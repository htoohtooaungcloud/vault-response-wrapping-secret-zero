resource "aws_iam_user" "vault_aws_kms_iam_user" {
  name = var.user_name
  path = "/"

  tags = {
    tag-key = "-aws-kms-auto-unseal"
  }
}

resource "aws_iam_access_key" "aws_kms_iam_user_access_key" {
  user = aws_iam_user.vault_aws_kms_iam_user.name
}

data "aws_iam_policy_document" "aws_kms_inline_pol" {
  statement {
    sid    = "KMSAutoUnseal"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:Describe*",
      "iam:ListUsers"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_user_policy" "aws_kms_user_pol" {
  name   = "KMSAutoUnsealPolicy"
  user   = aws_iam_user.vault_aws_kms_iam_user.name
  policy = data.aws_iam_policy_document.aws_kms_inline_pol.json
}