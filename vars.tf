variable "consul-a_ipv4_address" {type = string}
variable "consul-b_ipv4_address" {type = string}
variable "consul-c_ipv4_address" {type = string}

variable "consul-dns-a_ipv4_address" {type = string}
variable "consul-dns-b_ipv4_address" {type = string}
variable "consul-dns-c_ipv4_address" {type = string}

variable "vault-a_ipv4_address" {type = string}
variable "vault-b_ipv4_address" {type = string}
variable "vault-c_ipv4_address" {type = string}

variable "hashistack1_url" {type = string}
variable "hashistack2_url" {type = string}
variable "hashistack3_url" {type = string}

variable "hashistack1_trunk_network_name" {type = string}
variable "hashistack2_trunk_network_name" {type = string}
variable "hashistack3_trunk_network_name" {type = string}

variable "management_token" {type = string}
variable "consul_encrypt_key" {type = string}

variable "consul_server_approle_role_id" {type = string}
variable "consul-a-consul_server_approle_secret_id" {type = string}
variable "consul-b-consul_server_approle_secret_id" {type = string}
variable "consul-c-consul_server_approle_secret_id" {type = string}

variable "consul_client_approle_role_id" {type = string}
variable "consul-dns-a-consul_client_approle_secret_id" {type = string}
variable "consul-dns-b-consul_client_approle_secret_id" {type = string}
variable "consul-dns-c-consul_client_approle_secret_id" {type = string}

variable "vault_server_approle_role_id" {type = string}
variable "vault-a-vault_server_approle_secret_id" {type = string}
variable "vault-b-vault_server_approle_secret_id" {type = string}
variable "vault-c-vault_server_approle_secret_id" {type = string}

variable "consul-a-consul_server_node_id" {type = string}
variable "consul-b-consul_server_node_id" {type = string}
variable "consul-c-consul_server_node_id" {type = string}

variable "consul-dns-a-consul_client_node_id" {type = string}
variable "consul-dns-b-consul_client_node_id" {type = string}
variable "consul-dns-c-consul_client_node_id" {type = string}

variable "vault-a-consul_client_node_id" {type = string}
variable "vault-b-consul_client_node_id" {type = string}
variable "vault-c-consul_client_node_id" {type = string}
