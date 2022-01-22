## Consul Template for approles

This is a docker image meant to start consul-template with access to vault via
an approle.  The default config expects the following:

* an approle role_id in /approle/role_id
* an approle secret_id in /approle/secret_id
* a vault server at https://vault.service.consul:8200
* TLS configured on vault server
* a CA cert present for the vault server in /ca-certificates

It will do the following:

* read configs from /vault-agent-config
* login with the approle from /approle
* write a wrapped vault token in /vault-agent-token-wrapping.json
* extract the token from the json output and place it in /vault-agent-token
  * if the json input doesn't exist, the vault-agent-token isn't created
    and no error is produced
* run consul-template with configs from /consul-template-config
