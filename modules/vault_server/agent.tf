variable "consul_cluster" {
    default = "consul.service.consul"
    type = string
}
variable "consul_token" { type=string }
variable "hostname" { type=string}
variable "ipv4_address" { type=string}
variable "trunk" {
    default = "trunk"
    type=string
}
variable "consul_encrypt" { type = string }
variable "ca_path" {type = string}
module "consul_agent" {
    source = "../consul_agent"

    hostname = var.hostname
    ipv4_address = var.ipv4_address
    trunk = var.trunk
    encrypt = var.consul_encrypt
    token = var.consul_token
    cluster_addresses = [var.consul_cluster]

    ca_path = var.ca_path
}


