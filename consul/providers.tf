terraform {
  required_providers {
    docker = {
      source = "kreuzwerker/docker"
      version = "2.15.0"
    }
    consul = {
      source = "hashicorp/consul"
      version = "2.14.0"
    }
  }
}

provider "docker" {
  alias = "hashistack1"
  host = var.hashistack1_url
}

provider "docker" {
  alias = "hashistack2"
  host = var.hashistack2_url
}

provider "docker" {
  alias = "hashistack3"
  host = var.hashistack3_url
}

provider "consul" {
    address = "https://${var.consul-b_ipv4_address}:8501"
    ca_path = "${path.root}/../ca-certificates"
    token = var.management_token #jsondecode(file("${path.root}/consul-acl-bootstrap.json")).SecretID
}
