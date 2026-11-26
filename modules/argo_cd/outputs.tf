# Argo CD outputs

# Basic information
output "argocd_namespace" {
  description = "Kubernetes namespace where Argo CD is installed"
  value       = kubernetes_namespace.argocd.metadata[0].name
}

output "argocd_release_name" {
  description = "Helm release name for Argo CD"
  value       = helm_release.argocd.name
}

output "argocd_chart_version" {
  description = "Argo CD Helm chart version"
  value       = helm_release.argocd.version
}

# Access to Argo CD
output "argocd_url" {
  description = "URL to access Argo CD"
  value = var.ingress_enabled ? (
    var.ingress_tls_enabled ?
    "https://${var.ingress_hostname}" :
    "http://${var.ingress_hostname}"
    ) : (
    var.service_type == "LoadBalancer" && var.create_load_balancer_service ?
    "http://${try(kubernetes_service.argocd_lb[0].status[0].load_balancer[0].ingress[0].hostname, "pending")}" :
    "http://localhost:8080 (use kubectl port-forward)"
  )
}

output "argocd_internal_url" {
  description = "Internal Argo CD URL inside the cluster"
  value       = "http://${helm_release.argocd.name}-argocd-server.${kubernetes_namespace.argocd.metadata[0].name}.svc.cluster.local"
}

# Credentials
output "argocd_admin_password" {
  description = "Argo CD admin password"
  value       = var.admin_password
  sensitive   = true
}

output "argocd_admin_secret_name" {
  description = "Name of the Kubernetes secret with the admin password"
  value       = kubernetes_secret.argocd_admin.metadata[0].name
}

# Service Account
output "argocd_service_account_name" {
  description = "Service Account name for Argo CD"
  value       = kubernetes_service_account.argocd.metadata[0].name
}

output "argocd_cluster_role_name" {
  description = "Cluster Role name for Argo CD"
  value       = kubernetes_cluster_role.argocd.metadata[0].name
}

# Network resources
output "argocd_service_name" {
  description = "Name of the main Kubernetes service for Argo CD"
  value       = "${helm_release.argocd.name}-argocd-server"
}

output "argocd_service_type" {
  description = "Kubernetes service type for Argo CD"
  value       = var.service_type
}

output "argocd_load_balancer_service_name" {
  description = "Name of the LoadBalancer service (if created)"
  value       = var.create_load_balancer_service ? kubernetes_service.argocd_lb[0].metadata[0].name : null
}

output "argocd_load_balancer_hostname" {
  description = "LoadBalancer hostname (if available)"
  value = var.service_type == "LoadBalancer" && var.create_load_balancer_service ? (
    try(kubernetes_service.argocd_lb[0].status[0].load_balancer[0].ingress[0].hostname, null)
  ) : null
}

output "argocd_load_balancer_ip" {
  description = "LoadBalancer IP address (if available)"
  value = var.service_type == "LoadBalancer" && var.create_load_balancer_service ? (
    try(kubernetes_service.argocd_lb[0].status[0].load_balancer[0].ingress[0].ip, null)
  ) : null
}

# Ingress
output "argocd_ingress_name" {
  description = "Name of the Ingress resource (if created)"
  value       = var.create_custom_ingress ? kubernetes_ingress_v1.argocd[0].metadata[0].name : null
}

output "argocd_ingress_hostname" {
  description = "Hostname for the Ingress"
  value       = var.ingress_enabled ? var.ingress_hostname : null
}

output "argocd_ingress_tls_secret" {
  description = "Name of the TLS secret for the Ingress"
  value       = var.ingress_tls_enabled ? var.ingress_tls_secret_name : null
}

# Auto Scaling
output "argocd_hpa_name" {
  description = "Name of the HorizontalPodAutoscaler (if enabled)"
  value       = var.enable_hpa ? kubernetes_horizontal_pod_autoscaler_v2.argocd_server[0].metadata[0].name : null
}

output "argocd_hpa_min_replicas" {
  description = "Minimum number of HPA replicas"
  value       = var.enable_hpa ? var.hpa_min_replicas : null
}

output "argocd_hpa_max_replicas" {
  description = "Maximum number of HPA replicas"
  value       = var.enable_hpa ? var.hpa_max_replicas : null
}

# Access commands
output "kubectl_port_forward_command" {
  description = "Command to port-forward to Argo CD"
  value       = "kubectl port-forward -n ${kubernetes_namespace.argocd.metadata[0].name} svc/${helm_release.argocd.name}-argocd-server 8080:80"
}

output "kubectl_get_admin_password_command" {
  description = "Command to get the admin password"
  value       = "kubectl get secret -n ${kubernetes_namespace.argocd.metadata[0].name} ${kubernetes_secret.argocd_admin.metadata[0].name} -o jsonpath='{.data.password}' | base64 -d"
}

output "kubectl_logs_command" {
  description = "Command to view Argo CD logs"
  value       = "kubectl logs -n ${kubernetes_namespace.argocd.metadata[0].name} -l app.kubernetes.io/name=argocd-server -f"
}

# Helm information
output "helm_status_command" {
  description = "Command to check the Helm release status"
  value       = "helm status ${helm_release.argocd.name} -n ${kubernetes_namespace.argocd.metadata[0].name}"
}

output "helm_values_command" {
  description = "Command to view the Helm values"
  value       = "helm get values ${helm_release.argocd.name} -n ${kubernetes_namespace.argocd.metadata[0].name}"
}

