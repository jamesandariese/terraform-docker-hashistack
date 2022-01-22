vault {
    address = "https://vault.service.consul:8200"

    vault_agent_token_file = "/vault-agent-token"
    unwrap_token = false
    renew_token = true
    ssl {
        enabled = true
        verify = true
        ca_path = "/ca-certificates"
    }
}

log_level = "info"
