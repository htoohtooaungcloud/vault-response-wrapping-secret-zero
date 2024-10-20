# HashiCorp Vault Response Wrapping to Solve Secret-Zero Problem

## Table of Contents

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
- **Postgresql** will be serve as database server for terraform `backend` for now.
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
3. Before run any terraform commands, must spin up the `postgresql-db-01` container first and configure as needed. Refer to `DB_README.md`.
4. Highly encourage to create new terraform local workspace by running `terraform workspace new <your-workspace-name>`. eg; 
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
Jenkins initial setup is required. An admin user has been created and a password generated.
Please use the following password to proceed to installation:

50492323cfd4475e814d74da74621644

This may also be found at: /var/jenkins_home/secrets/initialAdminPassword

```
--------------------------------------------------------------------------------------------------------------------------------------

### Some hcl files can be found under `/vault/config/` in the docker container
```
$ docker exec -i vault-server-1 ls -la /vault/config/
```

### Let's enable AppRole auth method for jenkins pipeline access
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
    token_type=batch \
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
## Jenkins part

### Jenkins need to install `Vault` CLI or copy over the `Vault` binary to this path `/usr/local/bin/` in the jenkins container
```
docker cp vault hellocloud-jenkins-1:/usr/local/bin/
```

### In Jenkins UI, install HashiCopr Vault pluggins

------------------------------------------------------------------------------------------------------------------------------------------
## Get the Trusted-Entity RoldId and SecretID for Jenkins Pipeline
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

[***Harbor Installation and Configuration***](https://goharbor.io/docs/2.0.0/install-config/)
------------------------------------------------------------------------------------------------------------------------------------------
## Integrate Jenkins and Github

- Integrate using SSH key since Jenkins in running as on-prem vm
- Jenkins side need to change `Dashboard` > `Manage Jenkins` > `Security` > `Git Host Key Verification Configuration`. Change it to `Accept first connection`. Default is `Known hosts file`.


## Contributing

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