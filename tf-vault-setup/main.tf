#######################################################################
# Policy Creation
#######################################################################

# Create Trusted Entity Policy for Jenkins
resource "vault_policy" "trusted_entity_policy" {
  name = "trusted-entity-policy"

  policy = <<EOT
path "auth/approle/role/+/role*" {
  capabilities = [ "read" ]
}

path "auth/approle/role/+/secret*" {
  capabilities = [ "create", "read", "update" ]
}
EOT
}

# Create Container Registry Policy for Jenkins
resource "vault_policy" "container_registry_policy" {
  name = "container-registry-policy"

  policy = <<EOT
path "secret/data/container-registry" {
  capabilities = ["read"]
}
EOT
}

#######################################################################
# Authentication Method Creation
#######################################################################

# Create Trusted Entity AppRole for Jenkins
resource "vault_auth_backend" "approle_path" {
  description = "Vault AppRole Auth Method Path"
  type        = var.auth_backend_type
  # path        = var.auth_backend_path   # Path will be default path `approle`
}

# Create Trusted Entity AppRole ROLE for Jenkins
resource "vault_approle_auth_backend_role" "trusted_entity_approle_role" {
  backend               = vault_auth_backend.approle_path.path
  role_name             = var.trusted_entity_policy_approle_role_name
  token_num_uses        = 2    # Usage number of the token that generated after authenticated to Vault
  secret_id_num_uses    = 0    # Can use the secret-id infinitely
  token_ttl             = 1440 # Suggest to check how often required to build 
  token_max_ttl         = 4320
  token_bound_cidrs     = ["172.19.0.5/32"] # Could it be Jenkins Server's IP Address or Load-Balancer's IP Address as LIST
  secret_id_bound_cidrs = ["172.19.0.5/32"] # Could it be Jenkins Server's IP Address or Load-Balancer's IP Address as LIST
  token_policies        = [vault_policy.trusted_entity_policy.name]
  depends_on  = [vault_auth_backend.approle_path]
}

# Uses "Push" mode and get the Secret-ID
resource "vault_approle_auth_backend_role_secret_id" "trusted_entity_role_sid" {
  backend   = vault_auth_backend.approle_path.path
  role_name = vault_approle_auth_backend_role.trusted_entity_approle_role.role_name
}

# Create AppRole Role to retrieve the secret from Vault via Pipeline 
resource "vault_approle_auth_backend_role" "container_registry_secret_approle_role" {
  backend               = vault_auth_backend.approle_path.path
  role_name             = var.container_registry_approle_role_name
  token_num_uses        = 2    # Usage number of the token that generated after authenticated to Vault
  token_ttl             = 100 
  token_max_ttl         = 200
  secret_id_num_uses    = 2    
  secret_id_ttl         = 200  
  token_bound_cidrs     = ["172.19.0.5/32"] # Could it be Jenkins Server's IP Address or Load-Balancer's IP Address as LIST
  secret_id_bound_cidrs = ["172.19.0.5/32"] # Could it be Jenkins Server's IP Address or Load-Balancer's IP Address as LIST
  token_policies        = [vault_policy.container_registry_policy.name]
  depends_on  = [vault_auth_backend.approle_path]
}

#######################################################################
# Secret Creation
#######################################################################
# Enable KV V2 Secret Engine at 'secret/' path (if not already enabled)
resource "vault_mount" "secret_kvv2" {
  path        = "secret"
  type        = "kv"
  description = "Secrets Engine for kv v2"
  options     = { version = "2" }
  depends_on  = [] # Optional: Add dependencies if needed
}

# Store secrets under 'secret/container-registry' path
resource "vault_kv_secret_v2" "container_registry" {
  mount = vault_mount.secret_kvv2.path
  name  = "container-registry" # This creates the secret at 'secret/container-registry'

  # JSON data to store in the secret
  data_json = jsonencode({
    username = var.kv_secret_cr_username
    password = var.kv_secret_cr_password
  })

  # Custom metadata for the secret
  custom_metadata {
    max_versions = 10 # Optional: Maximum number of versions to retain
    data = {
      project = "secret-zero"
      owner   = "hellocloud"
    }
  }
  depends_on = [vault_mount.secret_kvv2] # Optional: Add dependencies if needed
}