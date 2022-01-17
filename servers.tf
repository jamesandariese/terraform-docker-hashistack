module "consul-a" {
    source = "./consul_server"
    hostname = "consul-a"
    ipv4_address = var.consul-a_ipv4_address
    trunk = data.docker_network.hashistack1_trunk.name

    encrypt = local.consul_bootstrap_token
    cluster_address = var.consul-b_ipv4_address

    providers = {
        docker = docker.hashistack1
    }
}
module "consul-b" {
    source = "./consul_server"
    hostname = "consul-b"
    ipv4_address = var.consul-b_ipv4_address
    trunk = data.docker_network.hashistack2_trunk.name

    encrypt = local.consul_bootstrap_token
    cluster_address = var.consul-c_ipv4_address

    providers = {
        docker = docker.hashistack2
    }

    depends_on = [module.consul-a]
}
module "consul-c" {
    source = "./consul_server"
    hostname = "consul-c"
    ipv4_address = var.consul-c_ipv4_address
    trunk = data.docker_network.hashistack3_trunk.name

    encrypt = local.consul_bootstrap_token
    cluster_address = var.consul-a_ipv4_address

    providers = {
        docker = docker.hashistack3
    }
    depends_on = [module.consul-b]
}

locals {
    bootstrap_environment = {
        MANAGEMENT_TOKEN = local.consul_acl_tokens.management.secret
        MANAGEMENT_ACCESSOR = local.consul_acl_tokens.management.accessor
        VAULT_TOKEN = local.consul_acl_tokens.vault.secret
        VAULT_ACCESSOR = local.consul_acl_tokens.vault.accessor
    }
}

resource "null_resource" "bootstrap-consul-acl" {
    provisioner "local-exec" {
        command = "bash ${path.root}/bootstrap-consul-acl.sh https://${var.consul-a_ipv4_address}:8501"
        environment = local.bootstrap_environment
    }
    triggers = local.bootstrap_environment
    depends_on = [
        module.consul-a,
        module.consul-b,
        module.consul-c,
    ]
}

module "vault-a" {
    source = "./vault_server"
    hostname = "vault-a"
    ipv4_address = var.vault-a_ipv4_address
    trunk = data.docker_network.hashistack1_trunk.name
    consul_encrypt = local.consul_bootstrap_token

    depends_on = [
        null_resource.bootstrap-consul-acl
    ]

    providers = {
        docker = docker.hashistack1
    }
}
module "vault-b" {
    source = "./vault_server"
    hostname = "vault-b"
    ipv4_address = var.vault-b_ipv4_address
    trunk = data.docker_network.hashistack2_trunk.name
    consul_encrypt = local.consul_bootstrap_token

    depends_on = [ module.vault-a ]

    providers = {
        docker = docker.hashistack2
    }
}
module "vault-c" {
    source = "./vault_server"
    hostname = "vault-c"
    ipv4_address = var.vault-c_ipv4_address
    trunk = data.docker_network.hashistack3_trunk.name
    consul_encrypt = local.consul_bootstrap_token

    depends_on = [ module.vault-b ]

    providers = {
        docker = docker.hashistack3
    }
}
