resource "vault_approle_auth_backend_role" "consul-client" {
  backend        = vault_auth_backend.approle.path
  role_name      = "consul-client"
  token_period   = 3600
  token_bound_cidrs = [
    var.consul-dns-a_ipv4_address,
    var.consul-dns-b_ipv4_address,
    var.consul-dns-c_ipv4_address,
  ]
  token_policies = ["default", "consul-pki-client"]
  role_id = var.consul_client_approle_role_id
}

resource "vault_approle_auth_backend_role_secret_id" "consul-dns-a-approle-secret" {
    role_name = vault_approle_auth_backend_role.consul-client.role_name
    cidr_list = ["${var.consul-dns-a_ipv4_address}/32"]
    secret_id = var.consul-dns-a-consul_client_approle_secret_id
}
resource "vault_approle_auth_backend_role_secret_id" "consul-dns-b-approle-secret" {
    role_name = vault_approle_auth_backend_role.consul-client.role_name
    cidr_list = ["${var.consul-dns-b_ipv4_address}/32"]
    secret_id = var.consul-dns-b-consul_client_approle_secret_id
}
resource "vault_approle_auth_backend_role_secret_id" "consul-dns-c-approle-secret" {
    role_name = vault_approle_auth_backend_role.consul-client.role_name
    cidr_list = ["${var.consul-dns-c_ipv4_address}/32"]
    secret_id = var.consul-dns-c-consul_client_approle_secret_id
}

resource "vault_pki_secret_backend_role" "consul-client" {
    name = "consul-client"
    backend = vault_mount.consul_pki.path
    ttl = 3600
    allow_ip_sans = true
    key_type = "rsa"
    key_bits = 4096
    allowed_domains = [
        "client.dc1.consul",
    ]
    allow_subdomains = false
    allow_bare_domains = true
    allow_glob_domains = false
    
    key_usage                          = [
        "DigitalSignature",
        "KeyAgreement",
        "KeyEncipherment",
    ]

    allow_localhost = true
    server_flag = false
    client_flag = true
}

resource "vault_policy" "consul-pki-client" {
    name = "consul-pki-client"
  
    policy = <<-EOT
        path "consul_pki/issue/${vault_pki_secret_backend_role.consul-client.name}" {
          capabilities = ["create", "update"]
        }
        EOT
}


