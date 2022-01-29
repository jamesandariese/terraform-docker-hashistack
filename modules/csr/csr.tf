variable "rsa_bits" {
    default = 4096
}

variable "algorithm" {
    type = string
    default = "RSA"
}

variable "dns_names" {
    default = []
}
variable "ip_addresses" {
    default = []
}
variable "uris" {
    default = []
}

variable "subject" { }

variable "ecdsa_curve" {
    type = string
    default = "P521"
}

variable "csr_filename" { type = string }
output "csr_filename" { value = var.csr_filename }
variable "cert_filename" { type = string }
output "cert_filename" { value = var.cert_filename }
variable "key_filename" { type = string }
output "key_filename" { value = var.key_filename }

resource "tls_private_key" "key" {
    algorithm = var.algorithm
    rsa_bits  = var.rsa_bits
    ecdsa_curve = var.ecdsa_curve
}

resource "tls_cert_request" "bootstrap-server" {
  key_algorithm   = var.algorithm
  private_key_pem = tls_private_key.key.private_key_pem

  dynamic "subject" {
    for_each = [var.subject]
    content {
      common_name = try(subject.value.common_name, null)
      organization = try(subject.value.organization, null)
      organizational_unit = try(subject.value.organizational_unit, null)
      street_address = try(subject.value.street_address, [])
      locality = try(subject.value.locality, null)
      province = try(subject.value.province, null)
      country = try(subject.value.country, null)
      postal_code = try(subject.value.postal_code, null)
      serial_number = try(subject.value.serial_number, null)
    }
  }

  ip_addresses = var.ip_addresses
  uris = var.uris
  dns_names = var.dns_names
}

resource "local_file" "bootstrap-server-csr" {
    filename = var.csr_filename
    content  = tls_cert_request.bootstrap-server.cert_request_pem
}

resource "local_file" "bootstrap-server-key" {
    filename = var.key_filename
    content = tls_private_key.key.private_key_pem
}

data "external" "csr_modulus" {
    program = ["${path.module}/extract-modulus.sh"]
    query = {
        csr = tls_cert_request.bootstrap-server.cert_request_pem
        cookie = tls_private_key.key.private_key_pem
        fail_no_file = false
    }
}

data "external" "cert_modulus" {
    #count = fileexists(var.cert_filename) ? 1 : 0
    program = ["${path.module}/extract-modulus.sh"]
    query = {
        cert_file = var.cert_filename
        cookie = tls_private_key.key.private_key_pem
        fail_no_file = false
    }
}

data "external" "key_modulus" {
    program = ["${path.module}/extract-modulus.sh"]
    query = {
        rsa_key = tls_private_key.key.private_key_pem
        cookie = tls_private_key.key.private_key_pem
        fail_no_file = false
    }
}

locals {
    key_modulus = data.external.key_modulus.result.modulus
    cert_modulus = data.external.cert_modulus.result.modulus
    csr_modulus = data.external.csr_modulus.result.modulus
    key_ready = local.key_modulus != ""
    cert_ready = local.key_ready && local.cert_modulus == local.key_modulus
    csr_ready = local.key_ready && local.csr_modulus == local.key_modulus
    ready = (
                local.key_ready && local.cert_ready && local.csr_ready
            )
    ready_count = local.ready ? 1 : 0
}

#data "local_file" "bootstrap-server-cert" {
#    filename = var.cert_filename
#}

output "ready" {
    value = local.ready
}

output "key_ready" { value = local.key_ready }
output "csr_ready" { value = local.csr_ready }
output "cert_ready" { value = local.cert_ready }

output "ready_count" {
    value = local.ready_count
}

output "private_key" {
    value = tls_private_key.key
}

output "csr" {
    value = tls_cert_request.bootstrap-server
}

output "write_pem_path" {
    value = var.cert_filename
}
