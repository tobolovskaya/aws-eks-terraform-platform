# Root module: wires the platform modules together

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

  # Backup
  enable_backup   = var.jenkins_enable_backup
  backup_schedule = var.jenkins_backup_schedule

  # Extra settings
  java_opts = var.jenkins_java_opts

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

  # Backup

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

  # Webhooks
  enable_webhooks = var.argocd_enable_webhooks


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
