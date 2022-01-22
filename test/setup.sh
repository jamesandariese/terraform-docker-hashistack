#!/bin/bash

set -e
set -x

RUNSETUP=no
uuid || RUNSETUP=yes
consul version || RUNSETUP=yes
terraform version || RUNSETUP=yes
docker version || RUNSETUP=yes

if [ x"$RUNSETUP" = xyes ];then
    sudo apt-get update
    sudo apt-get update && sudo apt-get install -y gnupg software-properties-common curl
    curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
    sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
    sudo apt-get update
    sudo apt-get install terraform consul uuid docker.io bind9-dnsutils
fi


docker network create --subnet 172.23.128.0/24 consul-test-network
git clone .. test-tf
cd test-tf

echo 'localhost
localhost
localhost
consul-test-network
consul-test-network
consul-test-network
'$USER'
'$USER'
'$USER'
172.23.128.10
172.23.128.11
172.23.128.12
172.23.128.53
172.23.128.54
172.23.128.55
172.23.128.41
172.23.128.42
172.23.128.43' | bash bootstrap-repo.sh
cd consul
terraform init
terraform apply -auto-approve -parallelism=1

dig @172.23.128.53 consul.service.consul | grep .
