#!/bin/sh

set -x

cd "$(dirname "$0")"

until curl -k "$1" 2>&1 > /dev/null;do
    echo waiting for consul to come up
    sleep 5
done

if [ x"$MANAGEMENT_TOKEN" = x ];then 1>&2 echo MANAGEMENT_TOKEN not set ; exit 1;fi
if [ x"$MANAGEMENT_ACCESSOR" = x ];then 1>&2 echo MANAGEMENT_ACCESSOR not set ; exit 1;fi
if [ x"$VAULT_TOKEN" = x ];then 1>&2 echo VAULT_TOKEN not set ; exit 1;fi
if [ x"$VAULT_ACCESSOR" = x ];then 1>&2 echo VAULT_ACCESSOR not set ; exit 1;fi
MANAGEMENT_DESCRIPTION="global management token"
VAULT_DESCRIPTION="vault node and service token"

CONSUL_ARGS="-http-addr=$1 -tls-server-name=server.dc1.consul -ca-file=consul-agent-ca.pem"

BOOTSTRAP="$(consul acl bootstrap -format=json $CONSUL_ARGS)"
if [ $? -eq 0 ];then
    TOKEN="$(echo "$BOOTSTRAP" | jq -r .SecretID)"
    BOOTSTRAP_ACCESSOR="$(echo "$BOOTSTRAP" | jq -r .AccessorID)"
else
    consul acl policy read -name 'global-management' -token="$MANAGEMENT_TOKEN" $CONSUL_ARGS > /dev/null
    if [ $? -ne 0 ];then
        echo "cannot bootstrap but passed MANAGEMENET_TOKEN is not valid either.  cannot continue."
        echo "you may reset the ACL bootstrap process to fix this.  See:"
        echo "https://learn.hashicorp.com/tutorials/consul/access-control-troubleshoot?utm_source=consul.io&utm_medium=docs#reset-the-acl-system"
        exit 1
    fi
    TOKEN="$MANAGEMENT_TOKEN"
fi

consul acl policy delete -name=allow-lookup -token="$TOKEN" $CONSUL_ARGS || true
consul acl policy create -name=allow-lookup -rules=@acls/allow-lookup.acl -token="$TOKEN" -format=json $CONSUL_ARGS
consul acl token update -policy-name=allow-lookup -id anonymous -token="$TOKEN" $CONSUL_ARGS

if [ x"$TOKEN" = x"$MANAGEMENT_TOKEN" ];then
    echo "TOKEN = MANAGEMENT_TOKEN.  skipping creation"
else
    consul acl token create -description="$MANAGEMENT_DESCRIPTION" -secret="$MANAGEMENT_TOKEN" -accessor="$MANAGEMENT_ACCESSOR" -policy-name=global-management -token="$TOKEN" $CONSUL_ARGS
    echo "Management token created.  Switching to it."
    TOKEN="$MANAGEMENT_TOKEN"
    consul acl token delete -id="$BOOTSTRAP_ACCESSOR" -token="$TOKEN" $CONSUL_ARGS
fi

consul acl policy delete -name=vault-server -token="$TOKEN" $CONSUL_ARGS || true
consul acl policy create -name=vault-server -rules=@acls/vault-server.acl -token="$TOKEN" $CONSUL_ARGS
consul acl token delete -id="$VAULT_ACCESSOR" -token="$TOKEN" $CONSUL_ARGS
consul acl token create -description="$VAULT_DESCRIPTION" -secret="$VAULT_TOKEN" -accessor="$VAULT_ACCESSOR" -policy-name=vault-server -token="$TOKEN" $CONSUL_ARGS