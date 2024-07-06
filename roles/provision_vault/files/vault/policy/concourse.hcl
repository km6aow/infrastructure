path "auth/approle/role/*" {
  capabilities = ["list"]
}

path "auth/approle/role/concourse_*" {
  capabilities = ["read"]
  denied_parameters = {
    policies = []
    token_policies = []
  }
}

path "secret/+/concourse-ci/*" {
  capabilities = ["read", "list"]
}

path "secret/concourse/concourse-ci/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "transit/keys/concourse*" {
  capabilities = ["read", "list"]
}

path "transit/encrypt/concourse*" {
  capabilities = ["read", "list"]
}

path "transit/decrypt/concourse*" {
  capabilities = ["read", "list"]
}
