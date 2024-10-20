output "vault_aws_kms_iam_user" {
  description = "Vault AWS KMS IAM User ID"
  value       = aws_iam_user.vault_aws_kms_iam_user.id
}

output "vault_aws_kms_iam_user_arn" {
  description = "Vault AWS IAM User ARN"
  value       = aws_iam_user.vault_aws_kms_iam_user.arn
}

output "vault_aws_kms_iam_user_name" {
  description = "Vault AWS IAM User Name"
  value       = aws_iam_user.vault_aws_kms_iam_user.name
}

output "vault_aws_kms_key_name" {
  description = "Vault AWS KMS ARN"
  value       = aws_kms_key.vault_kms_auto_unseal.arn
}

output "vault_aws_kms_key_keyid" {
  description = "Vault AWS KMS KeyID"
  value       = aws_kms_key.vault_kms_auto_unseal.key_id
}

output "aws_kms_key_region" {
  value = data.aws_region.current.name
}
