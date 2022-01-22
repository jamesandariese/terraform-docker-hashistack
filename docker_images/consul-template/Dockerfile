ARG VAULT_VERSION=1.9.1
ARG CONSUL_TEMPLATE_VERSION=0.27.2

FROM vault:$VAULT_VERSION AS vault
FROM hashicorp/consul-template:$CONSUL_TEMPLATE_VERSION AS consul-template
FROM alpine:3

RUN apk add bash jq

COPY --from=vault /bin/vault /bin/vault
COPY --from=consul-template /bin/consul-template /bin/consul-template

RUN mkdir /vault-agent-config
RUN mkdir /consul-template-config

VOLUME /vault-agent-config
VOLUME /consul-template-config

RUN mkdir /approle
VOLUME /approle

RUN mkdir /ca-certificates
VOLUME /ca-certificates

ADD --chown=0:0 docker-vault-agent-entrypoint.sh /bin/docker-vault-agent-entrypoint.sh
ADD consul-template-config.hcl /consul-template-config/config.hcl
ADD vault-agent-config.hcl /vault-agent-config/config.hcl

RUN chmod a+x /bin/docker-vault-agent-entrypoint.sh

ENTRYPOINT ["/bin/docker-vault-agent-entrypoint.sh"]
