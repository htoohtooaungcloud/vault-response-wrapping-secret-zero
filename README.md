# HashiCorp Vault Response Wrapping to Solve Secret-Zero Problem

## Table of Contents

- [Project](#project)
- [Introduction](#introduction)
- [Features](#features)
- [Scope](#scope)
- [Goal](#goal)
- [Architecture](#architecture)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [Configuration](#configuration)
    - [Docker Deployment](#docker-deployment)
      - [Using Docker Compose](#using-docker-compose)
- [Contributing](#contributing)
------------------------------------------------------------------------------------------------------------------------------------------
## Project : *Secret-Zero*

## Introduction

- Distributing credentials via messaging applications introduces significant security risks, that leads the `Secret-Zero` problem.
- It's crucial to take control on your application's architecture, configuration management, orchestration tools, and CI/CD pipelines.
- HashiCorp Vault's `response-wrapping` feature offers a secure way to deliver credentials, ensuring sensitive data is transmitted safely to your platform while minimizing the risk of exposure.
- This will guide you how to securely deliver `SecretID` from Vault to application being build and/or deployed by your Trusted Orchestrator or CI/CD Pipeline as Trusted Entity.
------------------------------------------------------------------------------------------------------------------------------------------
## Features
- When requested, Vault can take the response it would have sent to an HTTP client and instead insert it into **cubbyhole** of a single-use token, returing that single-use token instead.
- The response is wrapped by the token, and retrieving it requireds an unwrap operation againt this token.
- Provide powerful mechanism for information sharing in many environments.
- Best option is to provider cover for the secrets, be able to detect middle-man interception **malfeasance** and limit-lifetimee of the secret exppsure.
- CI/CD pipeline provides significant automation benefits for your infrastructure and application development workflows.
------------------------------------------------------------------------------------------------------------------------------------------
## Scope
- **Vault** containers will run in a High Availability (HA) cluster for redundancy.
- **Nginx** will act as a reverse proxy and load balancer.
- **Jenkins** will handle the CI/CD pipeline automation.
- **Certbot** will generate SSL/TLS certificates. TLS is optional but will require adjustments to configuration files if omitted.
- **Terraform** for provision the Cloud API resources as Infrastructure as Code automation.
- **Terrform Cloud** will be serve as terraform `backend` and any workflow works fine.
------------------------------------------------------------------------------------------------------------------------------------------
## Goal
1. Jenkins Pipeline should securely retrieve secrets with a narrow scope, and the `Token` must expire immediately after the secrets are retrieved.
![Vault-Trusted-Orchestrator](https://github.com/user-attachments/assets/6ac9fcb4-79a1-488b-aef7-8bce0f57244b)
**Figure-1** The Goal of the Project

2. Vault must be running with `Auto-Unsealing` method using `AWS KMS`.
------------------------------------------------------------------------------------------------------------------------------------------
## Architecture 
![secret-zero-cicd](https://github.com/user-attachments/assets/cf65b5d1-3e99-457a-8235-1c9078aff7f9)
**Figure-2**- High-level Architecture

------------------------------------------------------------------------------------------------------------------------------------------
## Prerequisite: 

1. Install Docker engine, Terraform and docker compose plugin.
2. Create AWS KMS for Auto-Unsealing mechanism using `Terraform`. Credentials will be export as `vault_kms_auto_unseal.env` and Vault Cluster will pick that file while running docker-compose file. 
3. Change the `Terraform Cloud` Execution Mode from *Organization Default* to *Local(custom)*.
![vault-secret-zero-backend](https://github.com/user-attachments/assets/d618b443-f274-456f-b6e9-bcf8ece8db6e)

```
terraform workspace new vault-aws-kms
```

### SSL/TLS certificate generate using certbot
💡 Must have at least one domain for DNS Challenge to get TLS Cert

#### Exec into Cert bot container
```
docker exec -it certbot sh
```
### Generate the cert
```
certbot certonly --manual --preferred-challenges dns -d name.yourdomain --email customemail@gmail.com
```
- In the terminal, you will be prompted to create a DNS TXT record in your DNS management system

![dns-txt-record-dns-challenge-to-generate-ssl-cert](https://github.com/user-attachments/assets/5c89b27d-1e53-4912-b2e1-8679abb110de)

------------------------------------------------------------------------------------------------------------------------------------------
## Getting Started
### If the Unsealing method is `Auto-Unseal` using AWS KMS, apply the `terraform` first.

```
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```
### Run the docker compose file 
```
cd ./vault-response-wrapping-secret-zero
docker compose -f docker-compose.yaml up -d 
```
### Check all the containers logs thoroughly and ensure all containers are up and running properly.
```
docker logs -f vault-server-1
docker logs -f vault-server-2
docker logs -f vault-server-3
docker logs -f nginx-server
docker logs -f hellocloud-jenkins-1
```
### Let's Initialize the Vault Cluster
```
$ vault operator init
```
### Vault Initialization Output
```
**Keep your keys and important tokens**

Success! Vault is initialized

Recovery key initialized with 5 key shares and a key threshold of 3. Please
securely distribute the key shares printed above.
```

### Jenkins Root Password
```
docker logs -f jenkins
```
### Log in to Jenkins using this password and just change the password immidiately
```
*************************************************************
*************************************************************
*************************************************************

Jenkins initial setup is required. An admin user has been created and a password generated.
Please use the following password to proceed to installation:

3d590fdb69e24a739bd6f8156a3866a6

This may also be found at: /var/jenkins_home/secrets/initialAdminPassword

*************************************************************
*************************************************************
*************************************************************

```
--------------------------------------------------------------------------------------------------------------------------------------

### Some hcl files can be found under `/vault/config/` in the docker container
```
$ docker exec -i vault-server-1 ls -la /vault/config/
```
# Mananged Vault Cluster using Terraform
### This approach is the automated approach, initially need to understand how to configure against Vault Cluster using `Vault Command`
### After unsealling Vault Cluster, Configure `tf-admin` AppRole Path
```
vault auth enable -path=tf-admin approle
```
### Write the admin policy for `tf-admin-policy`
```
vault policy write tf-admin-policy tf-admin-policy.hcl
```
### List the Policy
```
vault policy list
default
tf-admin-policy
root
```
### Admin Policy
<details>
<summary>Admin Policy</summary>

```
# Manage auth methods broadly across Vault
path "auth/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Create, update, and delete auth methods
path "sys/auth/*" {
  capabilities = ["create", "update", "delete", "sudo"]
}

# List auth methods
path "sys/auth" {
  capabilities = ["read"]
}

# Create and manage ACL policies
path "sys/policies/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# To list policies - Step 3
path "sys/policies/" {
  capabilities = ["list"]
}

# List, create, update, and delete key/value secrets mounted under secret/
path "secret/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# List secret/
path "secret/" {
  capabilities = ["list"]
}

# Prevent admin users from reading user secrets
# But allow them to create, update, delete, and list them
path "secret/users/*" {
  capabilities = ["create", "update", "delete", "list"]
}

# List, create, update, and delete key/value secrets mounted under kv/
path "kv/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# List kv/
path "kv/" {
  capabilities = ["list"]
}

# Prevent admin users from reading user secrets
# But allow them to create, update, delete, and list them
# Creating and updating are explicitly included here
# Deleting and listing are implied by capabilities given on kv/* which includes kv/delete/users/* and kv/metadata/users/* paths
path "kv/data/users/*" {
  capabilities = ["create", "update"]
}

# Active Directory secrets engine
path "ad/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Alicloud secrets engine
path "alicloud/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# AWS secrets engine
path "aws/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Azure secrets engine
path "azure/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Google Cloud secrets engine
path "gcp/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Google Cloud KMS secrets engine
path "gcpkms/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Consul secrets engine
path "consul/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Cubbyhole secrets engine
path "cubbyhole/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Database secrets engine
path "database/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Identity secrets engine
path "identity/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# PKI secrets engine
path "nomad/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Nomad secrets engine
path "pki/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# RabbitMQ secrets engine
path "rabbitmq/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# SSH secrets engine
path "ssh/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# TOTP secrets engine
path "totp/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Transit secrets engine
path "transit/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Create and manage secrets engines broadly across Vault.
path "sys/mounts/*"
{
  capabilities = ["create", "read", "update", "delete", "list"]
}

# List sys/mounts/
path "sys/mounts" {
  capabilities = ["read"]
}

# Check token capabilities
path "sys/capabilities" {
  capabilities = ["create", "update"]
}

# Check token accessor capabilities
path "sys/capabilities-accessor" {
  capabilities = ["create", "update"]
}

# Check token's own capabilities
path "sys/capabilities-self" {
  capabilities = ["create", "update"]
}

# Audit hash
path "sys/audit-hash" {
  capabilities = ["create", "update"]
}

# Health checks
path "sys/health" {
  capabilities = ["read"]
}

# Host info
path "sys/host-info" {
  capabilities = ["read"]
}

# Key Status
path "sys/key-status" {
  capabilities = ["read"]
}

# Leader
path "sys/leader" {
  capabilities = ["read"]
}

# Plugins catalog
path "sys/plugins/catalog/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# List sys/plugins/catalog
path "sys/plugins/catalog" {
  capabilities = ["read"]
}

# Read system configuration state
path "sys/config/state/sanitized" {
  capabilities = ["read"]
}

# Use system tools
path "sys/tools/*" {
  capabilities = ["create", "update"]
}

# Generate OpenAPI docs
path "sys/internal/specs/openapi" {
  capabilities = ["read"]
}

# Lookup leases
path "sys/leases/lookup" {
  capabilities = ["create", "update"]
}

# Renew leases
path "sys/leases/renew" {
  capabilities = ["create", "update"]
}

# Revoke leases
path "sys/leases/revoke" {
  capabilities = ["create", "update"]
}

# Tidy leases
path "sys/leases/tidy" {
  capabilities = ["create", "update"]
}

# Telemetry
path "sys/metrics" {
  capabilities = ["read"]
}

# Seal Vault
path "sys/seal" {
  capabilities = ["create", "update", "sudo"]
}

# Unseal Vault
path "sys/unseal" {
  capabilities = ["create", "update", "sudo"]
}

# Step Down
path "sys/step-down" {
  capabilities = ["create", "update", "sudo"]
}

# Wrapping
path "sys/wrapping/*" {
  capabilities = ["create", "update"]
}

## Enterprise Features

# Manage license
path "sys/license/status" {
  capabilities = ["create", "read", "update"]
}

# Use control groups
path "sys/control-group/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# MFA
path "sys/mfa/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# List MFA
path "sys/mfa/" {
  capabilities = ["list"]
}

# Namespaces
path "sys/namespaces/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# List sys/namespaces
path "sys/namespaces/" {
  capabilities = ["list"]
}

# Replication
path "sys/replication/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Seal Wrap
path "sys/sealwrap/rewrap" {
  capabilities = ["create", "read", "update"]
}

# KMIP secrets engine
path "kmip/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
```
</details>

### Read the Policy `tf-admin-policy`
```
vault policy read tf-admin-policy
```
### Create AppRole Auth Method ROLE at `auth/tf-admin/role/tf-admin-role` for Terraform
```
vault write auth/tf-admin/role/tf-admin-role  \
    token_ttl=72h \
    token_num_uses=0 \
    secret_id_num_uses=0 \
    token_policies="tf-admin-policy"
```
### Read that Role to get `Rold-ID`
```
vault read auth/tf-admin/role/tf-admin-role/role-id
```
### Write that Role to get `Secret-ID` with force
```
vault write -f auth/tf-admin/role/tf-admin-role/secret-id
```
### Pass these two credentials to `terraforn-variable.tfvars` file and then run the terraform code
![terraform-variable tfvars](https://github.com/user-attachments/assets/fc68efd3-5a4f-4522-a096-b7ffd2528c11)

---------------------------------------------------------------------------------------------------------------------------------------------
### Let's enable Vautl AppRole Auth Method for Jenkins Pipeline
1. The role of this Jenkins AppRole should be narrowed-scope since we just need to read and write the role-id and secret-id

### Enable AppRole Auth Method First
```
$ vault auth enable approle
Success! Enabled approle auth method at: approle/
$ vault auth list
Path        Type       Accessor                 Description                Version
----        ----       --------                 -----------                -------
approle/    approle    auth_approle_a7c3e202    n/a                        n/a
token/      token      auth_token_707c0f22      token based credentials    n/a

```
### Configure the policy (trusted-entity-policy)
```
$ vault policy write trusted-entity-policy trusted-entity-policy.hcl
Success! Uploaded policy: trusted-entity-policy
```
```
$ vault policy list
default
trusted-entity-policy
root
```
```
$ vault policy read trusted-entity-policy
path "auth/approle/role/+/secret*" {
  capabilities = [ "create", "read", "update" ]
}

path "auth/approle/role/+/role*" {
  capabilities = [ "read" ]
}
```

### Let config Approle's Role, the path is `auth/approle/role` and the name is `jenkins-vault-role`. (Narrow-scope and CIDR bound)
### Attached the trusted-entity-policy
```
vault write auth/approle/role/trusted-entity  \
    token_num_uses=2 \
    token_ttl=72h \
    secret_id_num_uses=0 \
    token_bound_cidrs="172.20.0.2/32" \
    secret_id_bound_cidrs="172.20.0.2/32" \
    token_policies="trusted-entity-policy"
```
### Verify
```
$ vault read auth/approle/role/trusted-entity
Key                        Value
---                        -----
bind_secret_id             true
local_secret_ids           false
secret_id_bound_cidrs      [172.20.0.2/32]
secret_id_num_uses         0
secret_id_ttl              0s
token_bound_cidrs          [172.20.0.2]
token_explicit_max_ttl     0s
token_max_ttl              0s
token_no_default_policy    false
token_num_uses             2
token_period               0s
token_policies             [trusted-entity-policy]
token_ttl                  72h
token_type                 default
```
### Let's create a pair of secret at kv v2 secret engine
```
tee data.json <<EOF
{
   "username": "robot\$cr",
   "password": "r9naldo"
}
EOF
```
### Enable `kv v2` secret engine
```
$ vault secrets enable --version=2 -path=secret -description="Secrets Engine for kv v2" kv
```
### Put the secrets under this path `secret/container-registry` 
```
$ vault kv put secret/container-registry @data.json
========= Secret Path =========
secret/data/container-registry

======= Metadata =======
Key                Value
---                -----
created_time       2024-10-18T08:47:00.43150816Z
custom_metadata    <nil>
deletion_time      n/a
destroyed          false
version            1
```

### Verfiy
```
$ vault kv get secret/container-registry
========= Secret Path =========
secret/data/container-registry

======= Metadata =======
Key                Value
---                -----
created_time       2024-10-18T08:54:56.346683774Z
custom_metadata    <nil>
deletion_time      n/a
destroyed          false
version            2

====== Data ======
Key         Value
---         -----
password    r9naldo
username    robot$cr
```
### Let's try print with field output
```
$ vault kv get -field=username secret/container-registry
robot$cr
```
### Create a policy just to fetch the secrets. Path `/vault/config/cr-secrets.hcl`
```
path "secret/data/container-registry" {
  capabilities = ["read"]
}
```
### Create a policy
```
$ vault policy write container-registry cr-secrets.hcl
```
### List the policy
```
$ vault policy list
container-registry
default
trusted-entity-policy
root
```
### Read the created policy `container-registry`
```
$ vault policy read container-registry
path "secret/data/container-registry" {
  capabilities = ["read"]
}
```

### Create AppRole Role to fecth the secret from Vault
```
vault write auth/approle/role/container-registry  \
    token_num_uses=2 \
    token_ttl=100s \
    token_max_ttl=200s \
    secret_id_ttl=200s \
    secret_id_num_uses=2 \
    token_bound_cidrs="172.20.0.2/32" \
    secret_id_bound_cidrs="172.20.0.2/32" \
    token_policies="container-registry"
```
--------------------------------------------------------------------------------------------------------------------------------------

### Jenkins Configuration


#### In Jenkins UI, install HashiCopr Vault pluggins

------------------------------------------------------------------------------------------------------------------------------------------
### Get the Trusted-Entity RoldID and SecretID for Jenkins Pipeline
### Read the Role-id
```
$ vault read -field=role_id auth/approle/role/trusted-entity/role-id
```
### Write the Secret-id
```
$ vault write -field=secret_id -f auth/approle/role/trusted-entity/secret-id
```
------------------------------------------------------------------------------------------------------------------------------------------
## Manual (The hard way)



------------------------------------------------------------------------------------------------------------------------------------------
## Harbor (Option)

- Follow the installation guide line from harbor official website.
- Prefer install harbor on **VM** and generate SSL/TLS certificate.

[Harbor Installation and Configuration](https://goharbor.io/docs/2.0.0/install-config/)
------------------------------------------------------------------------------------------------------------------------------------------
## Integrate Jenkins and Github

- Integrate using SSH key since Jenkins in running as on-prem vm
- Jenkins side need to change `Dashboard` > `Manage Jenkins` > `Security` > `Git Host Key Verification Configuration`. Change it to `Accept first connection`. Default is `Known hosts file`.

-------------------------------------------------------------------------------------------------------------------------------------------
## Git: Reset Local Branch to Match Remote Branch (Duplicated)
1. Fetch the Latest Changes from the Remote Repository
```
git fetch origin
```
2. Reset Your Local `main` Branch to Match the Remote `origin/main`.
> [!NOTE]
> Makes your local branch `identical` to the remote branch. Discards **all local changes and commits** (including any commits that haven’t been pushed).
```
git reset --hard origin/main
```
3. Verify Your Local Branch is Now Aligned
```
git status
```
## Contributing
### Should see the following output:
```
On branch main
Your branch is up to date with 'origin/main'.
nothing to commit, working tree clean
```
4. (Optional) Clean Up Untracked Files
```
git clean -fd
```
---------------------------------------------------------------------------------------------------------------------------------------------
Contributions are welcome! Please follow these guidelines:

1. **Fork the Repository**

2. **Create a Feature Branch**

   ```bash
   git checkout -b feature/YourFeature
   ```

3. **Commit Your Changes**

   ```bash
   git commit -m "Add your feature" # (For example; new feature; terraform configuration files for creation of AWS KMS)
   ```

4. **Push to the Branch**

   ```bash
   git push origin feature/YourFeature
   ```

5. **Open a Pull Request**

   Please provide a clear description of your changes and the problem they solve.