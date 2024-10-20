path "auth/approle/role/+/secret*" {
  capabilities = [ "create", "read", "update" ]
}

path "auth/approle/role/+/role*" {
  capabilities = [ "read" ]
}


