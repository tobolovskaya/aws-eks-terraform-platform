variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-north-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["eu-north-1a", "eu-north-1b"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.20.0/24"]
}

variable "use_aurora" {
  description = "Use an Aurora cluster instead of a regular RDS instance"
  type        = bool
  default     = false
}

variable "db_engine" {
  description = "Database engine"
  type        = string
  default     = "postgres"
}

variable "db_engine_version" {
  description = "Database engine version"
  type        = string
  default     = "15.4"
}

variable "db_instance_class" {
  description = "Database instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "database_name" {
  description = "Database name"
  type        = string
  default     = "myapp"
}

variable "db_username" {
  description = "Database username"
  type        = string
  default     = "dbadmin"
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment"
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "Backup retention period (days)"
  type        = number
  default     = 7
}

variable "backup_window" {
  description = "Backup window"
  type        = string
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  description = "Maintenance window"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

# EKS variables
variable "eks_cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "my-eks-cluster"
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.35"
}

variable "node_groups" {
  description = "Node groups configuration"
  type = list(object({
    name                       = string
    instance_types             = list(string)
    ami_type                   = string
    capacity_type              = string
    desired_size               = number
    max_size                   = number
    min_size                   = number
    max_unavailable_percentage = number
    disk_size                  = number
    disk_type                  = string
    subnet_ids                 = list(string)
    labels                     = map(string)
    taints = list(object({
      key    = string
      value  = string
      effect = string
    }))
  }))
  default = [
    {
      name                       = "main"
      instance_types             = ["t3.medium"]
      ami_type                   = "AL2023_x86_64_STANDARD"
      capacity_type              = "ON_DEMAND"
      desired_size               = 2
      max_size                   = 4
      min_size                   = 1
      max_unavailable_percentage = 25
      disk_size                  = 50
      disk_type                  = "gp3"
      subnet_ids                 = []
      labels                     = {}
      taints                     = []
    }
  ]
}

variable "enable_ebs_csi_driver" {
  description = "Enable the AWS EBS CSI Driver"
  type        = bool
  default     = true
}

# ECR variables
variable "ecr_repository_name" {
  description = "ECR repository name"
  type        = string
  default     = "my-app"
}

variable "ecr_image_tag_mutability" {
  description = "Image tag mutability"
  type        = string
  default     = "IMMUTABLE"
}

variable "ecr_scan_on_push" {
  description = "Scan images on push"
  type        = bool
  default     = true
}

variable "ecr_enable_registry_scanning" {
  description = "Enable enhanced registry scanning"
  type        = bool
  default     = false
}

variable "ecr_encryption_type" {
  description = "ECR encryption type"
  type        = string
  default     = "KMS"
}

variable "ecr_kms_key" {
  description = "KMS key ARN for ECR encryption"
  type        = string
  default     = null
}

variable "ecr_enable_lifecycle_policy" {
  description = "Enable the ECR lifecycle policy"
  type        = bool
  default     = true
}

variable "ecr_max_image_count" {
  description = "Maximum number of images to keep"
  type        = number
  default     = 10
}

variable "ecr_untagged_image_days" {
  description = "Days to keep untagged images"
  type        = number
  default     = 1
}

variable "ecr_enable_cross_account_access" {
  description = "Enable cross-account access to ECR"
  type        = bool
  default     = false
}

variable "ecr_cross_account_arns" {
  description = "Account ARNs for cross-account access"
  type        = list(string)
  default     = []
}

# Jenkins variables
variable "jenkins_release_name" {
  description = "Helm release name for Jenkins"
  type        = string
  default     = "jenkins"
}

variable "jenkins_namespace" {
  description = "Kubernetes namespace for Jenkins"
  type        = string
  default     = "jenkins"
}

variable "jenkins_helm_chart_version" {
  description = "Helm chart version for Jenkins"
  type        = string
  default     = "4.8.3"
}

variable "jenkins_helm_timeout" {
  description = "Timeout for Helm operations"
  type        = number
  default     = 600
}

variable "jenkins_admin_user" {
  description = "Jenkins admin username"
  type        = string
  default     = "admin"
}

