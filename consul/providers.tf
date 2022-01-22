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

# provider "docker" {
#   alias = "hashistack1"
#   host = "ssh://james@192.168.1.2:22"
# }
#
# provider "docker" {
#   alias = "hashistack2"
#   host = "ssh://james@192.168.1.2:22"
# }
#
# provider "docker" {
#   alias = "hashistack3"
#   host = "ssh://james@192.168.1.2:22"
# }

provider "consul" {
    #address = module.consul-a.https
    address = "http://192.168.1.35:8500"
    #ca_file = "${path.root}/../ca-certificates/all.pem"
    ca_path = "${path.root}/../ca-certificates"
    token = var.management_token #jsondecode(file("${path.root}/consul-acl-bootstrap.json")).SecretID
    #insecure_https = true
}
