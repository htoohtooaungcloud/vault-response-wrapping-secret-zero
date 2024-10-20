provider "aws" {
  shared_config_files      = ["/home/vagrant/.aws/config"]
  shared_credentials_files = ["/home/vagrant/.aws/credentials"]
  profile                  = "poc-master-programmatic-admin"
  region                   = var.aws_default_region
}
