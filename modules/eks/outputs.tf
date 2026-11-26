# EKS cluster outputs

# Basic cluster information
output "cluster_id" {
  description = "EKS cluster ID"
  value       = aws_eks_cluster.main.id
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.main.name
}

output "cluster_arn" {
  description = "EKS cluster ARN"
  value       = aws_eks_cluster.main.arn
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_version" {
  description = "Cluster Kubernetes version"
  value       = aws_eks_cluster.main.version
}

output "cluster_platform_version" {
  description = "EKS platform version"
  value       = aws_eks_cluster.main.platform_version
}

output "cluster_status" {
  description = "EKS cluster status"
  value       = aws_eks_cluster.main.status
}

# Cluster certificate
output "cluster_certificate_authority_data" {
  description = "Base64-encoded certificate data to connect to the cluster"
  value       = aws_eks_cluster.main.certificate_authority[0].data
}

# OIDC information
output "cluster_oidc_issuer_url" {
  description = "OIDC identity provider URL for the cluster"
  value       = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

output "oidc_provider_arn" {
  description = "ARN OIDC Identity Provider"
  value       = aws_iam_openid_connect_provider.cluster.arn
}

# Security Groups
output "cluster_security_group_id" {
  description = "Cluster security group ID"
  value       = aws_security_group.cluster.id
}

output "node_security_group_id" {
  description = "Security group ID for node groups"
  value       = aws_security_group.node_group.id
}

# IAM roles
output "cluster_iam_role_arn" {
  description = "Cluster IAM role ARN"
  value       = aws_iam_role.cluster.arn
}

output "node_group_iam_role_arn" {
  description = "Node group IAM role ARN"
  value       = aws_iam_role.node_group.arn
}

output "ebs_csi_driver_iam_role_arn" {
  description = "EBS CSI Driver IAM role ARN"
  value       = var.enable_ebs_csi_driver ? aws_iam_role.ebs_csi_driver[0].arn : null
}

# Node groups information
output "node_groups" {
  description = "Node group information"
  value = {
    for ng in aws_eks_node_group.main : ng.node_group_name => {
      arn            = ng.arn
      status         = ng.status
      capacity_type  = ng.capacity_type
      instance_types = ng.instance_types
      ami_type       = ng.ami_type
      node_role_arn  = ng.node_role_arn
      subnet_ids     = ng.subnet_ids
      scaling_config = ng.scaling_config
      labels         = ng.labels
    }
  }
}

# Add-ons information
output "ebs_csi_addon_arn" {
  description = "ARN EBS CSI Driver addon"
  value       = var.enable_ebs_csi_driver ? aws_eks_addon.ebs_csi_driver[0].arn : null
}

output "ebs_csi_addon_status" {
  description = "EBS CSI Driver add-on status"
  value       = var.enable_ebs_csi_driver ? aws_eks_addon.ebs_csi_driver[0].addon_version : null
}

# Connection commands
output "kubectl_config_command" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${data.aws_region.current.name} --name ${aws_eks_cluster.main.name}"
}

output "kubeconfig" {
  description = "kubeconfig to connect to the cluster"
  value = {
    apiVersion = "v1"
    kind       = "Config"
    clusters = [{
      name = aws_eks_cluster.main.name
      cluster = {
        server                     = aws_eks_cluster.main.endpoint
        certificate-authority-data = aws_eks_cluster.main.certificate_authority[0].data
      }
    }]
    contexts = [{
      name = aws_eks_cluster.main.name
      context = {
        cluster = aws_eks_cluster.main.name
        user    = aws_eks_cluster.main.name
      }
    }]
    current-context = aws_eks_cluster.main.name
    users = [{
      name = aws_eks_cluster.main.name
      user = {
        exec = {
          apiVersion = "client.authentication.k8s.io/v1beta1"
          command    = "aws"
          args = [
            "eks",
            "get-token",
            "--cluster-name",
            aws_eks_cluster.main.name,
            "--region",
            data.aws_region.current.name
          ]
        }
      }
    }]
  }
  sensitive = true
}

# CloudWatch Log Group
output "cloudwatch_log_group_name" {
  description = "CloudWatch log group name for the cluster"
  value       = "/aws/eks/${aws_eks_cluster.main.name}/cluster"
}

# Network information
output "vpc_id" {
  description = "Cluster VPC ID"
  value       = var.vpc_id
}

output "subnet_ids" {
  description = "Cluster subnet IDs"
  value       = var.subnet_ids
}

# Useful information for CI/CD
output "cluster_info" {
  description = "General cluster information for use in CI/CD"
  value = {
    name                  = aws_eks_cluster.main.name
    endpoint              = aws_eks_cluster.main.endpoint
    region                = data.aws_region.current.name
    certificate_authority = aws_eks_cluster.main.certificate_authority[0].data
    oidc_issuer_url       = aws_eks_cluster.main.identity[0].oidc[0].issuer
  }
  sensitive = true
}

# Helm values for different charts
output "helm_values" {
  description = "Values for use in Helm charts"
  value = {
    cluster = {
      name     = aws_eks_cluster.main.name
      endpoint = aws_eks_cluster.main.endpoint
      region   = data.aws_region.current.name
    }
    serviceAccount = {
      annotations = {
        "eks.amazonaws.com/role-arn" = aws_iam_role.node_group.arn
      }
    }
  }
}