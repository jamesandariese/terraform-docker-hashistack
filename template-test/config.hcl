vault {
    vault_agent_token_file = "./vault-agent-token"
    #unwrap_token = true
    renew_token = true  
}

template {
    source = "ca.pem.tmpl"
    destination = "ca.pem"
}
template {
    source = "key.pem.tmpl"
    destination = "key.pem"
}
template {
    source = "cert.pem.tmpl"
    destination = "cert.pem"
}
