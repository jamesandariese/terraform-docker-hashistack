variable "hostname" {}
variable "ipv4_address" {}
variable "trunk" {
    default = "trunk"
}
variable "encrypt" {}
variable "cluster_address" {
    default = "consul.service.consul"
}
variable "order" {
    default = 1
    type = number
}
variable "order_enforcer_wait_time" {
    default = 7
    type = number
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

resource "docker_volume" "consul" {
    name = "${var.hostname}_consul_server_volume"
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

resource "null_resource" "order_enforcer" {
    provisioner "local-exec" {
        command = "sleep ${(var.order - 1) * 7 + 1}"
    }
}

locals {
    order_hack = substr(null_resource.order_enforcer.id, 0, 0)
}

resource "docker_container" "server" {
    name = "${var.hostname}_consul_server${local.order_hack}"
    image = docker_image.consul.latest

    command = [
        "consul",
        "agent",
        "-encrypt", var.encrypt,
        "-retry-join", var.cluster_address,
        "-server",
        "-client", "0.0.0.0",
        "-ui",
        "-bootstrap-expect", "3",
        "-dns-port", "53",
        "-data-dir", "/consul/data",
        #"-hcl", "acl { enabled = true }",
    ]
    network_mode = "container:${docker_container.sleeper.id}"
    volumes {
        container_path = "/consul"
        volume_name = docker_volume.consul.name
    }

    # this is a hack to enforce parallelism=1 for just this resource...
    # hope everything really just takes 7 seconds!
    depends_on = [
        null_resource.order_enforcer
    ]
}
