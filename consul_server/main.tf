variable "hostname" {}
variable "ipv4_address" {}
variable "trunk" {
    default = "trunk"
}
variable "encrypt" {}
variable "cluster_address" {
    default = "consul.service.consul"
}

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

    command = [ "sleep", "infinity" ]
    networks_advanced {
        name = data.docker_network.trunk.name
        ipv4_address = var.ipv4_address
    }
}

resource "docker_container" "server" {
    name = "${var.hostname}_consul_server"
    image = docker_image.consul.latest
    restart = "always"

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
        "-hcl", "connect { enabled = true }",
        "-hcl", "ca_file = \"/consul/ca.pem\"",
        "-hcl", "cert_file = \"/consul/cert.pem\"",
        "-hcl", "key_file = \"/consul/key.pem\"",
        "-hcl", "auto_encrypt { allow_tls = true }",
        #"-hcl", "verify_incoming = true",
        "-hcl", "verify_incoming_rpc = true",
        "-hcl", "verify_outgoing = true",
        "-hcl", "verify_server_hostname = true",
        "-hcl", "acl { enabled = true, default_policy = \"deny\" }",
    ]
    network_mode = "container:${docker_container.sleeper.id}"

    upload {
        file = "/consul/bootstrap-cert.pem"
        source = "${path.root}/dc1-server-consul-0.pem"
        source_hash = filesha256("${path.root}/dc1-server-consul-0.pem")
    }
    upload {
        file = "/consul/bootstrap-key.pem"
        source = "${path.root}/dc1-server-consul-0-key.pem"
        source_hash = filesha256("${path.root}/dc1-server-consul-0-key.pem")
    }
    #upload {
    #    file = "/consul/bootstrap-ca-key.pem"
    #    source = "${path.root}/consul-agent-ca-key.pem"
    #    source_hash = filesha256("${path.root}/consul-agent-ca-key.pem")
    #}
    upload {
        file = "/consul/bootstrap-ca.pem"
        source = "${path.root}/consul-agent-ca.pem"
        source_hash = filesha256("${path.root}/consul-agent-ca.pem")
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
