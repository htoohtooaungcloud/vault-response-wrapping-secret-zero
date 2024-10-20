terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.72.1"
    }
  }
  backend "pg" {
    conn_str = "postgres://192.168.1.43/terraform_backend?sslmode=disable"
  }
}


