#!/bin/bash

cd "$(dirname "$0")"

OUTPUT_FILES="
    terraform.tfvars
    dc1-client-consul-0-key.pem
    dc1-client-consul-0.pem
    dc1-server-consul-0-key.pem
    dc1-server-consul-0.pem
    consul-agent-ca-key.pem
    consul-agent-ca.pem
    providers-local.tf
"

echo "Welcome to the repo bootstrapper."
echo "You will need to enter values from your network and your configuration:"
echo "After, the following files will be created:"

ABORT=no
for f in $OUTPUT_FILES;do
    echo -n "   $f"
    if [ -e "$f" ];then
        echo -n " *** $f already exists!  aborting. ***"
        ABORT=yes
    fi
    echo
done
if [ x"$ABORT" = xyes ];then
    exit 1
fi

echo "what hosts will the stack be installed on?  it may be the same host 3 times for testing"
read -p 'docker host 1: ' DOCKER_IP_A
read -p 'docker host 2: ' DOCKER_IP_B
read -p 'docker host 3: ' DOCKER_IP_C
echo "what docker network (docker network ls) is attached to your macvlan trunk?"
read -p 'docker host 1 trunk network name [trunk]: ' DOCKER_TRUNK_A
read -p 'docker host 2 trunk network name [trunk]: ' DOCKER_TRUNK_B
read -p 'docker host 3 trunk network name [trunk]: ' DOCKER_TRUNK_C
echo "what's the username able to ssh and run docker without sudo?"
read -p 'docker host 1 username: ' DOCKER_USER_A
read -p 'docker host 2 username: ' DOCKER_USER_B
read -p 'docker host 3 username: ' DOCKER_USER_C
echo Enter the IP addresses of the services to build.
echo These must not already be on your network and must be usable from the docker trunk network.
read -p 'consul-a ip address: ' CONSUL_A
read -p 'consul-b ip address: ' CONSUL_B
read -p 'consul-c ip address: ' CONSUL_C
read -p 'consul-dns-a ip address: ' CONSUL_DNS_A
read -p 'consul-dns-b ip address: ' CONSUL_DNS_B
read -p 'consul-dns-c ip address: ' CONSUL_DNS_C
read -p 'vault-a ip address: ' VAULT_A
read -p 'vault-b ip address: ' VAULT_B
read -p 'vault-c ip address: ' VAULT_C

if [ x"$DOCKER_TRUNK_A" = x ];then DOCKER_TRUNK_A=trunk; fi
if [ x"$DOCKER_TRUNK_B" = x ];then DOCKER_TRUNK_B=trunk; fi
if [ x"$DOCKER_TRUNK_C" = x ];then DOCKER_TRUNK_C=trunk; fi

MANAGEMENT_TOKEN=`uuid -v 4`
CONSUL_KEY=`consul keygen`

cat << EOF > terraform.tfvars
consul-a_ipv4_address = "$CONSUL_A"
consul-b_ipv4_address = "$CONSUL_B"
consul-c_ipv4_address = "$CONSUL_C"
consul-dns-a_ipv4_address = "$CONSUL_DNS_A"
consul-dns-b_ipv4_address = "$CONSUL_DNS_B"
consul-dns-c_ipv4_address = "$CONSUL_DNS_C"
vault-a_ipv4_address = "$VAULT_A"
vault-b_ipv4_address = "$VAULT_B"
vault-c_ipv4_address = "$VAULT_C"
hashistack1_trunk_network_name = "$DOCKER_TRUNK_A"
hashistack2_trunk_network_name = "$DOCKER_TRUNK_B"
hashistack3_trunk_network_name = "$DOCKER_TRUNK_C"
management_token = "$MANAGEMENT_TOKEN"
consul_encrypt_key = "$CONSUL_KEY"
EOF

consul tls ca create
consul tls cert create -client -additional-ipaddress=$VAULT_A -additional-ipaddress=$VAULT_B -additional-ipaddress=$VAULT_C -additional-dnsname=vault.service.consul
consul tls cert create -server -additional-ipaddress=$CONSUL_A -additional-ipaddress=$CONSUL_B -additional-ipaddress=$CONSUL_C -additional-dnsname=consul.service.consul


echo 'provider "docker" {
  alias = "hashistack1"
  host = "ssh://'"$DOCKER_USER_A"'@'"$DOCKER_IP_A"':22"
}

provider "docker" {
  alias = "hashistack2"
  host = "ssh://'"$DOCKER_USER_B"'@'"$DOCKER_IP_B"':22"
}

provider "docker" {
  alias = "hashistack3"
  host = "ssh://'"$DOCKER_USER_C"'@'"$DOCKER_IP_C"':22"
}' > providers-local.tf
