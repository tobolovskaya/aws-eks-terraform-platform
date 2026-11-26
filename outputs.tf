# Common resource outputs

# VPC outputs
output "vpc_id" {
  description = "ID VPC"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

# RDS outputs
output "database_endpoint" {
  description = "Database endpoint"
  value       = module.rds.endpoint
}

output "database_port" {
  description = "Database port"
  value       = module.rds.port
}

output "database_name" {
  description = "Database name"
  value       = module.rds.database_name
}

output "database_username" {
  description = "Database username"
  value       = module.rds.username
  sensitive   = true
}

output "security_group_id" {
  description = "Security group ID for the database"
  value       = module.rds.security_group_id
}

output "subnet_group_name" {
  description = "DB subnet group name"
  value       = module.rds.subnet_group_name
}

output "parameter_group_name" {
  description = "Parameter group name"
  value       = module.rds.parameter_group_name
}

output "db_master_user_secret_arn" {
  description = "Secrets Manager ARN with the database master password"
  value       = module.rds.master_user_secret_arn
}

# EKS outputs
output "eks_cluster_id" {
  description = "EKS cluster ID"
  value       = module.eks.cluster_id
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "kubectl_config_command" {
  description = "Command to configure kubectl"
  value       = module.eks.kubectl_config_command
}

output "cluster_security_group_id" {
  description = "EKS cluster security group ID"
  value       = module.eks.cluster_security_group_id
}

output "node_security_group_id" {
  description = "Security group ID for EKS node groups"
  value       = module.eks.node_security_group_id
}

# ECR outputs
output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = module.ecr.repository_url
}

output "ecr_repository_arn" {
  description = "ECR repository ARN"
  value       = module.ecr.repository_arn
}

output "ecr_registry_id" {
  description = "ECR registry ID"
  value       = module.ecr.registry_id
}

output "ecr_docker_push_commands" {
  description = "Commands to push an image to ECR"
  value       = module.ecr.docker_push_commands
}

output "ecr_login_command" {
  description = "Command to log in to ECR"
  value       = module.ecr.ecr_login_command
}

# Jenkins outputs
output "jenkins_url" {
  description = "URL to access Jenkins"
  value       = module.jenkins.jenkins_url
}

output "jenkins_admin_user" {
  description = "Jenkins admin username"
  value       = module.jenkins.jenkins_admin_user
}

output "jenkins_admin_password" {
  description = "Jenkins admin password"
  value       = module.jenkins.jenkins_admin_password
  sensitive   = true
}

output "jenkins_namespace" {
  description = "Kubernetes namespace Jenkins"
  value       = module.jenkins.jenkins_namespace
}

output "kubectl_port_forward_command" {
  description = "Command to port-forward to Jenkins"
  value       = module.jenkins.kubectl_port_forward_command
}

output "jenkins_webhook_url" {
  description = "URL for GitHub/GitLab webhooks"
  value       = module.jenkins.jenkins_webhook_url
}

output "jenkins_api_url" {
  description = "URL for the Jenkins API"
  value       = module.jenkins.jenkins_api_url
}

# Argo CD outputs
output "argocd_url" {
  description = "URL to access Argo CD"
  value       = module.argocd.argocd_url
}

output "argocd_admin_password" {
  description = "Argo CD admin password"
  value       = module.argocd.argocd_admin_password
  sensitive   = true
}

output "argocd_namespace" {
  description = "Kubernetes namespace Argo CD"
  value       = module.argocd.argocd_namespace
}

output "argocd_cli_login_command" {
  description = "Command to log in with the Argo CD CLI"
  value       = module.argocd.argocd_cli_login_command
  sensitive   = true
}

output "argocd_webhook_urls" {
  description = "URLs for Git webhooks"
  value       = module.argocd.argocd_webhook_urls
}

output "argocd_api_url" {
  description = "URL for the Argo CD API"
  value       = module.argocd.argocd_api_url
}

# Monitoring outputs
output "prometheus_url" {
  description = "URL to access Prometheus"
  value       = "http://localhost:9090 (use kubectl port-forward)"
}

output "grafana_url" {
  description = "URL to access Grafana"
  value       = "http://localhost:3000 (use kubectl port-forward)"
}

output "grafana_admin_password" {
  description = "Grafana admin password"
  value       = var.grafana_admin_password
  sensitive   = true
}

# Commands to access monitoring
output "prometheus_port_forward_command" {
  description = "Command to port-forward to Prometheus"
  value       = "kubectl port-forward svc/prometheus-kube-prometheus-prometheus 9090:9090 -n monitoring"
}

output "grafana_port_forward_command" {
  description = "Command to port-forward to Grafana"
  value       = "kubectl port-forward svc/prometheus-grafana 3000:80 -n monitoring"
}