variable "hostname" { type=string }
variable "ipv4_address" { type=string }
variable "trunk" {
    default = "trunk"
    type = string
}
variable "encrypt" { type=string }
variable "cluster_addresses" {
    type = list
}
variable "token" {
    default = "anonymous"
    type = string
}
variable "config" {
    type = string
    default = "# no extra config defined"
}
variable "ca_path" {
    type = string
    #default = null
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

resource "docker_container" "sleeper" {
    name = "${var.hostname}_consul_sidecar_sleeper"
    image = docker_image.debian.latest
    hostname = var.hostname

    restart = "unless-stopped"

    command = [ "sleep", "infinity" ]
    networks_advanced {
        name = data.docker_network.trunk.name
        ipv4_address = var.ipv4_address
    }
}

locals {
    consul_join_flags = flatten([for s in var.cluster_addresses: ["-retry-join", s] ])
}

resource "docker_container" "agent" {
    name = "${var.hostname}_consul_sidecar"
    image = docker_image.consul.latest

    restart = "unless-stopped"

    command = [
        "consul",
        "agent",
        "-encrypt", var.encrypt,
        "-data-dir", "/consul/data",
        "-config-dir", "/consul/config",
        #"-hcl", "auto_encrypt { tls = true }",
        #"-hcl", "verify_incoming = true",
        "-hcl", "verify_incoming_rpc = true",
        "-hcl", "verify_outgoing = true",
        "-hcl", "verify_server_hostname = true",
        "-hcl", "acl { enabled = true, tokens { default = \"${var.token}\"}}",
        "-hcl", "ca_path = \"/consul/ca_certs\"",
        "-hcl", "cert_file = \"/consul/cert.pem\"",
        "-hcl", "key_file = \"/consul/key.pem\"",
        "-retry-join", var.cluster_addresses[0],
        "-retry-join", var.cluster_addresses[1%length(var.cluster_addresses)],
        "-retry-join", var.cluster_addresses[2%length(var.cluster_addresses)],
    ]
    dynamic "upload" {
        for_each = var.ca_path!=null ? fileset(var.ca_path, "*.pem") : []
        content {
            file = "/consul/ca_certs/${substr(filesha256("${var.ca_path}/${upload.value}"),0,12)}.pem"
            source = "${var.ca_path}/${upload.value}"
            source_hash = filesha256("${var.ca_path}/${upload.value}")
        }
    }
    upload {
        file = "/consul/bootstrap-ca.pem"
        source = "${path.root}/../bootstrap/ca.pem"
        source_hash = filesha256("${path.root}/../bootstrap/ca.pem")
    } 
    upload {
        file = "/consul/bootstrap-cert.pem"
        source = "${path.root}/../bootstrap/certs/bootstrap-consul-client.pem"
        source_hash = filesha256("${path.root}/../bootstrap/certs/bootstrap-consul-client.pem")
    }
    upload {
        file = "/consul/bootstrap-key.pem"
        source = "${path.root}/../bootstrap/certs/bootstrap-consul-client-key.pem"
        source_hash = filesha256("${path.root}/../bootstrap/certs/bootstrap-consul-client-key.pem")
    }

    upload {
        file = "/consul/config/custom.hcl"
        content = var.config
    }
    network_mode = "container:${docker_container.sleeper.id}"
}

output "network_container" {
    value = docker_container.sleeper
}
