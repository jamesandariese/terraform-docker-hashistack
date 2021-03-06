data "docker_network" "trunk" {
    name = var.trunk
}

resource "docker_image" "debian" {
    name = "debian:11"
    keep_locally = true

    # don't start downloading more stuff until the consul_agent is up
    depends_on = [module.consul_agent]
}

data "docker_registry_image" "vault" {
  name = "jamesandariese/vault-tls:1.9.1"
}

resource "docker_image" "vault" {
    name = data.docker_registry_image.vault.name
    keep_locally = true
    # order these image downloads, please
    depends_on = [docker_image.debian]
    pull_triggers = [data.docker_registry_image.vault.sha256_digest]
}

resource "docker_volume" "vault" {
    name = "${var.hostname}_vault_server_volume"
}

#resource "docker_container" "setup" {
#    name = "${var.hostname}_vault_setup"
#    image = docker_image.debian.latest
#
#    # this will install the config and then not be running.  if we don't
#    # specify must_run, it will try to create a new one on every run and fail
#    # because it still exists.
#
#    must_run = false
#
#    command = [
#        "bash",
#        "-c",
#        "mkdir -p /vault/config ; echo -e '${replace(templatefile("${path.module}/vault.hcl.tmpl", {}), "'", "'\"'\"'")}' > /vault/config/vault.hcl ; sleep 60",
#    ]
#
#    volumes {
#        container_path = "/vault"
#        volume_name = docker_volume.vault.name
#    }
#}

resource "docker_container" "server" {
    name = "${var.hostname}_vault_server"
    image = docker_image.vault.latest

    restart = "unless-stopped"

    command = [
        "server",
    ]
    network_mode = "container:${module.consul_agent.network_container.id}"
    volumes {
        container_path = "/vault"
        read_only = false
        volume_name = docker_volume.vault.name
    }

    upload {
        file = "/vault/bootstrap-cert.pem"
        source = "${path.root}/../bootstrap/certs/bootstrap-vault-server.pem"
        source_hash = filesha256("${path.root}/../bootstrap/certs/bootstrap-vault-server.pem")
    }
    upload {
        file = "/vault/bootstrap-key.pem"
        source = "${path.root}/../bootstrap/certs/bootstrap-vault-server-key.pem"
        source_hash = filesha256("${path.root}/../bootstrap/certs/bootstrap-vault-server-key.pem")
    }
    upload {
        file = "/vault/bootstrap-ca.pem"
        source = "${path.root}/../bootstrap/ca.pem"
        source_hash = filesha256("${path.root}/../bootstrap/ca.pem")
    }   


    capabilities {
        add = ["CAP_IPC_LOCK"]
    }

    # this is a hack to enforce parallelism=1 for just this resource...
    # hope everything really just takes 7 seconds!
    #depends_on = [
    #    docker_container.setup
    #]
}
