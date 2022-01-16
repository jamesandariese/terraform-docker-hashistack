#!/bin/sh

cd "$(dirname "$0")"

CONSUL_VERSION=1.11.2
CONSUL_TEMPLATE_VERSION=0.27.2
PLATFORMS="linux/arm64,linux/amd64"

docker buildx build --platform "$PLATFORMS" \
    --build-arg CONSUL_VERSION="$CONSUL_VERSION" \
    --build-arg CONSUL_TEMPLATE_VERSION="$CONSUL_TEMPLATE_VERSION" \
    -t jamesandariese/consul-tls:$CONSUL_VERSION \
    --push .
