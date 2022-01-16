terraform {
  required_providers {
    docker = {
      source = "kreuzwerker/docker"
      version = "2.15.0"
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
