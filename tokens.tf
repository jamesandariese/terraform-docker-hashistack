# this file loads in the tokens in your tokens.json file
# and keeps them in memory rather than in state.  booyah

locals {
    consul_acl_tokens = jsondecode(file("${path.root}/tokens.json"))
}
