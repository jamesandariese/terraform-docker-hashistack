resource "vault_approle_auth_backend_role" "vault-server" {
  backend        = vault_auth_backend.approle.path
  role_name      = "vault-server"
  token_period   = 3600
  token_bound_cidrs = [
    var.vault-a_ipv4_address,
    var.vault-b_ipv4_address,
    var.vault-c_ipv4_address,
  ]
  token_policies = ["default", vault_policy.vault-server-pki.name, "consul-pki-client"]
  role_id = var.vault_server_approle_role_id
}

resource "vault_approle_auth_backend_role_secret_id" "vault-server-a-approle-secret" {
    role_name = vault_approle_auth_backend_role.vault-server.role_name
    cidr_list = ["${var.vault-a_ipv4_address}/32"]
    secret_id = var.vault-a-vault_server_approle_secret_id
}
resource "vault_approle_auth_backend_role_secret_id" "vault-server-b-approle-secret" {
    role_name = vault_approle_auth_backend_role.vault-server.role_name
    cidr_list = ["${var.vault-b_ipv4_address}/32"]
    secret_id = var.vault-b-vault_server_approle_secret_id
}
resource "vault_approle_auth_backend_role_secret_id" "vault-server-c-approle-secret" {
    role_name = vault_approle_auth_backend_role.vault-server.role_name
    cidr_list = ["${var.vault-c_ipv4_address}/32"]
    secret_id = var.vault-c-vault_server_approle_secret_id
}

resource "vault_pki_secret_backend_role" "vault-server" {
    name = "vault-server"
    backend = vault_mount.consul_pki.path
    ttl = 3600
    allow_ip_sans = true
    key_type = "rsa"
    key_bits = 4096
    allowed_domains = [
        "vault.service.consul",
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

resource "vault_policy" "vault-server-pki" {
    name = "vault-server-pki"
  
    policy = <<-EOT
        path "consul_pki/issue/${vault_pki_secret_backend_role.vault-server.name}" {
          capabilities = ["create", "update"]
        }
        EOT
}


