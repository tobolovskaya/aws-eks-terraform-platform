# KMS key for envelope encryption of Kubernetes secrets.
# Created only when encryption is enabled and no existing key ARN is passed in.
locals {
  create_kms_key = var.cluster_encryption_config_kms_key_id == ""
}

resource "aws_kms_key" "eks_secrets" {
  count = local.create_kms_key ? 1 : 0

  description             = "EKS secrets encryption for ${var.cluster_name}"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowAccountAdministration"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      }
    ]
  })

  tags = var.tags
}

resource "aws_kms_alias" "eks_secrets" {
  count = local.create_kms_key ? 1 : 0

  name          = "alias/${var.cluster_name}-eks-secrets"
  target_key_id = aws_kms_key.eks_secrets[0].key_id
}
