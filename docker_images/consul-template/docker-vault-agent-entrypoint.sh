#!/bin/bash

set -e
set -x

# take out every zig
mkdir -p /vault-agent-config
mkdir -p /consul-template-config
shopt -s nullglob

VAULT_AGENT_CMD="/bin/vault agent -exit-after-auth"
for f in /vault-agent-config/*.*;do
    VAULT_AGENT_CMD="$VAULT_AGENT_CMD -config=${f@Q}"
done
eval "$VAULT_AGENT_CMD"

if [ -f "/vault-agent-token-wrapping.json" ];then
    jq -r .token /vault-agent-token-wrapping.json > /vault-agent-token
fi

if [ x"$VAULT_SHORT_CIRCUIT" = xyes ];then
    cat /vault-agent-token
    sleep 60
    exit 1
fi

exec /bin/consul-template -config=/consul-template-config/
