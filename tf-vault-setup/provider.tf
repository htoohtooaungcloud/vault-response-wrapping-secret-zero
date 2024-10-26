terraform {
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "4.4.0"
    }
  }
  cloud {

    organization = "hc-multi-project"

    workspaces {
      name = "terraform-jenkins-pipeline"
    }
  }
}