# CLI commands
output "argocd_cli_login_command" {
  description = "Command to log in with the Argo CD CLI"
  value = var.ingress_enabled ? (
    "argocd login ${var.ingress_hostname} --username admin --password '${var.admin_password}'"
    ) : (
    "argocd login localhost:8080 --username admin --password '${var.admin_password}' --insecure"
  )
  sensitive = true
}

output "argocd_cli_context_command" {
  description = "Command to set the Argo CD CLI context"
  value = var.ingress_enabled ? (
    "argocd context ${var.ingress_hostname}"
    ) : (
    "argocd context localhost:8080"
  )
}

# GitOps information
output "argocd_applications_command" {
  description = "Command to list Applications"
  value       = "argocd app list"
}

output "argocd_sync_command" {
  description = "Command to sync an application"
  value       = "argocd app sync <app-name>"
}

# Demo Application
output "demo_application_name" {
  description = "Name of the demo Application (if created)"
  value       = var.create_demo_application ? "demo-app" : null
}

output "demo_application_namespace" {
  description = "Namespace of the demo Application"
  value       = var.create_demo_application ? var.demo_app_namespace : null
}

# AppProject
output "app_project_name" {
  description = "AppProject name (if created)"
  value       = var.create_app_project ? var.app_project_name : null
}

# Monitoring
output "argocd_prometheus_enabled" {
  description = "Whether Prometheus monitoring is enabled"
  value       = var.enable_prometheus_monitoring
}

output "argocd_metrics_endpoints" {
  description = "Endpoints for Prometheus metrics"
  value = var.enable_metrics ? {
    server      = "${helm_release.argocd.name}-argocd-server-metrics.${kubernetes_namespace.argocd.metadata[0].name}.svc.cluster.local:8083"
    controller  = "${helm_release.argocd.name}-argocd-application-controller-metrics.${kubernetes_namespace.argocd.metadata[0].name}.svc.cluster.local:8082"
    repo_server = "${helm_release.argocd.name}-argocd-repo-server-metrics.${kubernetes_namespace.argocd.metadata[0].name}.svc.cluster.local:8084"
  } : null
}

# Features
output "argocd_features_enabled" {
  description = "Enabled Argo CD features"
  value = {
    high_availability = var.enable_ha
    metrics           = var.enable_metrics
    notifications     = var.enable_notifications
    applicationset    = var.enable_applicationset
    dex               = var.enable_dex
    webhooks          = var.enable_webhooks
  }
}

# Deployment status
output "argocd_deployment_status" {
  description = "Argo CD deployment status"
  value       = helm_release.argocd.status
}

output "argocd_chart_repository" {
  description = "Helm repository for the Argo CD chart"
  value       = var.helm_repository
}

# Useful information for GitOps
output "argocd_webhook_urls" {
  description = "URLs for Git webhooks"
  value = var.ingress_enabled ? {
    github = (var.ingress_tls_enabled ?
      "https://${var.ingress_hostname}/api/webhook" :
    "http://${var.ingress_hostname}/api/webhook")
    gitlab = (var.ingress_tls_enabled ?
      "https://${var.ingress_hostname}/api/webhook" :
    "http://${var.ingress_hostname}/api/webhook")
  } : null
}

output "argocd_api_url" {
  description = "URL for the Argo CD API"
  value = var.ingress_enabled ? (
    var.ingress_tls_enabled ?
    "https://${var.ingress_hostname}/api/v1/" :
    "http://${var.ingress_hostname}/api/v1/"
  ) : null
}

# Troubleshooting commands
output "troubleshooting_commands" {
  description = "Useful commands for diagnostics"
  value = {
    check_pods          = "kubectl get pods -n ${kubernetes_namespace.argocd.metadata[0].name} -l app.kubernetes.io/part-of=argocd"
    describe_server     = "kubectl describe pod -n ${kubernetes_namespace.argocd.metadata[0].name} -l app.kubernetes.io/name=argocd-server"
    describe_controller = "kubectl describe pod -n ${kubernetes_namespace.argocd.metadata[0].name} -l app.kubernetes.io/name=argocd-application-controller"
    check_service       = "kubectl get svc -n ${kubernetes_namespace.argocd.metadata[0].name} ${helm_release.argocd.name}-argocd-server"
    check_ingress       = var.ingress_enabled ? "kubectl get ingress -n ${kubernetes_namespace.argocd.metadata[0].name}" : null
    helm_history        = "helm history ${helm_release.argocd.name} -n ${kubernetes_namespace.argocd.metadata[0].name}"
    check_applications  = "kubectl get applications -n ${kubernetes_namespace.argocd.metadata[0].name}"
    check_appprojects   = "kubectl get appprojects -n ${kubernetes_namespace.argocd.metadata[0].name}"
  }
}

# Configuration for CI/CD integration
output "argocd_integration_info" {
  description = "Information for integrating with CI/CD systems"
  value = {
    server_url = var.ingress_enabled ? (
      var.ingress_tls_enabled ?
      "https://${var.ingress_hostname}" :
      "http://${var.ingress_hostname}"
    ) : "http://localhost:8080"
    namespace      = kubernetes_namespace.argocd.metadata[0].name
    admin_username = "admin"
    cli_version    = "v2.9.3"
  }
  sensitive = false
}