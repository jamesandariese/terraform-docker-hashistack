module "bootstrap-consul-client" {
    source = "../modules/csr"

    subject = {
        common_name = "client.dc1.consul"
    }

    csr_filename = "${path.root}/certs/bootstrap-consul-client.csr"
    cert_filename = "${path.root}/certs/bootstrap-consul-client.pem"
    key_filename = "${path.root}/certs/bootstrap-consul-client-key.pem"

    dns_names = [
        "client.dc1.consul"
    ]

    ip_addresses = [
        var.consul-dns-a_ipv4_address,
        var.consul-dns-b_ipv4_address,
        var.consul-dns-c_ipv4_address,
        var.vault-a_ipv4_address,
        var.vault-b_ipv4_address,
        var.vault-c_ipv4_address,
        "127.0.0.1",
    ]
}

output "bootstrap-consul-client-read_csr_path" {
    value = module.bootstrap-consul-client.csr_filename
}
output "bootstrap-consul-client-write_pem_path" {
    value = module.bootstrap-consul-client.cert_filename
}
