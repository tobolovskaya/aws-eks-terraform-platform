# Root file that wires the modules together
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# VPC module
module "vpc" {
  source = "./modules/vpc"

  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs

  tags = var.common_tags
}

# RDS module
module "rds" {
  source = "./modules/rds"

  # Basic parameters
  use_aurora     = var.use_aurora
  engine         = var.db_engine
  engine_version = var.db_engine_version
  instance_class = var.db_instance_class

  # Network parameters
  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.vpc.private_subnet_ids
  allowed_cidr_blocks = [var.vpc_cidr]

  # Database parameters
  database_name = var.database_name
  username      = var.db_username
  password      = var.db_password

  # Extra settings
  multi_az                = var.multi_az
  backup_retention_period = var.backup_retention_period
  backup_window           = var.backup_window
  maintenance_window      = var.maintenance_window

  tags = var.common_tags
}

# EKS module
module "eks" {
  source = "./modules/eks"

  # Basic parameters
  cluster_name       = var.eks_cluster_name
  kubernetes_version = var.kubernetes_version

  # Network parameters
  vpc_id     = module.vpc.vpc_id
  subnet_ids = concat(module.vpc.private_subnet_ids, module.vpc.public_subnet_ids)

  # Node Groups
  node_groups = var.node_groups

  # EBS CSI Driver
  enable_ebs_csi_driver = var.enable_ebs_csi_driver

  tags = var.common_tags
}

# ECR module
module "ecr" {
  source = "./modules/ecr"

  # Basic parameters
  repository_name      = var.ecr_repository_name
  image_tag_mutability = var.ecr_image_tag_mutability

  # Scanning
  scan_on_push             = var.ecr_scan_on_push
  enable_registry_scanning = var.ecr_enable_registry_scanning

  # Encryption
  encryption_type = var.ecr_encryption_type
  kms_key         = var.ecr_kms_key

  # Lifecycle policy
  enable_lifecycle_policy = var.ecr_enable_lifecycle_policy
  max_image_count         = var.ecr_max_image_count
  untagged_image_days     = var.ecr_untagged_image_days

  # Cross-account access
  enable_cross_account_access = var.ecr_enable_cross_account_access
  cross_account_arns          = var.ecr_cross_account_arns

  tags = var.common_tags
}

# Providers for Jenkins (needed by Helm and Kubernetes)
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      module.eks.cluster_name,
      "--region",
      var.aws_region
    ]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = [
        "eks",
        "get-token",
        "--cluster-name",
        module.eks.cluster_name,
        "--region",
        var.aws_region
      ]
    }
  }
}

# Jenkins module
module "jenkins" {
  source = "./modules/jenkins"

  # Basic parameters
  release_name = var.jenkins_release_name
  namespace    = var.jenkins_namespace

  # Helm settings
  helm_chart_version = var.jenkins_helm_chart_version
  helm_timeout       = var.jenkins_helm_timeout

  # Jenkins configuration
  admin_user     = var.jenkins_admin_user
  admin_password = var.jenkins_admin_password

  # Resources
  resources = var.jenkins_resources

  # Storage
  persistence_enabled = var.jenkins_persistence_enabled
  storage_size        = var.jenkins_storage_size
  storage_class       = var.jenkins_storage_class
  create_pvc          = var.jenkins_create_pvc

  # Network settings
  service_type                 = var.jenkins_service_type
  create_load_balancer_service = var.jenkins_create_load_balancer_service
  load_balancer_annotations    = var.jenkins_load_balancer_annotations
  load_balancer_source_ranges  = var.jenkins_load_balancer_source_ranges

  # Ingress
  ingress_enabled         = var.jenkins_ingress_enabled
  create_custom_ingress   = var.jenkins_create_custom_ingress
  ingress_hostname        = var.jenkins_ingress_hostname
  ingress_class_name      = var.jenkins_ingress_class_name
  ingress_annotations     = var.jenkins_ingress_annotations
  ingress_tls_enabled     = var.jenkins_ingress_tls_enabled
  ingress_tls_secret_name = var.jenkins_ingress_tls_secret_name

  # Plugins
  install_plugins = var.jenkins_install_plugins

  # AWS integration
  aws_region         = var.aws_region
  ecr_registry_url   = module.ecr.repository_url
  ecr_repository_arn = module.ecr.repository_arn

  # IRSA for build agents
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.cluster_oidc_issuer_url

  # Auto Scaling
  enable_hpa                    = var.jenkins_enable_hpa
  hpa_min_replicas              = var.jenkins_hpa_min_replicas
  hpa_max_replicas              = var.jenkins_hpa_max_replicas
  hpa_target_cpu_utilization    = var.jenkins_hpa_target_cpu_utilization
  hpa_target_memory_utilization = var.jenkins_hpa_target_memory_utilization

  # Monitoring
  enable_prometheus_monitoring = var.jenkins_enable_prometheus_monitoring
  prometheus_scrape_interval   = var.jenkins_prometheus_scrape_interval

