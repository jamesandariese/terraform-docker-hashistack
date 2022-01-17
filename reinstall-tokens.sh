#!/bin/sh

# if you've restored a snapshot of consul but deployed new tokens via terraform,
# for example due to a clean run followed by consul snapshot restore, you will
# need to restore the tokens from bootstrap into your cluster.
#
# this script does that.  it will leave the old tokens in place as well as
# reinstall these new tokens.

if [ $# -lt 2 ];then
    echo "usage: $0 <https-address-of-consul-server> <existing-management-token>"
    exit 1
fi

TOKEN="$2"

CONSUL_ARGS="-http-addr=$1 -tls-server-name=server.dc1.consul -ca-file=consul-agent-ca.pem"

MANAGEMENT_TOKEN=$(jq -r .management.secret tokens.json)
MANAGEMENT_ACCESSOR=$(jq -r .management.accessor tokens.json)
VAULT_TOKEN=$(jq -r .vault.secret tokens.json)
VAULT_ACCESSOR=$(jq -r .vault.accessor tokens.json)

MANAGEMENT_DESCRIPTION="global management token"
VAULT_DESCRIPTION="vault node and service token"

consul acl token create -description="$VAULT_DESCRIPTION" -secret="$VAULT_TOKEN" -accessor="$VAULT_ACCESSOR" -policy-name=vault-server -token="$TOKEN" $CONSUL_ARGS
consul acl token create -description="$MANAGEMENT_DESCRIPTION" -secret="$MANAGEMENT_TOKEN" -accessor="$MANAGEMENT_ACCESSOR" -policy-name=global-management -token="$TOKEN" $CONSUL_ARGS

