variable "aws_default_region" {
  description = "AWS Default Region"
  type        = string
  default     = "ap-southeast-1"
}

variable "user_name" {
  description = "Vault AWS IAM User Name"
  type        = string
  default     = "vault-aws-iam-kms-user"
}