  # Backup
  enable_backup         = var.jenkins_enable_backup
  backup_schedule       = var.jenkins_backup_schedule
  backup_retention_days = var.jenkins_backup_retention_days

  # Extra settings
  timezone                 = var.jenkins_timezone
  java_opts                = var.jenkins_java_opts
  jenkins_opts             = var.jenkins_jenkins_opts
  enable_csrf_protection   = var.jenkins_enable_csrf_protection
  enable_script_security   = var.jenkins_enable_script_security
  agent_connection_timeout = var.jenkins_agent_connection_timeout

  tags = var.common_tags

  depends_on = [
    module.eks,
    module.ecr
  ]
}

# Argo CD module
module "argocd" {
  source = "./modules/argo_cd"

  # Basic parameters
  release_name = var.argocd_release_name
  namespace    = var.argocd_namespace

  # Helm settings
  helm_chart_version = var.argocd_helm_chart_version
  helm_timeout       = var.argocd_helm_timeout

  # Argo CD configuration
  admin_password = var.argocd_admin_password

  # Resources
  controller_resources  = var.argocd_controller_resources
  server_resources      = var.argocd_server_resources
  repo_server_resources = var.argocd_repo_server_resources

  # High Availability
  enable_ha            = var.argocd_enable_ha
  controller_replicas  = var.argocd_controller_replicas
  server_replicas      = var.argocd_server_replicas
  repo_server_replicas = var.argocd_repo_server_replicas

  # Network settings
  service_type                 = var.argocd_service_type
  create_load_balancer_service = var.argocd_create_load_balancer_service
  load_balancer_annotations    = var.argocd_load_balancer_annotations
  load_balancer_source_ranges  = var.argocd_load_balancer_source_ranges

  # Ingress
  ingress_enabled         = var.argocd_ingress_enabled
  create_custom_ingress   = var.argocd_create_custom_ingress
  ingress_hostname        = var.argocd_ingress_hostname
  ingress_class_name      = var.argocd_ingress_class_name
  ingress_annotations     = var.argocd_ingress_annotations
  ingress_tls_enabled     = var.argocd_ingress_tls_enabled
  ingress_tls_secret_name = var.argocd_ingress_tls_secret_name

  # Features
  enable_metrics        = var.argocd_enable_metrics
  enable_notifications  = var.argocd_enable_notifications
  enable_applicationset = var.argocd_enable_applicationset
  enable_dex            = var.argocd_enable_dex

  # Auto Scaling
  enable_hpa                    = var.argocd_enable_hpa
  hpa_min_replicas              = var.argocd_hpa_min_replicas
  hpa_max_replicas              = var.argocd_hpa_max_replicas
  hpa_target_cpu_utilization    = var.argocd_hpa_target_cpu_utilization
  hpa_target_memory_utilization = var.argocd_hpa_target_memory_utilization

  # Monitoring
  enable_prometheus_monitoring = var.argocd_enable_prometheus_monitoring
  prometheus_scrape_interval   = var.argocd_prometheus_scrape_interval

  # Backup
  enable_backup         = var.argocd_enable_backup
  backup_schedule       = var.argocd_backup_schedule
  backup_retention_days = var.argocd_backup_retention_days

  # GitOps settings
  create_demo_application  = var.argocd_create_demo_application
  demo_app_repo_url        = var.argocd_demo_app_repo_url
  demo_app_target_revision = var.argocd_demo_app_target_revision
  demo_app_path            = var.argocd_demo_app_path
  demo_app_namespace       = var.argocd_demo_app_namespace

  # AppProject
  create_app_project           = var.argocd_create_app_project
  app_project_name             = var.argocd_app_project_name
  app_project_source_repos     = var.argocd_app_project_source_repos
  app_project_admin_groups     = var.argocd_app_project_admin_groups
  app_project_developer_groups = var.argocd_app_project_developer_groups

  # Extra settings
  timezone          = var.argocd_timezone
  log_level         = var.argocd_log_level
  log_format        = var.argocd_log_format
  sync_timeout      = var.argocd_sync_timeout
  self_heal_timeout = var.argocd_self_heal_timeout

  # Webhooks
  enable_webhooks       = var.argocd_enable_webhooks
  webhook_github_secret = var.argocd_webhook_github_secret
  webhook_gitlab_secret = var.argocd_webhook_gitlab_secret

  tags = var.common_tags

  depends_on = [
    module.eks,
    module.jenkins
  ]
}

# Monitoring module (Prometheus + Grafana)
module "monitoring" {
  source = "./modules/monitoring"

  # Credentials
  grafana_admin_password = var.grafana_admin_password

  # Ingress settings
  grafana_ingress_enabled  = var.grafana_ingress_enabled
  grafana_ingress_hostname = var.grafana_ingress_hostname

  depends_on = [
    module.eks,
    module.jenkins,
    module.argocd
  ]
}

# Variables
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b"]
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

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
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