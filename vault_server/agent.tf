variable "consul_cluster" {
    default = "consul.service.consul"
}
variable "consul_token_name" {
    default = "vault"
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
    token_name = var.consul_token_name
    cluster_address = var.consul_cluster
}


