data "external" "no_file_modulus_with_count" {
    count = fileexists("does not exist") ? 1 : 0
    program = ["${path.root}/../extract-modulus.sh"]
    query = {
        cert_file = "does not exist"
    }
}

data "external" "no_file_modulus" {
    program = ["${path.root}/../extract-modulus.sh"]
    query = {
        cert_file = "does not exist"
        fail_no_file = false
    }
}

output "no_file_modulus_is_empty_string" {
    value = data.external.no_file_modulus.result.modulus == ""
}

data "external" "ca_key_modulus" {
    program = ["${path.root}/../extract-modulus.sh"]
    query = {
        rsa_key = tls_private_key.ca.private_key_pem
    }
}
data "external" "ca_cert_modulus" {
    program = ["${path.root}/../extract-modulus.sh"]
    query = {
        cert = tls_self_signed_cert.cacert.cert_pem
    }
}
data "external" "csr_keys" {
    count = local.csrcount
    program = ["${path.root}/../extract-modulus.sh"]
    query = {
        rsa_key = tls_private_key.keys[count.index].private_key_pem
    }
}
data "external" "csr_csrs" {
    count = local.csrcount
    program = ["${path.root}/../extract-modulus.sh"]
    query = {
        csr = tls_cert_request.csrs[count.index].cert_request_pem
    }
}
data "external" "csr_certs" {
    count = local.csrcount
    program = ["${path.root}/../extract-modulus.sh"]
    query = {
        cert = tls_locally_signed_cert.certs[count.index].cert_pem
    }
}

output "modulii" {
    value = {
        ca_cert = data.external.ca_cert_modulus.result
        ca_key = data.external.ca_key_modulus.result
        keys = [for c in data.external.csr_keys: c.result]
        csrs = [for c in data.external.csr_csrs: c.result]
        certs = [for c in data.external.csr_certs: c.result]
        no_file_modulus = data.external.no_file_modulus.result
    }
}
