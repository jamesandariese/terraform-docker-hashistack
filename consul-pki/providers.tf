terraform {
  required_providers {
    vault = {
      source = "hashicorp/vault"
      version = "3.2.1"
    }
  }
}

provider "vault" {
  address = "https://vault.service.consul:8200"
  ca_cert_dir = "${path.root}/../ca-certificates"
}
