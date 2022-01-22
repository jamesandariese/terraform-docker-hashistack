resource "vault_approle_auth_backend_role" "consul-server" {
  backend        = data.vault_auth_backend.approle.path
  role_name      = "consul-server"
  token_period   = 3600
  token_bound_cidrs = [
    var.consul-a_ipv4_address,
    var.consul-b_ipv4_address,
    var.consul-c_ipv4_address,
  ]
  token_policies = ["default", "consul-pki"]
  role_id = var.consul_server_approle_role_id
}

resource "vault_approle_auth_backend_role_secret_id" "consul-a-approle-secret" {
    role_name = vault_approle_auth_backend_role.consul-server.role_name
    cidr_list = ["${var.consul-a_ipv4_address}/32"]
    secret_id = var.consul-a-consul_server_approle_secret_id
}
resource "vault_approle_auth_backend_role_secret_id" "consul-b-approle-secret" {
    role_name = vault_approle_auth_backend_role.consul-server.role_name
    cidr_list = ["${var.consul-b_ipv4_address}/32"]
    secret_id = var.consul-b-consul_server_approle_secret_id
}
resource "vault_approle_auth_backend_role_secret_id" "consul-c-approle-secret" {
    role_name = vault_approle_auth_backend_role.consul-server.role_name
    cidr_list = ["${var.consul-c_ipv4_address}/32"]
    secret_id = var.consul-c-consul_server_approle_secret_id
}

resource "vault_pki_secret_backend_role" "consul-server" {
    name = "consul-server"
    backend = vault_mount.consul_pki.path
    ttl = 3600
    allow_ip_sans = true
    key_type = "rsa"
    key_bits = 4096
    allowed_domains = [
        "server.dc1.consul",
        "consul.service.consul"
    ]
    allow_subdomains = true
    allow_bare_domains = true
    allow_glob_domains = true
    
    key_usage                          = [
        "DigitalSignature",
        "KeyAgreement",
        "KeyEncipherment",
    ]

    allow_localhost = true
    server_flag = true
    client_flag = true
}

resource "vault_policy" "consul-pki" {
    name = "consul-pki"
  
    policy = <<-EOT
        path "consul_pki/issue/${vault_pki_secret_backend_role.consul-server.name}" {
          capabilities = ["create", "update"]
        }
        EOT
}


