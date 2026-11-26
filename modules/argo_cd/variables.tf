# Variables for the Argo CD module

# Basic parameters
variable "release_name" {
  description = "Helm release name for Argo CD"
  type        = string
  default     = "argocd"

  validation {
    condition     = can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", var.release_name))
    error_message = "Release name may only contain lowercase letters, digits and hyphens."
  }
}

variable "namespace" {
  description = "Kubernetes namespace for Argo CD"
  type        = string
  default     = "argocd"

  validation {
    condition     = can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", var.namespace))
    error_message = "Namespace may only contain lowercase letters, digits and hyphens."
  }
}

# Helm settings
variable "helm_repository" {
  description = "Helm repository URL for the Argo CD chart"
  type        = string
  default     = "https://argoproj.github.io/argo-helm"
}

variable "helm_chart" {
  description = "Helm chart name for Argo CD"
  type        = string
  default     = "argo-cd"
}

variable "helm_chart_version" {
  description = "Helm chart version for Argo CD"
  type        = string
  default     = "5.51.6"
}

variable "helm_timeout" {
  description = "Timeout for Helm operations (seconds)"
  type        = number
  default     = 600

  validation {
    condition     = var.helm_timeout >= 300 && var.helm_timeout <= 1800
    error_message = "Helm timeout must be between 300 and 1800 seconds."
  }
}

# Argo CD configuration
variable "admin_password" {
  description = "Argo CD admin password"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.admin_password) >= 8
    error_message = "Admin password must be at least 8 characters long."
  }
}

variable "argocd_config_files" {
  description = "Extra configuration files for Argo CD"
  type        = map(string)
  default     = {}
}

variable "additional_values" {
  description = "Extra Helm values in YAML format"
  type        = string
  default     = ""
}

# Resources for the Controller
variable "controller_resources" {
  description = "Resources for the Argo CD Application Controller"
  type = object({
    requests = object({
      cpu    = string
      memory = string
    })
    limits = object({
      cpu    = string
      memory = string
    })
  })
  default = {
    requests = {
      cpu    = "250m"
      memory = "1Gi"
    }
    limits = {
      cpu    = "500m"
      memory = "2Gi"
    }
  }
}

# Resources for the Server
variable "server_resources" {
  description = "Resources for the Argo CD Server"
  type = object({
    requests = object({
      cpu    = string
      memory = string
    })
    limits = object({
      cpu    = string
      memory = string
    })
  })
  default = {
    requests = {
      cpu    = "100m"
      memory = "128Mi"
    }
    limits = {
      cpu    = "500m"
      memory = "512Mi"
    }
  }
}

# Resources for the Repo Server
variable "repo_server_resources" {
  description = "Resources for the Argo CD Repo Server"
  type = object({
    requests = object({
      cpu    = string
      memory = string
    })
    limits = object({
      cpu    = string
      memory = string
    })
  })
  default = {
    requests = {
      cpu    = "100m"
      memory = "256Mi"
    }
    limits = {
      cpu    = "1"
      memory = "1Gi"
    }
  }
}

# High Availability
variable "enable_ha" {
  description = "Enable High Availability mode"
  type        = bool
  default     = false
}

variable "controller_replicas" {
  description = "Number of Application Controller replicas (HA mode)"
  type        = number
  default     = 1

  validation {
    condition     = var.controller_replicas >= 1 && var.controller_replicas <= 5
    error_message = "Controller replicas must be between 1 and 5."
  }
}

variable "server_replicas" {
  description = "Number of Server replicas (HA mode)"
  type        = number
  default     = 2

  validation {
    condition     = var.server_replicas >= 1 && var.server_replicas <= 10
    error_message = "Server replicas must be between 1 and 10."
  }
}

variable "repo_server_replicas" {
  description = "Number of Repo Server replicas (HA mode)"
  type        = number
  default     = 2

  validation {
    condition     = var.repo_server_replicas >= 1 && var.repo_server_replicas <= 10
    error_message = "Repo Server replicas must be between 1 and 10."
  }
}

# Network settings
variable "service_type" {
  description = "Kubernetes service type for Argo CD"
  type        = string
  default     = "ClusterIP"

  validation {
    condition     = contains(["ClusterIP", "NodePort", "LoadBalancer"], var.service_type)
    error_message = "Service type must be ClusterIP, NodePort or LoadBalancer."
  }
}

variable "create_load_balancer_service" {
  description = "Create an extra LoadBalancer service"
  type        = bool
  default     = false
}

