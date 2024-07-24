path "auth/approle/role/*" {
  capabilities = ["list"]
}

path "auth/approle/role/aredn_*" {
  capabilities = ["read"]
  denied_parameters = {
    policies = []
    token_policies = []
  }
}

path "secret/aredn/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "transit/keys/aredn*" {
  capabilities = ["read", "list"]
}

path "transit/encrypt/aredn*" {
  capabilities = ["read", "list"]
}

path "transit/decrypt/aredn*" {
  capabilities = ["read", "list"]
}
