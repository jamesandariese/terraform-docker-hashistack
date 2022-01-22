#!/bin/sh

cd "$(dirname "$0")"

VAULT_VERSION=1.9.1
CONSUL_TEMPLATE_VERSION=0.27.2
PLATFORMS="linux/arm64,linux/amd64"

docker buildx build --platform "$PLATFORMS" \
    --build-arg CONSUL_TEMPLATE_VERSION="$CONSUL_TEMPLATE_VERSION" \
    --build-arg VAULT_AGENT_VERSION="$CONSUL_TEMPLATE_VERSION" \
    -t jamesandariese/consul-template:$CONSUL_TEMPLATE_VERSION \
    --push .
