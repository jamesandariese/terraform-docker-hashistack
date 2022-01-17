variable "hostname" {}
variable "ipv4_address" {}
variable "trunk" {
    default = "trunk"
}
variable "encrypt" {}
variable "cluster_address" {
    default = "consul.service.consul"
}
variable "token_name" {
    default = "anonymous"
    description = "key from {path.root}/tokens.json to use for token"
}
locals {
    token = jsondecode(file("${path.root}/tokens.json"))[var.token_name]["secret"]
}


data "docker_network" "trunk" {
  name = var.trunk
}

resource "docker_image" "debian" {
  name = "debian:11"
  keep_locally = true
}

resource "docker_image" "consul" {
  name = "consul:latest"
  keep_locally = true
  depends_on = [docker_image.debian]
}

resource "docker_container" "sleeper" {
    name = "${var.hostname}_consul_sidecar_sleeper"
    image = docker_image.debian.latest
    hostname = var.hostname

    command = [ "sleep", "infinity" ]
    networks_advanced {
        name = data.docker_network.trunk.name
        ipv4_address = var.ipv4_address
    }
}

resource "docker_container" "agent" {
    name = "${var.hostname}_consul_sidecar"
    image = docker_image.consul.latest

    command = [
        "consul",
        "agent",
        "-encrypt", var.encrypt,
        "-retry-join", var.cluster_address,
        "-dns-port", "53",
        "-data-dir", "/consul/data",
        "-hcl", "auto_encrypt { tls = true }",
        #"-hcl", "verify_incoming = true",
        "-hcl", "verify_incoming_rpc = true",
        "-hcl", "verify_outgoing = true",
        "-hcl", "verify_server_hostname = true",
        "-hcl", "acl { enabled = true, tokens { default = \"${local.token}\"}}",
        "-hcl", "ca_path = \"/consul/ca_certs\"",
    ]
    upload {
        file = "/consul/ca_certs/ca.pem"
        source = "${path.root}/consul-agent-ca.pem"
        source_hash = filesha256("${path.root}/consul-agent-ca.pem")
    }
    network_mode = "container:${docker_container.sleeper.id}"
}

output "network_container" {
    value = docker_container.sleeper
}
