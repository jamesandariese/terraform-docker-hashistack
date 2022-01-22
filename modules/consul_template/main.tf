resource "docker_image" "consul_template" {
    name = "jamesandariese/consul-template:0.27.2"
    keep_locally = true
}

variable "attach_container" {
}
variable "config" {
    type = string
    default = "# unconfigured"
    description = "config to be used by consul-template"
}
variable "approle_role_id" { type = string }
variable "approle_secret_id" { type = string }
variable "uploads" { type = map }

variable "ca_path" {
    type = string
    #default = null
}

resource "docker_container" "container" {
    name = "${var.attach_container.hostname}_consul_template"
    image = docker_image.consul_template.latest

    restart = "unless-stopped"

    network_mode = "container:${var.attach_container.id}"
    #volumes = var.attach_container.volumes
    dynamic "volumes" {
        for_each = var.attach_container.volumes
        content {
            container_path = volumes.value["container_path"]
            volume_name = volumes.value["volume_name"]
        }
    }
    dynamic "upload" {
        for_each = var.uploads
        content {
            file = upload.key
            content = upload.value
        }
    }
    upload {
        file = "/consul-template-config/extra-config.hcl"
        content = var.config
    }
    upload {
        file = "/approle/role_id"
        content = var.approle_role_id
    }
    upload {
        file = "/approle/secret_id"
        content = var.approle_secret_id
    }
    #upload {
    #    file = "/ca-certificates/ca.pem"
    #    source = "${path.root}/../ca-certificates/bootstrap-ca.pem"
    #    source_hash = filesha256("${path.root}/../ca-certificates/bootstrap-ca.pem")
    #}
    dynamic "upload" {
        for_each = var.ca_path!=null ? fileset(var.ca_path, "*.pem") : []
        content {
            file = "/ca-certificates/${substr(filesha256("${var.ca_path}/${upload.value}"),0,12)}.pem"
            source = "${var.ca_path}/${upload.value}"
            source_hash = filesha256("${var.ca_path}/${upload.value}")
        }
    }

}

output "container" {
    value = docker_container.container
}
