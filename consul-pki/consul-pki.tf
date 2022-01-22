resource "vault_mount" "consul_pki" {
    path = "consul_pki"
    type = "pki"
}

resource "vault_pki_secret_backend_intermediate_cert_request" "consul_pki_csr" {
  depends_on  = [vault_mount.consul_pki]
  backend     = vault_mount.consul_pki.path
  type        = "internal"
  common_name = "vault.service.consul"

  key_type    = "rsa"
  key_bits    = 4096
}

resource "local_file" "consul_pki_csr_file" {
  filename = "${path.root}/consul_pki_ca.csr"
  content = "${vault_pki_secret_backend_intermediate_cert_request.consul_pki_csr.csr}\n"
}

data "local_file" "consul_pki_ca" {
  filename = "${path.root}/consul_pki_ca.pem"
  count    = fileexists("consul_pki_ca.pem") ? 1 : 0
}

resource "local_file" "consul_pki_ca_cacerts" {
  count       = fileexists("consul_pki_ca.pem") ? 1 : 0
  filename = "${path.root}/../ca-certificates/consul_pki_ca.pem"
  content = data.local_file.consul_pki_ca[0].content
}

resource "vault_pki_secret_backend_intermediate_set_signed" "consul_pki_certificate_install" { 
  count       = fileexists("consul_pki_ca.pem") ? 1 : 0
  backend     = vault_mount.consul_pki.path
  certificate = data.local_file.consul_pki_ca[0].content
}

