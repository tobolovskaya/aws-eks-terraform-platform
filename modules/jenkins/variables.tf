# Variables for the Jenkins module

# Basic parameters
variable "release_name" {
  description = "Helm release name for Jenkins"
  type        = string
  default     = "jenkins"

  validation {
    condition     = can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", var.release_name))
    error_message = "Release name may only contain lowercase letters, digits and hyphens."
  }
}

variable "namespace" {
  description = "Kubernetes namespace for Jenkins"
  type        = string
  default     = "jenkins"

  validation {
    condition     = can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", var.namespace))
    error_message = "Namespace may only contain lowercase letters, digits and hyphens."
  }
}

# Helm settings
variable "helm_repository" {
  description = "Helm repository URL for the Jenkins chart"
  type        = string
  default     = "https://charts.jenkins.io"
}

variable "helm_chart" {
  description = "Helm chart name for Jenkins"
  type        = string
  default     = "jenkins"
}

variable "helm_chart_version" {
  description = "Helm chart version for Jenkins"
  type        = string
  default     = "4.8.3"
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

# Jenkins configuration
variable "admin_user" {
  description = "Jenkins admin username"
  type        = string
  default     = "admin"
}

variable "admin_password" {
  description = "Jenkins admin password"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.admin_password) >= 8
    error_message = "Admin password must be at least 8 characters long."
  }
}

variable "jenkins_config_files" {
  description = "Extra configuration files for Jenkins"
  type        = map(string)
  default     = {}
}

variable "additional_values" {
  description = "Extra Helm values in YAML format"
  type        = string
  default     = ""
}

# Resources
variable "resources" {
  description = "Resources for the Jenkins controller"
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
      cpu    = "500m"
      memory = "1Gi"
    }
    limits = {
      cpu    = "2"
      memory = "4Gi"
    }
  }
}

# Storage
variable "persistence_enabled" {
  description = "Enable persistent storage for Jenkins"
  type        = bool
  default     = true
}

variable "storage_size" {
  description = "Storage size for Jenkins home"
  type        = string
  default     = "20Gi"
}

variable "storage_class" {
  description = "Storage class for the Jenkins PVC"
  type        = string
  default     = "gp3"
}

variable "create_pvc" {
  description = "Create a PVC for Jenkins (if false, it is provisioned dynamically)"
  type        = bool
  default     = true
}

# Network settings
variable "service_type" {
  description = "Kubernetes service type for Jenkins"
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
  description = "Enable Ingress for Jenkins"
  type        = bool
  default     = true
}

variable "create_custom_ingress" {
  description = "Create a custom Ingress resource"
  type        = bool
  default     = false
}

variable "ingress_hostname" {
  description = "Hostname for the Jenkins Ingress"
  type        = string
  default     = "jenkins.local"
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
  default     = "jenkins-tls"
}

# Plugins
variable "install_plugins" {
  description = "List of plugins to install in Jenkins"
  type        = list(string)
  default = [
    "kubernetes:4029.v5712230ccb_f8",
    "workflow-aggregator:596.v8c21c963d92d",
    "git:5.0.0",
    "configuration-as-code:1670.v564dc8b_982d0",
    "blueocean:1.27.2",
    "pipeline-stage-view:2.25",
    "docker-workflow:563.vd5d2e5c4007f",
    "aws-credentials:191.vcb_f183ce58b_9",
    "pipeline-aws:1.43",
    "amazon-ecr:1.7.3",
    "slack:631.v40deea_40323b",
    "github:1.37.3.1",
    "pipeline-github-lib:42.v0739460cda_c4",
    "sonar:2.15",
    "build-timeout:1.30",
    "timestamper:1.25",
    "ws-cleanup:0.45",
    "ant:475.vf34069fef73c",
    "gradle:2.8.2",
    "nodejs:1.6.1",
    "maven-plugin:3.22"
  ]
}

# AWS integration
variable "aws_region" {
  description = "AWS region for the integration"
  type        = string
  default     = ""
}

variable "ecr_registry_url" {
  description = "ECR registry URL for Docker builds"
  type        = string
  default     = ""
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
  default     = 1

  validation {
    condition     = var.hpa_min_replicas >= 1
    error_message = "Minimum replicas must be at least 1."
  }
}

variable "hpa_max_replicas" {
  description = "Maximum number of replicas for HPA"
  type        = number
  default     = 3

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

# Security
# Monitoring
variable "enable_prometheus_monitoring" {
  description = "Enable Prometheus monitoring"
  type        = bool
  default     = true
}

# Backup
variable "enable_backup" {
  description = "Enable automatic backups"
  type        = bool
  default     = false
}

variable "backup_schedule" {
  description = "Cron schedule for backups"
  type        = string
  default     = "0 2 * * *"
}

# Tags
variable "tags" {
  description = "Tags for resources"
  type        = map(string)
  default = {
    ManagedBy = "terraform"
    Module    = "jenkins"
  }
}

# Extra settings
variable "java_opts" {
  description = "Extra Java options for Jenkins"
  type        = string
  default     = "-Xmx2g -Xms1g"
}

# IRSA for Jenkins build agents
variable "oidc_provider_arn" {
  description = "ARN of the EKS cluster OIDC provider (module.eks.oidc_provider_arn)"
  type        = string
}

variable "oidc_provider_url" {
  description = "OIDC issuer URL of the EKS cluster (module.eks.cluster_oidc_issuer_url)"
  type        = string
}

variable "ecr_repository_arn" {
  description = "ARN of the only ECR repository Jenkins agents may push to"
  type        = string
}

variable "agent_service_account_name" {
  description = "Kubernetes service account used by Jenkins build agents"
  type        = string
  default     = "jenkins-agent"
}
