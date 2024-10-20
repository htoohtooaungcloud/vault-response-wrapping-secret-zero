resource "aws_kms_key" "vault_kms_auto_unseal" {
  description              = "Vault AWS KMS Auto-Unseal Key"
  deletion_window_in_days  = 30
  key_usage                = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  depends_on               = [aws_iam_user.vault_aws_kms_iam_user]

  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "key-aws-kms-auto-unseal-1"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow administration of the key"
        Effect = "Allow"
        Principal = {
          AWS = "${aws_iam_user.vault_aws_kms_iam_user.arn}" # Corrected IAM user reference
        }
        Action = [
          "kms:ReplicateKey",
          "kms:Create*",
          "kms:Describe*",
          "kms:Enable*",
          "kms:List*",
          "kms:Put*",
          "kms:Update*",
          "kms:Revoke*",
          "kms:Disable*",
          "kms:Get*",
          "kms:Delete*",
          "kms:ScheduleKeyDeletion",
          "kms:CancelKeyDeletion"
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow use of the key"
        Effect = "Allow"
        Principal = {
          AWS = "${aws_iam_user.vault_aws_kms_iam_user.arn}" # Corrected reference to user ARN
        }
        Action = [
          "kms:DescribeKey",
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey",
          "kms:GenerateDataKeyWithoutPlaintext"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_kms_alias" "vault_kms_alias" {
  name          = "alias/vault-aws-kms-key-1"
  target_key_id = aws_kms_key.vault_kms_auto_unseal.key_id
}