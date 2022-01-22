module "bootstrap-vault-server" {
    source = "../modules/csr"

    subject = {
        common_name = "vault.service.consul"
    }

    csr_filename = "${path.root}/certs/bootstrap-vault-server.csr"
    cert_filename = "${path.root}/certs/bootstrap-vault-server.pem"
    key_filename = "${path.root}/certs/bootstrap-vault-server-key.pem"

    dns_names = [
        "client.dc1.consul",
        "vault.service.consul",
    ]

    ip_addresses = [
        var.vault-a_ipv4_address,
        var.vault-b_ipv4_address,
        var.vault-c_ipv4_address,
        "127.0.0.1",
    ]
}

output "bootstrap-vault-server-read_csr_path" {
    value = module.bootstrap-vault-server.csr_filename
}
output "bootstrap-vault-server-write_pem_path" {
    value = module.bootstrap-vault-server.cert_filename
}
