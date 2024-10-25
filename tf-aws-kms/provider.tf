terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.72.1"
    }
  }
  cloud {

    organization = "hc-multi-project"

    workspaces {
      name = "vault-secret-zero-response-wrapping"
    }
  }
}


