variable "approle_role_id" {type=string}
variable "approle_secret_id" {type=string}

locals {
    cert_template_common_pre = <<-TMPL
        {{- with secret "consul_pki/issue/vault-server"
                       "common_name=vault.service.consul"
                       "ttl=24h"
                       "alt_names=localhost,active.vault.service.consul"
                       "ip_sans=127.0.0.1,${var.ipv4_address}"
        -}}
        TMPL
    cert_template_common_post = <<-TMPL
        {{- end -}}
        TMPL
    ca_template = <<-TMPL
        ${local.cert_template_common_pre}
        {{- range $cert := .Data.ca_chain -}}
        {{ $cert }}
        {{ end -}}
        ${local.cert_template_common_post}
        TMPL
    cert_template = <<-TMPL
        ${local.cert_template_common_pre}
        {{ .Data.certificate }}
        {{ .Data.issuing_ca }}
        ${local.cert_template_common_post}
        TMPL
    key_template = <<-TMPL
        ${local.cert_template_common_pre}
        {{ .Data.private_key }}
        ${local.cert_template_common_post}
        TMPL
}

module "consul-template" {
    source = "../consul_template"

    approle_role_id = var.approle_role_id
    approle_secret_id = var.approle_secret_id

    ca_path = var.ca_path

    config = <<-CONFIG
        template {
            source = "/vault/ca-template.tmpl"
            destination = "/vault/ca.pem"
        }
        template {
            source = "/vault/cert-template.tmpl"
            destination = "/vault/cert.pem"
        }
        template {
            source = "/vault/key-template.tmpl"
            destination = "/vault/key.pem"
        }
        CONFIG

    uploads = {
        "/vault/cert-template.tmpl": local.cert_template,
        "/vault/ca-template.tmpl": local.ca_template,
        "/vault/key-template.tmpl": local.key_template,
    }

    attach_container = docker_container.server

}

