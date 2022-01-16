#module "consul-agent" {
#    source = "./consul_agent"
#    hostname = "consul-agent"
#    ipv4_address = "192.168.1.2"
#    trunk = data.docker_network.hashistack1_trunk
#
#    encrypt = locals.consul_bootstrap_token
#    cluster_address = "consul.service.consul"
#
#    providers = {
#        docker = docker.hashistack1
#    }
#}
