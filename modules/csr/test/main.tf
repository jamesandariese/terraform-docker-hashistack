resource "tls_private_key" "ca" {
  algorithm = "RSA"
}

resource "local_file" "cakey" {
  filename = "ca.key"
  content = tls_private_key.ca.private_key_pem
}

resource "tls_self_signed_cert" "cacert" {
  key_algorithm = tls_private_key.ca.algorithm
  private_key_pem = tls_private_key.ca.private_key_pem

  subject {
    common_name = "csr test ca"
    street_address = []
  }

  validity_period_hours = 24*3653 # leap years, they matter.

  is_ca_certificate = true

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "local_file" "cacert" {
  filename = "ca.pem"
  content = tls_self_signed_cert.cacert.cert_pem
}

locals {
  csrcount = 3
}

resource "tls_private_key" "keys" {
  count = local.csrcount
  algorithm = "RSA"
  rsa_bits = (count.index + 2) * 1024
}

resource "local_file" "keys" {
  count = local.csrcount
  filename = "csr${count.index + 1}.key"
  content = tls_private_key.keys[count.index].private_key_pem
}

resource "tls_cert_request" "csrs" {
  count = local.csrcount
  key_algorithm = "RSA"
  private_key_pem = tls_private_key.keys[count.index].private_key_pem
  subject {
    common_name = "csr test ${count.index + 1}"
    street_address = []
  }
}

resource "local_file" "csrs" {
  count = local.csrcount
  filename = "csr${count.index + 1}.csr"
  content = tls_cert_request.csrs[count.index].cert_request_pem
}

resource "tls_locally_signed_cert" "certs" {
  count = local.csrcount
  cert_request_pem = tls_cert_request.csrs[count.index].cert_request_pem
  ca_private_key_pem = tls_private_key.ca.private_key_pem
  ca_key_algorithm = tls_private_key.ca.algorithm
  ca_cert_pem = tls_self_signed_cert.cacert.cert_pem
  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
  validity_period_hours = 25*3653
}

resource "local_file" "certs" {
  count = local.csrcount
  filename = "csr${count.index + 1}.pem"
  content = tls_locally_signed_cert.certs[count.index].cert_pem
}
