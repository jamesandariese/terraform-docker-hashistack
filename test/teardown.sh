#!/bin/sh

cd "$(dirname "$0")"

rm -rf test-tf

docker rm -f \
    consul-a_consul_server \
    consul-a_consul_server_sleeper \
    consul-b_consul_server \
    consul-b_consul_server_sleeper \
    consul-c_consul_server \
    consul-c_consul_server_sleeper \
    consul-dns-b_consul_sidecar \
    consul-dns-a_consul_sidecar \
    consul-dns-c_consul_sidecar \
    consul-dns-a_consul_sidecar_sleeper \
    consul-dns-b_consul_sidecar_sleeper \
    consul-dns-c_consul_sidecar_sleeper


docker volume rm \
    consul-a_consul_server_volume \
    consul-a_consul_server_data_volume \
    consul-b_consul_server_volume \
    consul-b_consul_server_data_volume \
    consul-c_consul_server_volume \
    consul-c_consul_server_data_volume

docker network rm consul-test-network

