module "consul-a" {
    source = "./consul_server"
    hostname = "consul-a"
    ipv4_address = var.consul-a_ipv4_address
    trunk = data.docker_network.hashistack1_trunk.name

    encrypt = local.consul_bootstrap_token
    cluster_address = var.consul-b_ipv4_address
    order = 1

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
    order = 2

    providers = {
        docker = docker.hashistack2
    }
}
module "consul-c" {
    source = "./consul_server"
    hostname = "consul-c"
    ipv4_address = var.consul-c_ipv4_address
    trunk = data.docker_network.hashistack3_trunk.name

    encrypt = local.consul_bootstrap_token
    cluster_address = var.consul-a_ipv4_address
    order = 3

    providers = {
        docker = docker.hashistack3
    }
}
module "vault-a" {
    source = "./vault_server"
    hostname = "vault-a"
    ipv4_address = var.vault-a_ipv4_address
    trunk = data.docker_network.hashistack1_trunk.name
    consul_encrypt = local.consul_bootstrap_token

    depends_on = [
        module.consul-a,
        module.consul-b,
        module.consul-c,
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

    depends_on = [
        module.consul-a,
        module.consul-b,
        module.consul-c,
    ]

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

    depends_on = [
        module.consul-a,
        module.consul-b,
        module.consul-c,
    ]

    providers = {
        docker = docker.hashistack3
    }
}
