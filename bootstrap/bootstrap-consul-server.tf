module "bootstrap-consul-server" {
    source = "../modules/csr"

    subject = {
        common_name = "server.dc1.consul"
    }

    csr_filename = "${path.root}/certs/bootstrap-consul-server.csr"
    cert_filename = "${path.root}/certs/bootstrap-consul-server.pem"
    key_filename = "${path.root}/certs/bootstrap-consul-server-key.pem"

    dns_names = [
        "server.dc1.consul",
        "consul.service.consul",
    ]
    ip_addresses = [
        var.consul-a_ipv4_address,
        var.consul-b_ipv4_address,
        var.consul-c_ipv4_address,
        "127.0.0.1",
    ]
}

output "bootstrap-consul-server-read_csr_path" {
    value = module.bootstrap-consul-server.csr_filename
}
output "bootstrap-consul-server-write_pem_path" {
    value = module.bootstrap-consul-server.cert_filename
}
