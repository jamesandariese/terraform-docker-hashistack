resource "consul_acl_policy" "vault-server" {
  name        = "vault-server-${local.run_id}"

  rules       = <<-RULE
    acl = "write"
    agent_prefix "" {
    	policy = "read"
    }
    key_prefix "vault/" {
    	policy = "write"
    }
    node_prefix "vault" {
    	policy = "write"
    }
    node_prefix "" {
    	policy = "read"
    }
    service_prefix "vault" {
    	policy = "write"
    }
    session_prefix "" {
    	policy = "write"
    }
    RULE
}

resource "consul_acl_token" "vault-server" {
  description = "vault-server-${local.run_id}"
  policies = [consul_acl_policy.vault-server.name]
}

data "consul_acl_token_secret_id" "vault-server" {
    accessor_id = consul_acl_token.vault-server.id
}



module "vault-a" {
    source = "../modules/vault_server"
    hostname = "vault-a"
    ipv4_address = var.vault-a_ipv4_address
    trunk = data.docker_network.hashistack1_trunk.name
    consul_encrypt = var.consul_encrypt_key
    consul_token = data.consul_acl_token_secret_id.vault-server.secret_id

    providers = {
        docker = docker.hashistack1
    }
}
module "vault-b" {
    source = "../modules/vault_server"
    hostname = "vault-b"
    ipv4_address = var.vault-b_ipv4_address
    trunk = data.docker_network.hashistack2_trunk.name
    consul_encrypt = var.consul_encrypt_key
    consul_token = data.consul_acl_token_secret_id.vault-server.secret_id

    depends_on = [ module.vault-a ]

    providers = {
        docker = docker.hashistack2
    }
}
module "vault-c" {
    source = "../modules/vault_server"
    hostname = "vault-c"
    ipv4_address = var.vault-c_ipv4_address
    trunk = data.docker_network.hashistack3_trunk.name
    consul_encrypt = var.consul_encrypt_key
    consul_token = data.consul_acl_token_secret_id.vault-server.secret_id

    depends_on = [ module.vault-b ]

    providers = {
        docker = docker.hashistack3
    }
}
