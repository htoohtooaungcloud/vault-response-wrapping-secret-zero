output "trusted_entity_approle_role_name" {
  description = "This is AppRole Role Name of trusted_entity Secret"
  value       = vault_approle_auth_backend_role.trusted_entity_approle_role.role_name
}

output "trusted_entity_policy" {
  description = "This is Policy defined for Trusted Entity AppROle"
  value       = vault_policy.trusted_entity_policy.policy
}

# Output the AppRole Role-ID for Jenkins
output "trusted_entity_approle_role_id" {
  description = "This is AppRole Role ID of Trusted Entity Secret Path"
  value       = nonsensitive(vault_approle_auth_backend_role.trusted_entity_approle_role.role_id)
}

# Output the AppRole Secret-ID for Jenkins
output "trusted_entity_approle_role_secret_id" {
  description = "This is AppRole Role Secred ID for Trusted Entity"
  value       = vault_approle_auth_backend_role_secret_id.trusted_entity_role_sid.secret_id
  sensitive   = true
}