variable "load_balancer_annotations" {
  description = "Annotations for the LoadBalancer service"
  type        = map(string)
  default = {
    "service.beta.kubernetes.io/aws-load-balancer-type"   = "nlb"
    "service.beta.kubernetes.io/aws-load-balancer-scheme" = "internet-facing"
  }
}

variable "load_balancer_source_ranges" {
  description = "CIDR blocks allowed to reach the LoadBalancer"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# Ingress settings
variable "ingress_enabled" {
  description = "Enable Ingress for Argo CD"
  type        = bool
  default     = true
}

variable "create_custom_ingress" {
  description = "Create a custom Ingress resource"
  type        = bool
  default     = false
}

variable "ingress_hostname" {
  description = "Hostname for the Argo CD Ingress"
  type        = string
  default     = "argocd.local"
}

variable "ingress_class_name" {
  description = "Ingress class name"
  type        = string
  default     = "nginx"
}

variable "ingress_annotations" {
  description = "Extra annotations for the Ingress"
  type        = map(string)
  default = {
    "cert-manager.io/cluster-issuer" = "letsencrypt-prod"
  }
}

variable "ingress_tls_enabled" {
  description = "Enable TLS for the Ingress"
  type        = bool
  default     = true
}

variable "ingress_tls_secret_name" {
  description = "Name of the secret with the TLS certificate"
  type        = string
  default     = "argocd-tls"
}

# Auto Scaling
variable "enable_hpa" {
  description = "Enable HorizontalPodAutoscaler"
  type        = bool
  default     = false
}

variable "hpa_min_replicas" {
  description = "Minimum number of replicas for HPA"
  type        = number
  default     = 2

  validation {
    condition     = var.hpa_min_replicas >= 1
    error_message = "Minimum replicas must be at least 1."
  }
}

variable "hpa_max_replicas" {
  description = "Maximum number of replicas for HPA"
  type        = number
  default     = 5

  validation {
    condition     = var.hpa_max_replicas >= 1
    error_message = "Maximum replicas must be at least 1."
  }
}

variable "hpa_target_cpu_utilization" {
  description = "Target CPU utilization for HPA (%)"
  type        = number
  default     = 70

  validation {
    condition     = var.hpa_target_cpu_utilization >= 1 && var.hpa_target_cpu_utilization <= 100
    error_message = "Target CPU utilization must be between 1% and 100%."
  }
}

variable "hpa_target_memory_utilization" {
  description = "Target memory utilization for HPA (%)"
  type        = number
  default     = 80

  validation {
    condition     = var.hpa_target_memory_utilization >= 1 && var.hpa_target_memory_utilization <= 100
    error_message = "Target memory utilization must be between 1% and 100%."
  }
}

# Features
variable "enable_metrics" {
  description = "Enable Prometheus metrics"
  type        = bool
  default     = true
}

variable "enable_notifications" {
  description = "Enable Argo CD Notifications"
  type        = bool
  default     = true
}

variable "enable_applicationset" {
  description = "Enable ApplicationSet Controller"
  type        = bool
  default     = true
}

variable "enable_dex" {
  description = "Enable Dex for OIDC authentication"
  type        = bool
  default     = false
}

# Git repository settings
# Demo Application
variable "create_demo_application" {
  description = "Create a demo Application"
  type        = bool
  default     = false
}

variable "demo_app_repo_url" {
  description = "Repository URL for the demo app"
  type        = string
  default     = "https://github.com/argoproj/argocd-example-apps.git"
}

variable "demo_app_target_revision" {
  description = "Target revision for the demo app"
  type        = string
  default     = "HEAD"
}

variable "demo_app_path" {
  description = "Path in the repository for the demo app"
  type        = string
  default     = "guestbook"
}

variable "demo_app_namespace" {
  description = "Namespace for the demo app"
  type        = string
  default     = "default"
}

# AppProject
variable "create_app_project" {
  description = "Create an AppProject"
  type        = bool
  default     = false
}

variable "app_project_name" {
  description = "AppProject name"
  type        = string
  default     = "default"
}

variable "app_project_source_repos" {
  description = "Allowed source repositories for the AppProject"
  type        = list(string)
  default     = ["*"]
}

variable "app_project_admin_groups" {
  description = "OIDC groups with admin rights"
  type        = list(string)
  default     = []
}

variable "app_project_developer_groups" {
  description = "OIDC groups with developer rights"
  type        = list(string)
  default     = []
}

# RBAC
# Security
# Monitoring
variable "enable_prometheus_monitoring" {
  description = "Enable Prometheus monitoring"
  type        = bool
  default     = true
}

# Backup
# Tags
# Extra settings
# Webhook settings
variable "enable_webhooks" {
  description = "Enable webhook support"
  type        = bool
  default     = true
}

# Sync settings