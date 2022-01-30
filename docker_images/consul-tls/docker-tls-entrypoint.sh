#!/bin/bash

set -e
set -x

cd /consul

cat << EOF > tls-shim.txt.tmpl
# {{ file "/consul/cert.pem" | sha256Hex }}
# {{ file "/consul/key.pem" | sha256Hex }}
# {{ file "/consul/ca.pem" | sha256Hex }}
EOF

if [ -f bootstrap-ca.pem -o -f bootstrap-cert.pem -o -f bootstrap-key.pem ];then
    # if there is any of the bootstrap files

    if [ ! '(' -f bootstrap-ca.pem -a -f bootstrap-cert.pem -a -f bootstrap-key.pem ')' ];then
        # but not all of them
        
        1>&2 echo "must have all or none of bootstrap-ca.pem bootstrap-cert.pem bootstrap-key.pem"
        exit 1
    fi
else
    # if there are none of them then make them with defaults.
    # use this for testing only.  copy real bootstrap certs in for configurability.

    consul tls ca create
    consul tls cert create -server
    cp consul-agent-ca.pem bootstrap-ca.pem
    cp dc1-server-consul-0-key.pem bootstrap-key.pem
    cp dc1-server-consul-0.pem bootstrap-cert.pem
fi


if [ ! -f "ca.pem" ];then
    cp bootstrap-ca.pem ca.pem
fi

if [ ! -f "cert.pem" ];then
    cp bootstrap-cert.pem cert.pem
fi

if [ ! -f "key.pem" ];then
    cp bootstrap-key.pem key.pem
fi

mkdir -p /consul/ca_certs
(cd /consul/ca_certs;ln -sf ../ca.pem .)

exec /bin/consul-template -template /consul/tls-shim.txt.tmpl:/tmp/tls-shim.txt -exec-reload-signal SIGHUP -exec "/usr/local/bin/docker-entrypoint.sh ${*@Q}"
