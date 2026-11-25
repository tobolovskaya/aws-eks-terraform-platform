# IRSA: own IAM role for Jenkins build agents.
# Only pods running as the agent service account can assume it,
# and it can only push to one ECR repository (least privilege).

locals {
  oidc_issuer = replace(var.oidc_provider_url, "https://", "")
}

data "aws_iam_policy_document" "jenkins_agent_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_issuer}:sub"
      values   = ["system:serviceaccount:${var.namespace}:${var.agent_service_account_name}"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_issuer}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "jenkins_agent" {
  name               = "${var.release_name}-agent-ecr-push"
  assume_role_policy = data.aws_iam_policy_document.jenkins_agent_assume.json
  tags               = var.tags
}

data "aws_iam_policy_document" "jenkins_agent_ecr_push" {
  # GetAuthorizationToken does not support resource-level permissions
  statement {
    sid       = "EcrLogin"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid    = "EcrPushToOneRepository"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
    ]
    resources = [var.ecr_repository_arn]
  }
}

resource "aws_iam_role_policy" "jenkins_agent_ecr_push" {
  name   = "ecr-push"
  role   = aws_iam_role.jenkins_agent.id
  policy = data.aws_iam_policy_document.jenkins_agent_ecr_push.json
}