variable "jenkins_admin_password" {
  description = "Jenkins admin password"
  type        = string
  sensitive   = true
}

variable "jenkins_resources" {
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

variable "jenkins_persistence_enabled" {
  description = "Enable persistent storage for Jenkins"
  type        = bool
  default     = true
}

variable "jenkins_storage_size" {
  description = "Storage size for Jenkins"
  type        = string
  default     = "20Gi"
}

variable "jenkins_storage_class" {
  description = "Storage class for Jenkins"
  type        = string
  default     = "gp3"
}

variable "jenkins_create_pvc" {
  description = "Create a PVC for Jenkins"
  type        = bool
  default     = true
}

variable "jenkins_service_type" {
  description = "Kubernetes service type for Jenkins"
  type        = string
  default     = "ClusterIP"
}

variable "jenkins_create_load_balancer_service" {
  description = "Create a LoadBalancer service"
  type        = bool
  default     = false
}

variable "jenkins_load_balancer_annotations" {
  description = "Annotations for the LoadBalancer service"
  type        = map(string)
  default = {
    "service.beta.kubernetes.io/aws-load-balancer-type" = "nlb"
  }
}

variable "jenkins_load_balancer_source_ranges" {
  description = "CIDR blocks for the LoadBalancer"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "jenkins_ingress_enabled" {
  description = "Enable Ingress for Jenkins"
  type        = bool
  default     = true
}

variable "jenkins_create_custom_ingress" {
  description = "Create a custom Ingress"
  type        = bool
  default     = false
}

variable "jenkins_ingress_hostname" {
  description = "Hostname for the Jenkins Ingress"
  type        = string
  default     = "jenkins.local"
}

variable "jenkins_ingress_class_name" {
  description = "Ingress class name"
  type        = string
  default     = "nginx"
}

variable "jenkins_ingress_annotations" {
  description = "Annotations for the Ingress"
  type        = map(string)
  default = {
    "cert-manager.io/cluster-issuer" = "letsencrypt-prod"
  }
}

variable "jenkins_ingress_tls_enabled" {
  description = "Enable TLS for the Ingress"
  type        = bool
  default     = true
}

variable "jenkins_ingress_tls_secret_name" {
  description = "TLS secret name"
  type        = string
  default     = "jenkins-tls"
}

variable "jenkins_install_plugins" {
  description = "List of plugins for Jenkins"
  type        = list(string)
  default = [
    "kubernetes:4029.v5712230ccb_f8",
    "workflow-aggregator:596.v8c21c963d92d",
    "git:5.0.0",
    "configuration-as-code:1670.v564dc8b_982d0",
    "blueocean:1.27.2",
    "docker-workflow:563.vd5d2e5c4007f",
    "aws-credentials:191.vcb_f183ce58b_9",
    "amazon-ecr:1.7.3"
  ]
}

variable "jenkins_enable_hpa" {
  description = "Enable HorizontalPodAutoscaler"
  type        = bool
  default     = false
}

variable "jenkins_hpa_min_replicas" {
  description = "Minimum number of HPA replicas"
  type        = number
  default     = 1
}

variable "jenkins_hpa_max_replicas" {
  description = "Maximum number of HPA replicas"
  type        = number
  default     = 3
}

variable "jenkins_hpa_target_cpu_utilization" {
  description = "Target CPU utilization for HPA"
  type        = number
  default     = 70
}

variable "jenkins_hpa_target_memory_utilization" {
  description = "Target memory utilization for HPA"
  type        = number
  default     = 80
}

variable "jenkins_enable_prometheus_monitoring" {
  description = "Enable Prometheus monitoring"
  type        = bool
  default     = true
}

variable "jenkins_prometheus_scrape_interval" {
  description = "Prometheus scrape interval"
  type        = string
  default     = "30s"
}

variable "jenkins_enable_backup" {
  description = "Enable automatic backups"
  type        = bool
  default     = false
}

variable "jenkins_backup_schedule" {
  description = "Cron schedule for backups"
  type        = string
  default     = "0 2 * * *"
}

variable "jenkins_backup_retention_days" {
  description = "Number of days to keep backups"
  type        = number
  default     = 30
}

variable "jenkins_timezone" {
  description = "Time zone for Jenkins"
  type        = string
  default     = "UTC"
}

variable "jenkins_java_opts" {
  description = "Java options for Jenkins"
  type        = string
  default     = "-Xmx2g -Xms1g"
}

variable "jenkins_jenkins_opts" {
  description = "Jenkins options"
  type        = string
  default     = ""
}

variable "jenkins_enable_csrf_protection" {
  description = "Enable CSRF protection"
  type        = bool
  default     = true
}

variable "jenkins_enable_script_security" {
  description = "Enable script security"
  type        = bool
  default     = true
}

variable "jenkins_agent_connection_timeout" {
  description = "Timeout for agent connections"
  type        = number
  default     = 100
}

variable "argocd_release_name" {
  description = "Helm release name for Argo CD"
  type        = string
  default     = "argocd"
}

variable "argocd_namespace" {
  description = "Kubernetes namespace for Argo CD"
  type        = string
  default     = "argocd"
}

variable "argocd_helm_chart_version" {
  description = "Helm chart version for Argo CD"
  type        = string
  default     = "5.51.6"
}

variable "argocd_helm_timeout" {
  description = "Timeout for Helm operations"
  type        = number
  default     = 600
}

variable "argocd_admin_password" {
  description = "Argo CD admin password"
  type        = string
  sensitive   = true
}

variable "argocd_controller_resources" {
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

variable "argocd_server_resources" {
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

variable "argocd_repo_server_resources" {
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

variable "argocd_enable_ha" {
  description = "Enable High Availability mode"
  type        = bool
  default     = false
}

variable "argocd_controller_replicas" {
  description = "Number of Application Controller replicas"
  type        = number
  default     = 1
}

variable "argocd_server_replicas" {
  description = "Number of Server replicas"
  type        = number
  default     = 2
}

variable "argocd_repo_server_replicas" {
  description = "Number of Repo Server replicas"
  type        = number
  default     = 2
}

variable "argocd_service_type" {
  description = "Kubernetes service type for Argo CD"
  type        = string
  default     = "ClusterIP"
}

variable "argocd_create_load_balancer_service" {
  description = "Create a LoadBalancer service"
  type        = bool
  default     = false
}

variable "argocd_load_balancer_annotations" {
  description = "Annotations for the LoadBalancer service"
  type        = map(string)
  default = {
    "service.beta.kubernetes.io/aws-load-balancer-type" = "nlb"
  }
}

variable "argocd_load_balancer_source_ranges" {
  description = "CIDR blocks for the LoadBalancer"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "argocd_ingress_enabled" {
  description = "Enable Ingress for Argo CD"
  type        = bool
  default     = true
}

variable "argocd_create_custom_ingress" {
  description = "Create a custom Ingress"
  type        = bool
  default     = false
}

variable "argocd_ingress_hostname" {
  description = "Hostname for the Argo CD Ingress"
  type        = string
  default     = "argocd.local"
}

variable "argocd_ingress_class_name" {
  description = "Ingress class name"
  type        = string
  default     = "nginx"
}

variable "argocd_ingress_annotations" {
  description = "Annotations for the Ingress"
  type        = map(string)
  default = {
    "cert-manager.io/cluster-issuer" = "letsencrypt-prod"
  }
}

variable "argocd_ingress_tls_enabled" {
  description = "Enable TLS for the Ingress"
  type        = bool
  default     = true
}

variable "argocd_ingress_tls_secret_name" {
  description = "TLS secret name"
  type        = string
  default     = "argocd-tls"
}

variable "argocd_enable_metrics" {
  description = "Enable Prometheus metrics"
  type        = bool
  default     = true
}

variable "argocd_enable_notifications" {
  description = "Enable Argo CD Notifications"
  type        = bool
  default     = true
}

variable "argocd_enable_applicationset" {
  description = "Enable ApplicationSet Controller"
  type        = bool
  default     = true
}

variable "argocd_enable_dex" {
  description = "Enable Dex for OIDC"
  type        = bool
  default     = false
}

variable "argocd_enable_hpa" {
  description = "Enable HorizontalPodAutoscaler"
  type        = bool
  default     = false
}

variable "argocd_hpa_min_replicas" {
  description = "Minimum number of HPA replicas"
  type        = number
  default     = 2
}

variable "argocd_hpa_max_replicas" {
  description = "Maximum number of HPA replicas"
  type        = number
  default     = 5
}

variable "argocd_hpa_target_cpu_utilization" {
  description = "Target CPU utilization for HPA"
  type        = number
  default     = 70
}

variable "argocd_hpa_target_memory_utilization" {
  description = "Target memory utilization for HPA"
  type        = number
  default     = 80
}

variable "argocd_enable_prometheus_monitoring" {
  description = "Enable Prometheus monitoring"
  type        = bool
  default     = true
}

variable "argocd_prometheus_scrape_interval" {
  description = "Prometheus scrape interval"
  type        = string
  default     = "30s"
}

variable "argocd_enable_backup" {
  description = "Enable automatic backups"
  type        = bool
  default     = false
}

variable "argocd_backup_schedule" {
  description = "Cron schedule for backups"
  type        = string
  default     = "0 2 * * *"
}

variable "argocd_backup_retention_days" {
  description = "Number of days to keep backups"
  type        = number
  default     = 30
}

variable "argocd_create_demo_application" {
  description = "Create a demo Application"
  type        = bool
  default     = false
}

variable "argocd_demo_app_repo_url" {
  description = "Repository URL for the demo app"
  type        = string
  default     = "https://github.com/argoproj/argocd-example-apps.git"
}

variable "argocd_demo_app_target_revision" {
  description = "Target revision for the demo app"
  type        = string
  default     = "HEAD"
}

variable "argocd_demo_app_path" {
  description = "Path in the repository for the demo app"
  type        = string
  default     = "guestbook"
}

variable "argocd_demo_app_namespace" {
  description = "Namespace for the demo app"
  type        = string
  default     = "default"
}

variable "argocd_create_app_project" {
  description = "Create an AppProject"
  type        = bool
  default     = false
}

variable "argocd_app_project_name" {
  description = "AppProject name"
  type        = string
  default     = "default"
}

variable "argocd_app_project_source_repos" {
  description = "Allowed source repositories"
  type        = list(string)
  default     = ["*"]
}

variable "argocd_app_project_admin_groups" {
  description = "OIDC groups with admin rights"
  type        = list(string)
  default     = []
}

variable "argocd_app_project_developer_groups" {
  description = "OIDC groups with developer rights"
  type        = list(string)
  default     = []
}

variable "argocd_timezone" {
  description = "Time zone for Argo CD"
  type        = string
  default     = "UTC"
}

variable "argocd_log_level" {
  description = "Log level"
  type        = string
  default     = "info"
}

variable "argocd_log_format" {
  description = "Log format"
  type        = string
  default     = "text"
}

variable "argocd_sync_timeout" {
  description = "Timeout for sync operations"
  type        = number
  default     = 300
}

variable "argocd_self_heal_timeout" {
  description = "Timeout for self-heal operations"
  type        = number
  default     = 5
}

variable "argocd_enable_webhooks" {
  description = "Enable webhook support"
  type        = bool
  default     = true
}

variable "argocd_webhook_github_secret" {
  description = "Secret for GitHub webhooks"
  type        = string
  default     = ""
  sensitive   = true
}

variable "argocd_webhook_gitlab_secret" {
  description = "Secret for GitLab webhooks"
  type        = string
  default     = ""
  sensitive   = true
}

# Monitoring variables
variable "grafana_admin_password" {
  description = "Grafana admin password"
  type        = string
  sensitive   = true
}

variable "grafana_ingress_enabled" {
  description = "Enable Ingress for Grafana"
  type        = bool
  default     = false
}

variable "grafana_ingress_hostname" {
  description = "Hostname for the Grafana Ingress"
  type        = string
  default     = "grafana.local"
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Environment = "dev"
    Project     = "terraform-rds-module"
    ManagedBy   = "terraform"
  }
}
