data "local_file" "consul_bootstrap_token_raw" {
    filename = "consul.key"
}

locals {
    consul_bootstrap_token = trimspace(data.local_file.consul_bootstrap_token_raw.content)
}

variable "consul-a_ipv4_address" {type = string}
variable "consul-b_ipv4_address" {type = string}
variable "consul-c_ipv4_address" {type = string}

variable "vault-a_ipv4_address" {type = string}
variable "vault-b_ipv4_address" {type = string}
variable "vault-c_ipv4_address" {type = string}

variable "hashistack1_trunk_network_name" {type = string}
variable "hashistack2_trunk_network_name" {type = string}
variable "hashistack3_trunk_network_name" {type = string}
