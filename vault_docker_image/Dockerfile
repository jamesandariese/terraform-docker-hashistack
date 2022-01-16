ARG VAULT_VERSION=1.9.1
ARG CONSUL_VERSION=1.11.2
ARG CONSUL_TEMPLATE_VERSION=0.27.2

FROM hashicorp/consul-template:$CONSUL_TEMPLATE_VERSION AS consul-template

FROM consul:$CONSUL_VERSION AS consul

FROM vault:$VAULT_VERSION
COPY --from=consul /bin/consul /bin/consul

COPY --from=consul-template /bin/consul-template /bin/consul-template
ADD --chown=0:0 docker-tls-entrypoint.sh /usr/local/bin/
RUN chmod a+x /usr/local/bin/docker-tls-entrypoint.sh
RUN apk add bash

ENTRYPOINT ["/usr/local/bin/docker-tls-entrypoint.sh"]
