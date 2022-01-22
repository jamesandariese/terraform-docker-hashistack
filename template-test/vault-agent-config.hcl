vault {
    address = "https://vault.service.consul:8200"
    ca_path = "./ca-certificates"
}

auto_auth {
    method {
        type = "approle"
        config = {
            role_id_file_path = "./approle/role_id"
            secret_id_file_path = "./approle/secret_id"
            remove_secret_id_file_after_reading = false
        }
        #wrap_ttl = "30s"
    }
    sink {
        type = "file"
        config = {
            #path = "./vault-agent-token-wrapping.json"
            path = "./vault-agent-token"
        }
    }
}
log_level="trace"

