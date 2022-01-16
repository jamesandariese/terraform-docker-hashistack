data "local_file" "consul_bootstrap_token_raw" {
    filename = "consul.key"
}

locals {
    consul_acl_tokens = jsondecode(file("${path.root}/tokens.json"))
    consul_bootstrap_token = trimspace(data.local_file.consul_bootstrap_token_raw.content)
}
