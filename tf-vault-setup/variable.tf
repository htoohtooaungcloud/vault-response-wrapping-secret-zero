# HashiCorp Vault Cluster IP Address
variable "vault_cluster_address" {
  description = "Vault Clusters Address"
  type        = string
  default     = "http://0.0.0.0:8200"
}
# Vault AppRole Login Path for Terraform
variable "tf_approle_login_path" {
  description = "Vault Terraform Admin AppRole Login Path"
  type        = string
  default     = "auth/<you-path>/login" # This could be auth/approle/login as well. It's depends on what you defined initially in Vault
}
#  Vault AppRole Role-ID to Login to Vault
variable "vault_tf_role_id" {
  description = "Vault Terraform Role-ID"
  type        = string
  default     = "your-role-id" # This should be in .tfvars
}

#  Vault AppRole Secret-ID to Login to Vault
variable "vault_tf_secret_id" {
  description = "Vault Terraform Secret-ID"
  type        = string
  default     = "your-secret-id" # This should be in .tfvars
}

#  Vault KV V2 Secret for Container Registry Username
variable "kv_secret_cr_username" {
  description = "Vault Secret Container Reistry Name"
  type        = string
  default     = "your-secret -id" # This should be in .tfvars
}

#  Vault KV V2 Secret for Container Registry Password
variable "kv_secret_cr_password" {
  description = "Vault Secret Container Reistry Name"
  type        = string
  default     = "your-secret -id" # This should be in .tfvars
}

# Vault Authentication Backend Type AppRole
variable "auth_backend_type" {
  description = "Backend type for Approle Auth Method"
  default     = "approle"
}

# Vault Authentication Method Custom Path
# variable "auth_backend_path" {
#   description = "Approle Auth Backend Path"
#   default     = "your-custom-auth-method-path"
# }

# Vault AppRole Trusted-Entity Authentication ROLE name 
variable "trusted_entity_policy_approle_role_name" {
  description = "Vault Trusted Entity AppRole ROle Name"
  default     = "trusted-entity"
}

# Vault AppRole Container Registry Authentication ROLE name 
variable "container_registry_approle_role_name" {
  description = "Vault Container Registry  AppRole Role Name"
  default     = "container-registry"
}

