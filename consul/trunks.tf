data "docker_network" "hashistack1_trunk" {
    provider = docker.hashistack1
    name = var.hashistack1_trunk_network_name
}
data "docker_network" "hashistack2_trunk" {
    provider = docker.hashistack2
    name = var.hashistack2_trunk_network_name
}
data "docker_network" "hashistack3_trunk" {
    provider = docker.hashistack3
    name = var.hashistack3_trunk_network_name
}
