resource "consul_acl_policy" "dns-lookups" {
  name        = "dns-lookups-${local.run_id}"

  rules       = <<-RULE
    node_prefix "consul-dns-" {
      policy = "write"
    }
    node_prefix "" {
      policy = "read"
    }
    service_prefix "" {
      policy = "read"
    }
    # only needed if using prepared queries
    query_prefix "" {
      policy = "read"
    }
    RULE
  depends_on = [ null_resource.consul_deployed ]
}

resource "consul_acl_token" "dns-lookups" {
  description = "dns-lookups-${local.run_id}"
  policies = [consul_acl_policy.dns-lookups.name]
  depends_on = [ null_resource.consul_deployed ]
}

data "consul_acl_token_secret_id" "dns-lookups" {
    accessor_id = consul_acl_token.dns-lookups.id
}

locals {
    consul_dns_agent_config = <<-CONFIG
        addresses {
            dns = "0.0.0.0",
            http = "127.0.0.1",
            https = "127.0.0.1",
        }
        ports {
            dns = 53,
        }
        CONFIG
}

module "consul-dns-server-a" {
    source = "../modules/consul_agent"
    hostname = "consul-dns-a"
    ipv4_address = var.consul-dns-a_ipv4_address
    trunk = data.docker_network.hashistack1_trunk.name
    agent_token = data.consul_acl_token_secret_id.dns-lookups.secret_id
    encrypt = var.consul_encrypt_key

    approle_role_id = var.consul_client_approle_role_id
    approle_secret_id = var.consul-dns-a-consul_client_approle_secret_id

    ca_path = "${path.root}/../ca-certificates"

    config = local.consul_dns_agent_config

    cluster_addresses = [ module.consul-a.ipv4_address, module.consul-b.ipv4_address, module.consul-c.ipv4_address ]
    providers = { docker = docker.hashistack1 }
    depends_on = [ null_resource.consul_deployed ]
}

module "consul-dns-server-b" {
    source = "../modules/consul_agent"
    hostname = "consul-dns-b"
    ipv4_address = var.consul-dns-b_ipv4_address
    trunk = data.docker_network.hashistack2_trunk.name
    agent_token = data.consul_acl_token_secret_id.dns-lookups.secret_id
    encrypt = var.consul_encrypt_key

    approle_role_id = var.consul_client_approle_role_id
    approle_secret_id = var.consul-dns-b-consul_client_approle_secret_id

    ca_path = "${path.root}/../ca-certificates"

    config = local.consul_dns_agent_config

    cluster_addresses = [ module.consul-a.ipv4_address, module.consul-b.ipv4_address, module.consul-c.ipv4_address ]
    providers = { docker = docker.hashistack2 }
    depends_on = [ null_resource.consul_deployed ]
}

module "consul-dns-server-c" {
    source = "../modules/consul_agent"
    hostname = "consul-dns-c"
    ipv4_address = var.consul-dns-c_ipv4_address
    trunk = data.docker_network.hashistack3_trunk.name
    agent_token = data.consul_acl_token_secret_id.dns-lookups.secret_id
    encrypt = var.consul_encrypt_key

    approle_role_id = var.consul_client_approle_role_id
    approle_secret_id = var.consul-dns-c-consul_client_approle_secret_id

    ca_path = "${path.root}/../ca-certificates"

    config = local.consul_dns_agent_config

    cluster_addresses = [ module.consul-a.ipv4_address, module.consul-b.ipv4_address, module.consul-c.ipv4_address ]
    providers = { docker = docker.hashistack3 }
    depends_on = [ null_resource.consul_deployed ]
}

resource "null_resource" "consul-dns-servers-deployed" {
    depends_on = [
        module.consul-dns-server-a,
        module.consul-dns-server-b,
        module.consul-dns-server-c,
    ]
}

output "dns_server_a" { value = var.consul-dns-a_ipv4_address }
output "dns_server_b" { value = var.consul-dns-b_ipv4_address }
output "dns_server_c" { value = var.consul-dns-c_ipv4_address }
