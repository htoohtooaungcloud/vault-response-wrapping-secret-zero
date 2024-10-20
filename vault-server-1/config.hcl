storage "raft" {
  path    = "/opt/vault/data"
  node_id = "vault-server-1" # node hostname

  retry_join {
    leader_api_addr = "http://vault-server-1:8200"
  }
  retry_join {
    leader_api_addr = "http://vault-server-1:8200"
  }
}
listener "tcp" {
 address = "0.0.0.0:8200"  # Or "vault-server-1:8200"
 cluster_address = "0.0.0.0:8201"  # Or "vault-server-1:8201"
 tls_disable = true
}
seal "awskms" {
  access_key = "${AWS_ACCESS_KEY_ID}"
  secret_key = "${AWS_SECRET_ACCESS_KEY}"
  region     = "${AWS_REGION}"
  kms_key_id = "${VAULT_AWSKMS_SEAL_KEY_ID}"
}       
api_addr = "http://vault-server-1:8200"
cluster_addr = "http://vault-server-1:8201"
cluster_name = "vault-ha-cluster"
ui = true
log_level = "DEBUG" # Or INFO
disable_mlock = true