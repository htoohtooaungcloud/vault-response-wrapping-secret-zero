# Terraform Admin policy providing full access to all paths and capabilities
path "sys/*" {
  capabilities = ["create", "update", "read", "delete", "list", "sudo"]
}

path "auth/*" {
  capabilities = ["create", "update", "read", "delete", "list", "sudo"]
}

path "secret/*" {
  capabilities = ["create", "update", "read", "delete", "list", "sudo"]
}

path "identity/*" {
  capabilities = ["create", "update", "read", "delete", "list", "sudo"]
}

path "cubbyhole/*" {
  capabilities = ["create", "update", "read", "delete", "list"]
}

path "sys/mounts/*" {
  capabilities = ["create", "update", "read", "delete", "list", "sudo"]
}

path "sys/leases/*" {
  capabilities = ["create", "update", "read", "sudo", "list"]
}

path "sys/config/*" {
  capabilities = ["create", "update", "read", "delete", "list", "sudo"]
}

path "sys/policies/*" {
  capabilities = ["create", "update", "read", "delete", "list", "sudo"]
}

path "sys/health" {
  capabilities = ["read"]
}

path "sys/audit/*" {
  capabilities = ["create", "update", "read", "delete", "list", "sudo"]
}

path "sys/control-group/*" {
  capabilities = ["create", "update", "read", "delete", "list", "sudo"]
}

path "sys/tools/*" {
  capabilities = ["create", "update", "read", "list", "sudo"]
}

path "sys/expire/*" {
  capabilities = ["read", "list", "update", "delete"]
}