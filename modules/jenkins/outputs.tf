# Jenkins outputs

# Basic information
output "jenkins_namespace" {
  description = "Kubernetes namespace where Jenkins is installed"
  value       = kubernetes_namespace.jenkins.metadata[0].name
}

output "jenkins_release_name" {
  description = "Helm release name for Jenkins"
  value       = helm_release.jenkins.name
}

output "jenkins_chart_version" {
  description = "Jenkins Helm chart version"
  value       = helm_release.jenkins.version
}

# Access to Jenkins
output "jenkins_url" {
  description = "URL to access Jenkins"
  value = var.ingress_enabled ? (
    var.ingress_tls_enabled ?
    "https://${var.ingress_hostname}" :
    "http://${var.ingress_hostname}"
    ) : (
    var.service_type == "LoadBalancer" && var.create_load_balancer_service ?
    "http://${try(kubernetes_service.jenkins_lb[0].status[0].load_balancer[0].ingress[0].hostname, "pending")}" :
    "http://localhost:8080 (use kubectl port-forward)"
  )
}

output "jenkins_internal_url" {
  description = "Internal Jenkins URL inside the cluster"
  value       = "http://${helm_release.jenkins.name}-jenkins.${kubernetes_namespace.jenkins.metadata[0].name}.svc.cluster.local:8080"
}

# Credentials
output "jenkins_admin_user" {
  description = "Jenkins admin username"
  value       = var.admin_user
}

output "jenkins_admin_password" {
  description = "Jenkins admin password"
  value       = var.admin_password
  sensitive   = true
}

output "jenkins_admin_secret_name" {
  description = "Name of the Kubernetes secret with the admin password"
  value       = kubernetes_secret.jenkins_admin.metadata[0].name
}

# Service Account
output "jenkins_service_account_name" {
  description = "Service Account name for Jenkins"
  value       = kubernetes_service_account.jenkins.metadata[0].name
}

output "jenkins_cluster_role_name" {
  description = "Cluster Role name for Jenkins"
  value       = kubernetes_cluster_role.jenkins.metadata[0].name
}

# Storage
output "jenkins_pvc_name" {
  description = "PersistentVolumeClaim name for Jenkins"
  value       = var.create_pvc ? kubernetes_persistent_volume_claim.jenkins_home[0].metadata[0].name : null
}

output "jenkins_storage_size" {
  description = "Jenkins storage size"
  value       = var.storage_size
}

output "jenkins_storage_class" {
  description = "Storage class for Jenkins"
  value       = var.storage_class
}

# Network resources
output "jenkins_service_name" {
  description = "Name of the main Kubernetes service for Jenkins"
  value       = "${helm_release.jenkins.name}-jenkins"
}

output "jenkins_service_type" {
  description = "Kubernetes service type for Jenkins"
  value       = var.service_type
}

output "jenkins_load_balancer_service_name" {
  description = "Name of the LoadBalancer service (if created)"
  value       = var.create_load_balancer_service ? kubernetes_service.jenkins_lb[0].metadata[0].name : null
}

output "jenkins_load_balancer_hostname" {
  description = "LoadBalancer hostname (if available)"
  value = var.service_type == "LoadBalancer" && var.create_load_balancer_service ? (
    try(kubernetes_service.jenkins_lb[0].status[0].load_balancer[0].ingress[0].hostname, null)
  ) : null
}

output "jenkins_load_balancer_ip" {
  description = "LoadBalancer IP address (if available)"
  value = var.service_type == "LoadBalancer" && var.create_load_balancer_service ? (
    try(kubernetes_service.jenkins_lb[0].status[0].load_balancer[0].ingress[0].ip, null)
  ) : null
}

# Ingress
output "jenkins_ingress_name" {
  description = "Name of the Ingress resource (if created)"
  value       = var.create_custom_ingress ? kubernetes_ingress_v1.jenkins[0].metadata[0].name : null
}

output "jenkins_ingress_hostname" {
  description = "Hostname for the Ingress"
  value       = var.ingress_enabled ? var.ingress_hostname : null
}

output "jenkins_ingress_tls_secret" {
  description = "Name of the TLS secret for the Ingress"
  value       = var.ingress_tls_enabled ? var.ingress_tls_secret_name : null
}

# Auto Scaling
output "jenkins_hpa_name" {
  description = "Name of the HorizontalPodAutoscaler (if enabled)"
  value       = var.enable_hpa ? kubernetes_horizontal_pod_autoscaler_v2.jenkins[0].metadata[0].name : null
}

output "jenkins_hpa_min_replicas" {
  description = "Minimum number of HPA replicas"
  value       = var.enable_hpa ? var.hpa_min_replicas : null
}

output "jenkins_hpa_max_replicas" {
  description = "Maximum number of HPA replicas"
  value       = var.enable_hpa ? var.hpa_max_replicas : null
}

