variable "hostname" {}
variable "ipv4_address" {}
variable "trunk" {
    default = "trunk"
}
variable "encrypt" {}
variable "cluster_address" {
    default = "consul.service.consul"
}
variable "management_token" { type = string }
variable "approle_role_id" { type = string }
variable "approle_secret_id" { type = string }

variable "ca_path" {type = string}

output "https" {
    value = "https://${var.ipv4_address}:8501"
}

data "docker_network" "trunk" {
    name = var.trunk
}

resource "docker_image" "debian" {
    name = "debian:11"
    keep_locally = true
}

resource "docker_image" "consul" {
    name = "jamesandariese/consul-tls:1.11.2"
    keep_locally = true
    depends_on = [docker_image.debian]
}

resource "docker_volume" "consul" {
    name = "${var.hostname}_consul_server_volume"
}

resource "docker_volume" "consul_data" {
    name = "${var.hostname}_consul_server_data_volume"
}

resource "docker_container" "sleeper" {
    name = "${var.hostname}_consul_server_sleeper"
    image = docker_image.debian.latest
    hostname = var.hostname

    restart = "unless-stopped"

    command = [ "sleep", "infinity" ]
    networks_advanced {
        name = data.docker_network.trunk.name
        ipv4_address = var.ipv4_address
    }
}

resource "docker_container" "server" {
    name = "${var.hostname}_consul_server"
    image = docker_image.consul.latest
    restart = "unless-stopped"

    command = [
        "consul",
        "agent",
        "-encrypt", var.encrypt,
        "-retry-join", var.cluster_address,
        "-server",
        "-client", "0.0.0.0",
        "-https-port", "8501",
        "-ui",
        "-bootstrap-expect", "3",
        "-dns-port", "53",
        "-data-dir", "/consul/data",
        "-config-dir", "/consul/config",
        "-hcl", "connect { enabled = true }",
        #"-hcl", "ca_file = \"/consul/ca.pem\"",
        "-hcl", "ca_path = \"/consul/ca_certs\"",
        "-hcl", "cert_file = \"/consul/cert.pem\"",
        "-hcl", "key_file = \"/consul/key.pem\"",
        #"-hcl", "auto_encrypt { allow_tls = true }",
        #"-hcl", "verify_incoming = true",
        #"-hcl", "verify_incoming_rpc = true",
        "-hcl", "verify_outgoing = true",
        "-hcl", "verify_server_hostname = true",
        "-hcl", "acl { enabled = true, default_policy = \"deny\" }",
    ]
    network_mode = "container:${docker_container.sleeper.id}"
    upload {
        file = "/consul/bootstrap-ca.pem"
        source = "${path.root}/../bootstrap/ca.pem"
        source_hash = filesha256("${path.root}/../bootstrap/ca.pem")
    }
    upload {
        file = "/consul/bootstrap-cert.pem"
        source = "${path.root}/../bootstrap/certs/bootstrap-consul-server.pem"
        source_hash = filesha256("${path.root}/../bootstrap/certs/bootstrap-consul-server.pem")
    }
    upload {
        file = "/consul/bootstrap-key.pem"
        source = "${path.root}/../bootstrap/certs/bootstrap-consul-server-key.pem"
        source_hash = filesha256("${path.root}/../bootstrap/certs/bootstrap-consul-server-key.pem")
    }
    upload {
        file = "/consul/config/tokens.hcl"
        content = templatefile("${path.module}/tokens.hcl.tftpl", {
            management_token=var.management_token,
        })
    }

    dynamic "upload" {
        for_each = var.ca_path!=null ? fileset(var.ca_path, "*.pem") : []
        content {
            file = "/consul/ca_certs/${substr(filesha256("${var.ca_path}/${upload.value}"),0,12)}.pem"
            source = "${var.ca_path}/${upload.value}"
            source_hash = filesha256("${var.ca_path}/${upload.value}")
        }
    }

    volumes {
        container_path = "/consul"
        volume_name = docker_volume.consul.name
    }

    volumes {
        container_path = "/consul/data"
        volume_name = docker_volume.consul_data.name
    }
}

locals {
    cert_template_common_pre = <<-TMPL
        {{- with secret "consul_pki/issue/consul-server"
                       "common_name=server.dc1.consul"
                       "ttl=24h"
                       "alt_names=localhost,consul.service.consul"
                       "ip_sans=127.0.0.1,${var.ipv4_address}"
        -}}
        TMPL
    cert_template_common_post = <<-TMPL
        {{- end -}}
        TMPL
    ca_template = <<-TMPL
        ${local.cert_template_common_pre}
        {{- range $cert := .Data.ca_chain -}}
        {{ $cert }}
        {{ end -}}
        ${local.cert_template_common_post}
        TMPL
    cert_template = <<-TMPL
        ${local.cert_template_common_pre}
        {{ .Data.certificate }}
        {{ .Data.issuing_ca }}
        ${local.cert_template_common_post}
        TMPL
    key_template = <<-TMPL
        ${local.cert_template_common_pre}
        {{ .Data.private_key }}
        ${local.cert_template_common_post}
        TMPL
}

module "consul-template" {
    source = "../consul_template"

    approle_role_id = var.approle_role_id
    approle_secret_id = var.approle_secret_id

    ca_path = var.ca_path

    config = <<-CONFIG
        template {
            source = "/consul/ca-template.tmpl"
            destination = "/consul/ca.pem"
        }
        template {
            source = "/consul/cert-template.tmpl"
            destination = "/consul/cert.pem"
        }
        template {
            source = "/consul/key-template.tmpl"
            destination = "/consul/key.pem"
        }
        CONFIG

    uploads = {
        "/consul/cert-template.tmpl": local.cert_template,
        "/consul/ca-template.tmpl": local.ca_template,
        "/consul/key-template.tmpl": local.key_template,
    }

    attach_container = docker_container.server

}

resource "time_sleep" "wait_for_consul_bootstrap" {
  depends_on = [
    docker_container.server
  ]

  create_duration = "5s"
  triggers = merge(
      { management_token = var.management_token },
      { container_id = docker_container.server.id },
      { container_id = docker_container.sleeper.id },
  )
}

output "ipv4_address" {
    value = var.ipv4_address
}
