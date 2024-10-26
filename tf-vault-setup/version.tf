provider "vault" {
  address = var.vault_cluster_address
  auth_login {
    path = var.tf_approle_login_path

    parameters = {
      role_id   = var.vault_tf_role_id   # Role ID from Vault
      secret_id = var.vault_tf_secret_id # Secret ID from Vault
    }
  }
}