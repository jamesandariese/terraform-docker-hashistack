variable "hostname" {}
variable "ipv4_address" {}
variable "trunk" {
    default = "trunk"
}
variable "encrypt" {}
variable "cluster_address" {
    default = "consul.service.consul"
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
        #"-hcl", "acl { enabled = true }",
    ]
    network_mode = "container:${docker_container.sleeper.id}"
}

output "network_container" {
    value = docker_container.sleeper
}
