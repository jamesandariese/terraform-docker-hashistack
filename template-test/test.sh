#!/usr/bin/env bash

cd "$(dirname "$0")"

set -e
set -x

vault agent -exit-after-auth -config=vault-agent-config.hcl
#jq -r .token vault-agent-token-wrapping.json > vault-agent-token

consul-template -log-level debug -once -config=config.hcl

openssl verify -CAfile ca.pem cert.pem
