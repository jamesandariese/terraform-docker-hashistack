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
variable "ca_path" { type = string }
variable "consul_node_id" { type = string }

#variable "approle_role_id" {
#    type = string
#    description = "approle role id which can create a consul client certificate in vault"
#}
#variable "approle_secret_id" {
#    type = string
#    description = "approle secret id which can create a consul client certificate in vault"
#}

module "consul_agent" {
    source = "../consul_agent"

    hostname = var.hostname
    ipv4_address = var.ipv4_address
    trunk = var.trunk
    encrypt = var.consul_encrypt
    agent_token = var.consul_token
    cluster_addresses = [var.consul_cluster]

    approle_role_id = var.approle_role_id
    approle_secret_id = var.approle_secret_id

    consul_node_id = var.consul_node_id

    ca_path = var.ca_path
}