# Access commands
output "kubectl_port_forward_command" {
  description = "Command to port-forward to Jenkins"
  value       = "kubectl port-forward -n ${kubernetes_namespace.jenkins.metadata[0].name} svc/${helm_release.jenkins.name}-jenkins 8080:8080"
}

output "kubectl_get_admin_password_command" {
  description = "Command to get the admin password"
  value       = "kubectl get secret -n ${kubernetes_namespace.jenkins.metadata[0].name} ${kubernetes_secret.jenkins_admin.metadata[0].name} -o jsonpath='{.data.jenkins-admin-password}' | base64 -d"
}

output "kubectl_logs_command" {
  description = "Command to view Jenkins logs"
  value       = "kubectl logs -n ${kubernetes_namespace.jenkins.metadata[0].name} -l app.kubernetes.io/instance=${helm_release.jenkins.name} -f"
}

# Helm information
output "helm_status_command" {
  description = "Command to check the Helm release status"
  value       = "helm status ${helm_release.jenkins.name} -n ${kubernetes_namespace.jenkins.metadata[0].name}"
}

output "helm_values_command" {
  description = "Command to view the Helm values"
  value       = "helm get values ${helm_release.jenkins.name} -n ${kubernetes_namespace.jenkins.metadata[0].name}"
}

# Configuration
output "jenkins_java_opts" {
  description = "Java options for Jenkins"
  value       = var.java_opts
}

output "jenkins_plugins_list" {
  description = "List of installed plugins"
  value       = var.install_plugins
}

# Monitoring
output "jenkins_prometheus_enabled" {
  description = "Whether Prometheus monitoring is enabled"
  value       = var.enable_prometheus_monitoring
}

output "jenkins_prometheus_endpoint" {
  description = "Endpoint for Prometheus metrics"
  value       = var.enable_prometheus_monitoring ? "${helm_release.jenkins.name}-jenkins.${kubernetes_namespace.jenkins.metadata[0].name}.svc.cluster.local:8080/prometheus" : null
}

# Backup
output "jenkins_backup_enabled" {
  description = "Whether automatic backups are enabled"
  value       = var.enable_backup
}

output "jenkins_backup_schedule" {
  description = "Backup schedule"
  value       = var.enable_backup ? var.backup_schedule : null
}

# AWS integration
output "jenkins_aws_region" {
  description = "AWS region for the integration"
  value       = var.aws_region != "" ? var.aws_region : null
}

output "jenkins_ecr_registry_url" {
  description = "URL ECR registry"
  value       = var.ecr_registry_url != "" ? var.ecr_registry_url : null
}

# Deployment status
output "jenkins_deployment_status" {
  description = "Jenkins deployment status"
  value       = helm_release.jenkins.status
}

output "jenkins_chart_repository" {
  description = "Helm repository for the Jenkins chart"
  value       = var.helm_repository
}

# Useful information for CI/CD
output "jenkins_webhook_url" {
  description = "URL for GitHub/GitLab webhooks"
  value = var.ingress_enabled ? (
    var.ingress_tls_enabled ?
    "https://${var.ingress_hostname}/github-webhook/" :
    "http://${var.ingress_hostname}/github-webhook/"
  ) : null
}

output "jenkins_api_url" {
  description = "URL for the Jenkins API"
  value = var.ingress_enabled ? (
    var.ingress_tls_enabled ?
    "https://${var.ingress_hostname}/api/" :
    "http://${var.ingress_hostname}/api/"
  ) : null
}

# Troubleshooting commands
output "troubleshooting_commands" {
  description = "Useful commands for diagnostics"
  value = {
    check_pods    = "kubectl get pods -n ${kubernetes_namespace.jenkins.metadata[0].name} -l app.kubernetes.io/instance=${helm_release.jenkins.name}"
    describe_pod  = "kubectl describe pod -n ${kubernetes_namespace.jenkins.metadata[0].name} -l app.kubernetes.io/instance=${helm_release.jenkins.name}"
    check_pvc     = var.create_pvc ? "kubectl get pvc -n ${kubernetes_namespace.jenkins.metadata[0].name} ${kubernetes_persistent_volume_claim.jenkins_home[0].metadata[0].name}" : null
    check_service = "kubectl get svc -n ${kubernetes_namespace.jenkins.metadata[0].name} ${helm_release.jenkins.name}-jenkins"
    check_ingress = var.ingress_enabled ? "kubectl get ingress -n ${kubernetes_namespace.jenkins.metadata[0].name}" : null
    helm_history  = "helm history ${helm_release.jenkins.name} -n ${kubernetes_namespace.jenkins.metadata[0].name}"
  }
}
output "agent_role_arn" {
  description = "IAM role (IRSA) for Jenkins build agents"
  value       = aws_iam_role.jenkins_agent.arn
}
