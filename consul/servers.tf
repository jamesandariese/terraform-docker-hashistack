module "consul-a" {
    source = "../modules/consul_server"
    hostname = "consul-a"
    ipv4_address = var.consul-a_ipv4_address
    trunk = data.docker_network.hashistack1_trunk.name

    ca_path = "${path.root}/../ca-certificates"

    approle_role_id = var.consul_server_approle_role_id
    approle_secret_id = var.consul-a-consul_server_approle_secret_id

    encrypt = var.consul_encrypt_key
    cluster_address = var.consul-b_ipv4_address
    management_token = var.management_token

    providers = {
        docker = docker.hashistack1
    }
}
module "consul-b" {
    source = "../modules/consul_server"
    hostname = "consul-b"
    ipv4_address = var.consul-b_ipv4_address
    trunk = data.docker_network.hashistack2_trunk.name

    ca_path = "${path.root}/../ca-certificates"

    approle_role_id = var.consul_server_approle_role_id
    approle_secret_id = var.consul-b-consul_server_approle_secret_id

    encrypt = var.consul_encrypt_key
    cluster_address = var.consul-c_ipv4_address
    management_token = var.management_token

    providers = {
        docker = docker.hashistack2
    }

    depends_on = [module.consul-a]
}
module "consul-c" {
    source = "../modules/consul_server"
    hostname = "consul-c"
    ipv4_address = var.consul-c_ipv4_address
    trunk = data.docker_network.hashistack3_trunk.name

    ca_path = "${path.root}/../ca-certificates"

    approle_role_id = var.consul_server_approle_role_id
    approle_secret_id = var.consul-c-consul_server_approle_secret_id

    encrypt = var.consul_encrypt_key
    cluster_address = var.consul-a_ipv4_address
    management_token = var.management_token

    providers = {
        docker = docker.hashistack3
    }
    depends_on = [module.consul-b]
}

resource "time_sleep" "wait_for_consul_bootstrap" {
  depends_on = [module.consul-c]

  create_duration = "40s"
  triggers = merge(
      { management_token = var.management_token },
     module.consul-a,
      module.consul-b,
      module.consul-c,
  )
}

resource "null_resource" "consul_deployed" {
    depends_on = [
        module.consul-a,
        module.consul-b,
        module.consul-c,
        time_sleep.wait_for_consul_bootstrap,
    ]
}

output "consul_addresses" {
    value = [
        module.consul-a.ipv4_address,
        module.consul-b.ipv4_address,
        module.consul-c.ipv4_address,
    ]
}
