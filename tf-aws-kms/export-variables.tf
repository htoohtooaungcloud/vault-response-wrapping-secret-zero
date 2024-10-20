resource "null_resource" "access_key" {
  provisioner "local-exec" {
    command = "echo \"AWS_ACCESS_KEY_ID=${aws_iam_access_key.aws_kms_iam_user_access_key.id}\" >> ../vault_kms_auto_unseal.env"
  }

  provisioner "local-exec" {
    command = "echo \"AWS_SECRET_ACCESS_KEY=${aws_iam_access_key.aws_kms_iam_user_access_key.secret}\" >> ../vault_kms_auto_unseal.env"
  }

  provisioner "local-exec" {
    command = "echo \"AWS_REGION=${data.aws_region.current.name}\" >> ../vault_kms_auto_unseal.env"
  }

  provisioner "local-exec" {
    command = "echo \"VAULT_AWSKMS_SEAL_KEY_ID=${aws_kms_key.vault_kms_auto_unseal.key_id}\" >> ../vault_kms_auto_unseal.env"
  }
  depends_on = [aws_iam_user.vault_aws_kms_iam_user]
}