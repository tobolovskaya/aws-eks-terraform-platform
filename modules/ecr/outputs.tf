# ECR outputs

# Basic repository information
output "repository_arn" {
  description = "ECR repository ARN"
  value       = aws_ecr_repository.main.arn
}

output "repository_name" {
  description = "ECR repository name"
  value       = aws_ecr_repository.main.name
}

output "repository_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.main.repository_url
}

output "registry_id" {
  description = "ECR registry ID"
  value       = aws_ecr_repository.main.registry_id
}

# Information for Docker commands
output "docker_push_commands" {
  description = "Commands to push an image to ECR"
  value = [
    "aws ecr get-login-password --region ${data.aws_region.current.name} | docker login --username AWS --password-stdin ${aws_ecr_repository.main.repository_url}",
    "docker build -t ${aws_ecr_repository.main.name} .",
    "docker tag ${aws_ecr_repository.main.name}:latest ${aws_ecr_repository.main.repository_url}:latest",
    "docker push ${aws_ecr_repository.main.repository_url}:latest"
  ]
}

output "docker_pull_command" {
  description = "Command to pull an image from ECR"
  value       = "docker pull ${aws_ecr_repository.main.repository_url}:latest"
}

# Policy information
output "lifecycle_policy_text" {
  description = "Lifecycle policy text"
  value       = var.enable_lifecycle_policy ? aws_ecr_lifecycle_policy.main[0].policy : null
}

output "repository_policy_text" {
  description = "Repository policy text"
  value       = var.enable_cross_account_access ? aws_ecr_repository_policy.main[0].policy : null
}

# Security settings
output "image_scanning_enabled" {
  description = "Whether image scanning is enabled"
  value       = var.scan_on_push
}

output "encryption_type" {
  description = "Repository encryption type"
  value       = var.encryption_type
}

output "image_tag_mutability" {
  description = "Tag mutability setting"
  value       = var.image_tag_mutability
}

# Replication information
output "replication_destinations" {
  description = "Replication regions"
  value       = var.replication_regions
}

# Useful information for CI/CD
output "ecr_login_command" {
  description = "Command to log in to ECR"
  value       = "aws ecr get-login-password --region ${data.aws_region.current.name} | docker login --username AWS --password-stdin ${aws_ecr_repository.main.repository_url}"
}

output "image_uri_template" {
  description = "URI template for images"
  value       = "${aws_ecr_repository.main.repository_url}:TAG"
}

# Current region
data "aws_region" "current" {}

# Repository statistics
output "repository_creation_time" {
  description = "Repository creation time"
  value       = aws_ecr_repository.main.id
}

# Information for Kubernetes
output "kubernetes_image_pull_secret" {
  description = "Command to create a Kubernetes secret for ECR"
  value       = "kubectl create secret docker-registry ecr-secret --docker-server=${aws_ecr_repository.main.repository_url} --docker-username=AWS --docker-password=$(aws ecr get-login-password --region ${data.aws_region.current.name})"
}

# Helm values for use in charts
output "helm_values" {
  description = "Values for use in Helm charts"
  value = {
    image = {
      repository = aws_ecr_repository.main.repository_url
      tag        = "latest"
      pullPolicy = "Always"
    }
  }
}