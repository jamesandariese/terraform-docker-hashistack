variable "consul_cluster" {
    default = "consul.service.consul"
}
variable "hostname" {}
variable "ipv4_address" {}
variable "trunk" {
    default = "trunk"
}
variable "consul_encrypt" {}

module "consul_agent" {
    source = "../consul_agent"

    hostname = var.hostname
    ipv4_address = var.ipv4_address
    trunk = var.trunk
    encrypt = var.consul_encrypt
    cluster_address = var.consul_cluster
}


