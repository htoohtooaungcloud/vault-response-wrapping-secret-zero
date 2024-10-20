# Prior to terraform init, we need to create database username and database table for terraform backend
[Terraform backend pg](https://developer.hashicorp.com/terraform/language/backend/pg)

### Export `PGUSER` and `PGPASSWD` in `db.env` file for postgresql database
```
export PGUSER=yourusername
export PGPASSWORD=yourpassword
```
### Run postgresql container in the docker compose file
```
docker compose up -d
```
### Exec into postgresql container 
```
docker exec -it postgresql-db-01
```
### Login with `terraform` user name which is already defined as Environment Variables
```
psql -U terraform
```
### Create a database with `terraform_backend` name
```
CREATE DATABASE terraform_backend;
```
### Verify the `Access Privileges` of `terraform_backend` table
```
\l
```
### GRANT PERMISSION this database table `terraform_backend` to `terraform` user
```
GRANT ALL PRIVILEGES ON DATABASE terraform_backend TO terraform;
```

### Verification
```
\l
```
### Connect to the database
```
\c terraform_backend
You are now connected to database "terraform_backend" as user "terraform".
```

### SQL Query to check for terraform_backend database
```
SELECT datname FROM pg_database WHERE datname = 'terraform_backend';

      datname      
-------------------
 terraform_backend
(1 row)
```

### Try `terraform init` and exit from docker container
```
terraform init

Initializing the backend...

Successfully configured the backend "pg"! Terraform will automatically
use this backend unless the backend configuration changes.

Initializing provider plugins...
- Finding latest version of hashicorp/aws...
- Installing hashicorp/aws v5.72.1...
- Installed hashicorp/aws v5.72.1 (signed by HashiCorp)

Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
``` 

## How to check the terraform state file data in Postgresql

### Easy to check with PgAdmin if installed
### 
```
docker exec -it postgresql-db-01
```

### login to database with `terraform` username
```
psql -U terraform
```
### Check the database list
```
\l
                                                            List of databases
       Name        |   Owner   | Encoding | Locale Provider |  Collate   |   Ctype    | ICU Locale | ICU Rules |    Access privileges    
-------------------+-----------+----------+-----------------+------------+------------+------------+-----------+-------------------------
 postgres          | terraform | UTF8     | libc            | en_US.utf8 | en_US.utf8 |            |           | 
 template0         | terraform | UTF8     | libc            | en_US.utf8 | en_US.utf8 |            |           | =c/terraform           +
                   |           |          |                 |            |            |            |           | terraform=CTc/terraform
 template1         | terraform | UTF8     | libc            | en_US.utf8 | en_US.utf8 |            |           | =c/terraform           +
                   |           |          |                 |            |            |            |           | terraform=CTc/terraform
 terraform         | terraform | UTF8     | libc            | en_US.utf8 | en_US.utf8 |            |           | 
 terraform_backend | terraform | UTF8     | libc            | en_US.utf8 | en_US.utf8 |            |           | =Tc/terraform          +
                   |           |          |                 |            |            |            |           | terraform=CTc/terraform
```
### Switch to ther `terraform_backend` database
```
\c terraform_backend
```
### Make query to read terraform state file in `terraform_backend` 
```
SELECT jsonb_pretty(data::jsonb) FROM terraform_remote_state.states;
```
### Terraform State File data can be found here
![terraform-backend-postgresql](https://github.com/user-attachments/assets/a0820ef1-282e-45ad-ae37-9fdcee79d4e3)