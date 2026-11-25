# Гнучкий Terraform-модуль для баз даних

Універсальний Terraform-модуль для створення баз даних AWS RDS або Aurora кластерів з повною автоматизацією інфраструктури.

## 🎯 Особливості

- **Універсальність**: Підтримка як звичайних RDS інстансів, так і Aurora кластерів
- **Гнучкість движків**: PostgreSQL, MySQL, MariaDB з автоматичним налаштуванням
- **Безпека**: Автоматичне шифрування, Security Groups, мережева ізоляція
- **Продакшн готовність**: Multi-AZ, бекапи, моніторинг, Performance Insights
- **Простота використання**: Мінімальна конфігурація з розумними значеннями за замовчуванням
- **Argo CD GitOps** для continuous deployment
- **ApplicationSet Controller** для управління множинними додатками
- **Notifications** для Slack/Email інтеграції

## 📁 Структура проєкту

```
Project/
├── main.tf                  # Головний файл для підключення модулів
├── backend.tf               # Налаштування бекенду для стейтів
├── setup-backend.tf         # Початкове налаштування S3 backend
├── backend-setup.tfvars     # Конфігурація для setup-backend.tf
├── outputs.tf               # Загальні виводи ресурсів
├── terraform.tfvars.example # Приклад конфігурації
├── README.md               # Документація
└── modules/
    ├── vpc/                # Модуль для VPC
    │   ├── vpc.tf
    │   ├── routes.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── s3-backend/         # Модуль для S3 та DynamoDB backend
    │   ├── s3.tf           # Створення S3 бакета
    │   ├── dynamodb.tf     # Створення DynamoDB таблиці
    │   ├── variables.tf    # Змінні для backend
    │   └── outputs.tf      # Виведення інформації
    ├── rds/                # Модуль для RDS/Aurora
        ├── rds.tf          # Звичайна RDS
        ├── aurora.tf       # Aurora кластер
        ├── shared.tf       # Спільні ресурси
        ├── variables.tf    # Змінні
        └── outputs.tf      # Виводи
    └── eks/                # Модуль для Kubernetes кластера
        ├── eks.tf          # Створення кластера
        ├── aws_ebs_csi_driver.tf # EBS CSI Driver
        ├── variables.tf    # Змінні для EKS
        ├── outputs.tf      # Виведення інформації
        └── user_data.sh    # Скрипт для node groups
    └── ecr/                # Модуль для Container Registry
        ├── ecr.tf          # Створення ECR репозиторію
        ├── variables.tf    # Змінні для ECR
        └── outputs.tf      # Виведення URL репозиторію
    └── jenkins/            # Модуль для Jenkins CI/CD
        ├── jenkins.tf      # Helm release для Jenkins
        ├── variables.tf    # Змінні для Jenkins
        ├── providers.tf    # Провайдери (Kubernetes, Helm)
        ├── values.yaml     # Конфігурація Jenkins
        └── outputs.tf      # Виводи (URL, креденшели)
    └── argo_cd/            # Модуль для Argo CD GitOps
        ├── argo_cd.tf      # Helm release для Argo CD
        ├── variables.tf    # Змінні для Argo CD
        ├── providers.tf    # Провайдери (Kubernetes, Helm)
        ├── values.yaml     # Конфігурація Argo CD
        └── outputs.tf      # Виводи (URL, креденшели)
```

## 🚀 Швидкий старт

### 0. Налаштування S3 Backend (перший раз)

Перед використанням основної інфраструктури потрібно створити S3 backend:

```bash
# 1. Налаштуйте backend конфігурацію
cp backend-setup.tfvars.example backend-setup.tfvars
# Відредагуйте backend-setup.tfvars з унікальною назвою бакета

# 2. Створіть S3 та DynamoDB ресурси
terraform init
terraform apply -var-file="backend-setup.tfvars" setup-backend.tf

# 3. Скопіюйте виведену конфігурацію в backend.tf
terraform output backend_configuration

# 4. Ініціалізуйте backend
terraform init -migrate-state

# 5. Видаліть setup-backend.tf (більше не потрібен)
rm setup-backend.tf backend-setup.tfvars
```

### 1. Клонування та налаштування

```bash
git clone <repository-url>
cd terraform-rds-module
cp terraform.tfvars.example terraform.tfvars
```

### 2. Налаштування змінних

Відредагуйте `terraform.tfvars`:

```hcl
# Основні налаштування
aws_region = "us-west-2"
use_aurora = false  # true для Aurora
db_engine = "postgres"
db_password = "your-secure-password"

# EKS налаштування
eks_cluster_name = "my-cluster"
kubernetes_version = "1.35"

# Jenkins налаштування
jenkins_admin_password = "secure-password"
jenkins_ingress_hostname = "jenkins.yourdomain.com"

# Argo CD налаштування
argocd_admin_password = "secure-password"
argocd_ingress_hostname = "argocd.yourdomain.com"

# Теги
common_tags = {
  Environment = "dev"
  Project     = "my-project"
  Owner       = "your-name"
}
```

### 3. Розгортання

```bash
terraform init
terraform plan
terraform apply
```

### 4. Підключення до EKS кластера

```bash
# Налаштування kubectl
aws eks update-kubeconfig --region us-west-2 --name my-cluster

# Перевірка підключення
kubectl get nodes
```

### 6. Доступ до Jenkins

```bash
# Отримання URL Jenkins
terraform output jenkins_url

# Port-forward для локального доступу
terraform output kubectl_port_forward_command

# Отримання пароля адміністратора
terraform output jenkins_admin_password
```

### 7. Доступ до Argo CD

```bash
# Отримання URL Argo CD
terraform output argocd_url

# Port-forward для локального доступу
kubectl port-forward -n argocd svc/argocd-argocd-server 8080:80

# Отримання пароля адміністратора
terraform output argocd_admin_password

# Логін через CLI
terraform output argocd_cli_login_command
```

### 5. Завантаження образів в ECR

```bash
# Отримання команд для завантаження
terraform output ecr_docker_push_commands

# Логін в ECR
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-west-2.amazonaws.com

# Збірка та завантаження образу
docker build -t my-app .
docker tag my-app:latest <ecr-url>:latest
docker push <ecr-url>:latest
```

## 📖 Приклади використання

### S3 Backend для Terraform State

```hcl
module "s3_backend" {
  source = "./modules/s3-backend"
  
  # Основні параметри
  bucket_name         = "my-terraform-state-bucket"
  dynamodb_table_name = "terraform-state-lock"
  environment         = "production"
  
  # S3 налаштування
  state_retention_days  = 365  # Зберігати стан рік
  enable_access_logging = true
  
  # DynamoDB налаштування
  dynamodb_billing_mode         = "PROVISIONED"
  dynamodb_read_capacity        = 10
  dynamodb_write_capacity       = 10
  enable_point_in_time_recovery = true
  
  # Auto Scaling
  enable_dynamodb_autoscaling             = true
  dynamodb_autoscaling_read_max_capacity  = 100
  dynamodb_autoscaling_write_max_capacity = 100
  
  # Моніторинг
  enable_cloudwatch_alarms = true
  sns_topic_arn           = "arn:aws:sns:us-west-2:123456789012:terraform-alerts"
  
  tags = {
    Environment = "production"
    Project     = "infrastructure"
  }
}
```

### Звичайна PostgreSQL RDS

```hcl
module "rds" {
  source = "./modules/rds"
  
  # Основні параметри
  use_aurora     = false
  engine         = "postgres"
  engine_version = "15.4"
  instance_class = "db.t3.micro"
  
  # Мережа
  vpc_id               = module.vpc.vpc_id
  subnet_ids          = module.vpc.private_subnet_ids
  allowed_cidr_blocks = ["10.0.0.0/16"]
  
  # База даних
  database_name = "myapp"
  username     = "dbadmin"
  password     = var.db_password
  
  # Налаштування
  multi_az                = false
  backup_retention_period = 7
  storage_encrypted      = true
  
  tags = {
    Environment = "production"
    Project     = "my-app"
  }
}
```

### ECR репозиторій з lifecycle політикою

```hcl
module "ecr" {
  source = "./modules/ecr"
  
  # Основні параметри
  repository_name      = "my-application"
  image_tag_mutability = "IMMUTABLE"  # Для продакшну
  
  # Безпека
  scan_on_push             = true
  enable_registry_scanning = true
  encryption_type         = "KMS"
  kms_key                = "arn:aws:kms:us-west-2:123456789012:key/12345678-1234-1234-1234-123456789012"
  
  # Управління образами
  enable_lifecycle_policy = true
  max_image_count        = 50
  untagged_image_days    = 7
  lifecycle_tag_prefixes = ["v", "release", "prod"]
  
  # Міжакаунтний доступ
  enable_cross_account_access = true
  cross_account_arns = [
    "arn:aws:iam::123456789012:root",
    "arn:aws:iam::987654321098:root"
  ]
  
  # Реплікація
  replication_regions = [
    {
      region      = "eu-west-1"
      registry_id = "123456789012"
    }
  ]
  
  tags = {
    Environment = "production"
    Project     = "my-app"
  }
}
```

### Jenkins CI/CD платформа

### Argo CD GitOps платформа

```hcl
module "argocd" {
  source = "./modules/argo_cd"
  
  # Основні параметри
  release_name = "argocd"
  namespace    = "argocd"
  
  # Креденшели
  admin_password = "secure-password-here"
  
  # Ресурси
  controller_resources = {
    requests = {
      cpu    = "250m"
      memory = "1Gi"
    }
    limits = {
      cpu    = "500m"
      memory = "2Gi"
    }
  }
  
  server_resources = {
    requests = {
      cpu    = "100m"
      memory = "128Mi"
    }
    limits = {
      cpu    = "500m"
      memory = "512Mi"
    }
  }
  
  # High Availability
  enable_ha = true
  controller_replicas = 1
  server_replicas = 3
  repo_server_replicas = 2
  
  # Ingress
  ingress_enabled     = true
  ingress_hostname    = "argocd.company.com"
  ingress_tls_enabled = true
  
  # Функціональність
  enable_metrics        = true
  enable_notifications  = true
  enable_applicationset = true
  enable_dex           = true
  
  # GitOps налаштування
  create_demo_application = true
  demo_app_repo_url      = "https://github.com/company/k8s-manifests.git"
  
  # AppProject
  create_app_project           = true
  app_project_name            = "production"
  app_project_source_repos    = ["https://github.com/company/*"]
  app_project_admin_groups    = ["argocd-admins"]
  app_project_developer_groups = ["developers"]
  
  # Моніторинг
  enable_prometheus_monitoring = true
  
  # Backup
  enable_backup         = true
  backup_schedule       = "0 2 * * *"
  backup_retention_days = 90
  
  tags = {
    Environment = "production"
    Project     = "gitops"
  }
}
```

```hcl
module "jenkins" {
  source = "./modules/jenkins"
  
  # Основні параметри
  release_name = "jenkins"
  namespace    = "jenkins"
  
  # Креденшели
  admin_user     = "admin"
  admin_password = "secure-password-here"
  
  # Ресурси
  resources = {
    requests = {
      cpu    = "1"
      memory = "2Gi"
    }
    limits = {
      cpu    = "4"
      memory = "8Gi"
    }
  }
  
  # Сховище
  persistence_enabled = true
  storage_size       = "50Gi"
  storage_class      = "gp3"
  
  # Ingress
  ingress_enabled     = true
  ingress_hostname    = "jenkins.company.com"
  ingress_tls_enabled = true
  
  # AWS інтеграція
  aws_region       = "us-west-2"
  ecr_registry_url = module.ecr.repository_url
  
  # Плагіни
  install_plugins = [
    "kubernetes:latest",
    "workflow-aggregator:latest",
    "git:latest",
    "docker-workflow:latest",
    "aws-credentials:latest",
    "amazon-ecr:latest",
    "github:latest",
    "slack:latest"
  ]
  
  # Моніторинг
  enable_prometheus_monitoring = true
  
  # Backup
  enable_backup         = true
  backup_schedule       = "0 2 * * *"
  backup_retention_days = 90
  
  tags = {
    Environment = "production"
    Project     = "ci-cd"
  }
}
```

### EKS кластер з node groups

```hcl
module "eks" {
  source = "./modules/eks"
  
  # Основні параметри
  cluster_name       = "production-cluster"
  kubernetes_version = "1.35"
  
  # Мережа
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids
  
  # Node Groups
  node_groups = [
    {
      name           = "main"
      instance_types = ["t3.medium"]
      desired_size   = 3
      max_size       = 5
      min_size       = 1
      disk_size      = 50
      subnet_ids     = module.vpc.private_subnet_ids
      labels = {
        Environment = "production"
        NodeGroup   = "main"
      }
      taints = []
    },
    {
      name           = "spot"
      instance_types = ["t3.large", "t3.xlarge"]
      capacity_type  = "SPOT"
      desired_size   = 2
      max_size       = 10
      min_size       = 0
      disk_size      = 100
      subnet_ids     = module.vpc.private_subnet_ids
      labels = {
        Environment = "production"
        NodeGroup   = "spot"
      }
      taints = [
        {
          key    = "spot"
          value  = "true"
          effect = "NO_SCHEDULE"
        }
      ]
    }
  ]
  
  # EBS CSI Driver
  enable_ebs_csi_driver = true
  
  tags = {
    Environment = "production"
    Project     = "my-app"
  }
}
```

### Aurora PostgreSQL кластер

```hcl
module "aurora" {
  source = "./modules/rds"
  
  # Aurora налаштування
  use_aurora            = true
  engine               = "postgres"
  engine_version       = "15.4"
  instance_class       = "db.r6g.large"
  aurora_cluster_instances = 2
  
  # Мережа
  vpc_id               = module.vpc.vpc_id
  subnet_ids          = module.vpc.private_subnet_ids
  allowed_cidr_blocks = ["10.0.0.0/16"]
  
  # База даних
  database_name = "production_db"
  username     = "admin"
  password     = var.db_password
  
  # Продакшн налаштування
  backup_retention_period = 30
  deletion_protection    = true
  performance_insights_enabled = true
  
  tags = {
    Environment = "production"
    Project     = "my-app"
  }
}
```

### Aurora Serverless v2

```hcl
module "aurora_serverless" {
  source = "./modules/rds"
  
  # Serverless налаштування
  use_aurora           = true
  aurora_serverless_v2 = true
  aurora_serverless_v2_scaling = {
    min_capacity = 0.5
    max_capacity = 4
  }
  
  engine         = "postgres"
  instance_class = "db.serverless"
  
  # Решта налаштувань...
}
```

### MySQL з кастомними параметрами

```hcl
module "mysql_rds" {
  source = "./modules/rds"
  
  use_aurora = false
  engine     = "mysql"
  
  # Кастомні параметри БД
  custom_db_parameters = {
    "innodb_buffer_pool_size" = {
      value        = "{DBInstanceClassMemory*3/4}"
      apply_method = "pending-reboot"
    }
    "max_connections" = {
      value        = "200"
      apply_method = "immediate"
    }
  }
  
  # Решта налаштувань...
}
```

## 🔧 Змінні модуля

### S3 Backend модуль

| Змінна | Тип | За замовчуванням | Опис |
|--------|-----|------------------|------|
| `bucket_name` | `string` | - | Назва S3 бакета (обов'язково) |
| `dynamodb_table_name` | `string` | `"terraform-state-lock"` | Назва DynamoDB таблиці |
| `environment` | `string` | `"dev"` | Середовище (dev, staging, prod) |
| `state_retention_days` | `number` | `90` | Днів зберігання старих версій |
| `enable_access_logging` | `bool` | `false` | Логування доступу до S3 |
| `dynamodb_billing_mode` | `string` | `"PAY_PER_REQUEST"` | Режим біллінгу DynamoDB |
| `enable_point_in_time_recovery` | `bool` | `true` | Point-in-Time Recovery |
| `enable_cloudwatch_alarms` | `bool` | `false` | CloudWatch алерти |

### Основні параметри

| Змінна | Тип | За замовчуванням | Опис |
|--------|-----|------------------|------|
| `use_aurora` | `bool` | `false` | Використовувати Aurora замість RDS |
| `engine` | `string` | `"postgres"` | Движок БД (postgres, mysql, mariadb) |
| `engine_version` | `string` | `""` | Версія движка (автоматично, якщо пусто) |
| `instance_class` | `string` | `"db.t3.micro"` | Клас інстансу |

### Мережеві параметри

| Змінна | Тип | Опис |
|--------|-----|------|
| `vpc_id` | `string` | ID VPC |
| `subnet_ids` | `list(string)` | ID підмереж для DB subnet group |
| `allowed_cidr_blocks` | `list(string)` | CIDR блоки з доступом до БД |
| `allowed_security_groups` | `list(string)` | Security groups з доступом до БД |

### Параметри бази даних

| Змінна | Тип | За замовчуванням | Опис |
|--------|-----|------------------|------|
| `database_name` | `string` | `"myapp"` | Назва БД |
| `username` | `string` | `"dbadmin"` | Головний користувач |
| `password` | `string` | - | Пароль (обов'язково) |
| `port` | `number` | `null` | Порт (автоматично за движком) |

### Налаштування продуктивності

| Змінна | Тип | За замовчуванням | Опис |
|--------|-----|------------------|------|
| `allocated_storage` | `number` | `20` | Розмір сховища (ГБ, тільки RDS) |
| `max_allocated_storage` | `number` | `100` | Макс. розмір для автоскейлінгу |
| `storage_type` | `string` | `"gp3"` | Тип сховища |
| `multi_az` | `bool` | `false` | Multi-AZ розгортання |

### Aurora специфічні

| Змінна | Тип | За замовчуванням | Опис |
|--------|-----|------------------|------|
| `aurora_cluster_instances` | `number` | `2` | Кількість інстансів в кластері |
| `aurora_serverless_v2` | `bool` | `false` | Використовувати Serverless v2 |
| `aurora_serverless_v2_scaling` | `object` | `{min=0.5, max=1}` | Налаштування масштабування |

### Бекапи та обслуговування

| Змінна | Тип | За замовчуванням | Опис |
|--------|-----|------------------|------|
| `backup_retention_period` | `number` | `7` | Період зберігання бекапів (дні) |
| `backup_window` | `string` | `"03:00-04:00"` | Вікно бекапів (UTC) |
| `maintenance_window` | `string` | `"sun:04:00-sun:05:00"` | Вікно обслуговування |
### EKS параметри

| Змінна | Тип | За замовчуванням | Опис |
|--------|-----|------------------|------|
| `eks_cluster_name` | `string` | `"my-eks-cluster"` | Назва EKS кластера |
| `kubernetes_version` | `string` | `"1.35"` | Версія Kubernetes |
| `node_groups` | `list(object)` | `[...]` | Конфігурація node groups |

### ECR параметри

| Змінна | Тип | За замовчуванням | Опис |
|--------|-----|------------------|------|
| `ecr_repository_name` | `string` | `"my-app"` | Назва ECR репозиторію |
| `ecr_image_tag_mutability` | `string` | `"MUTABLE"` | Можливість змінювати теги |
| `ecr_scan_on_push` | `bool` | `true` | Сканувати образи при завантаженні |
| `ecr_encryption_type` | `string` | `"AES256"` | Тип шифрування (AES256/KMS) |
| `ecr_enable_cross_account_access` | `bool` | `false` | Міжакаунтний доступ |
| `enable_ebs_csi_driver` | `bool` | `true` | Увімкнути EBS CSI Driver |

| `deletion_protection` | `bool` | `true` | Захист від видалення |

### Моніторинг

| Змінна | Тип | За замовчуванням | Опис |
|--------|-----|------------------|------|
| `monitoring_interval` | `number` | `60` | Інтервал моніторингу (сек) |
| `performance_insights_enabled` | `bool` | `true` | Performance Insights |
| `enabled_cloudwatch_logs_exports` | `list(string)` | `[]` | Типи логів для CloudWatch |

## 📤 Виводи модуля

### S3 Backend виводи

| Вивід | Опис |
|-------|------|
| `s3_bucket_id` | ID S3 бакета |
| `s3_bucket_arn` | ARN S3 бакета |
| `dynamodb_table_name` | Назва DynamoDB таблиці |
| `terraform_backend_config` | Об'єкт конфігурації backend |
| `backend_configuration` | Готовий блок backend для копіювання |

### Підключення

| Вивід | Опис |
|-------|------|
| `endpoint` | Основний endpoint для підключення |
| `reader_endpoint` | Reader endpoint (тільки Aurora) |
| `port` | Порт бази даних |
| `connection_string` | Повний рядок підключення |

### EKS виводи

| Вивід | Опис |
|-------|------|
| `eks_cluster_endpoint` | Endpoint EKS кластера |
| `kubectl_config_command` | Команда для налаштування kubectl |
| `cluster_security_group_id` | ID Security Group кластера |
| `node_security_group_id` | ID Security Group node groups |

### ECR виводи

| Вивід | Опис |
|-------|------|
| `ecr_repository_url` | URL ECR репозиторію |
| `ecr_repository_arn` | ARN ECR репозиторію |
| `ecr_docker_push_commands` | Команди для завантаження образу |
| `ecr_login_command` | Команда для логіну в ECR |
| `ecr_login_command` | Команда для логіну в ECR |

### Jenkins виводи

| Вивід | Опис |
|-------|------|
| `jenkins_url` | URL для доступу до Jenkins |
| `jenkins_admin_user` | Ім'я адміністратора |
| `jenkins_admin_password` | Пароль адміністратора (sensitive) |
| `kubectl_port_forward_command` | Команда для port-forward |
| `jenkins_webhook_url` | URL для GitHub/GitLab webhooks |
| `jenkins_api_url` | URL для Jenkins API |

### Ідентифікатори

| Вивід | Опис |
|-------|------|
| `db_instance_id` | ID RDS інстансу |
| `cluster_id` | ID Aurora кластера |
| `security_group_id` | ID Security Group |
| `subnet_group_name` | Назва DB Subnet Group |

## 🔧 Робота з EKS

### Підключення до кластера

```bash
# Отримання команди підключення
terraform output kubectl_config_command

# Виконання команди
aws eks update-kubeconfig --region us-west-2 --name my-cluster

# Перевірка
kubectl get nodes
kubectl get pods --all-namespaces
```

### Встановлення додатків

```bash
# Встановлення Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Додавання репозиторіїв
helm repo add stable https://charts.helm.sh/stable
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Встановлення NGINX Ingress Controller
helm install nginx-ingress bitnami/nginx-ingress-controller

# Встановлення cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
```

### Масштабування node groups

```bash
# Масштабування через AWS CLI
aws eks update-nodegroup-config \
  --cluster-name my-cluster \
  --nodegroup-name main \
  --scaling-config minSize=2,maxSize=6,desiredSize=4

# Або через Terraform
# Змініть desired_size в terraform.tfvars та виконайте:
terraform apply
```

## 🐳 Робота з ECR

### Django Application Deployment

```bash
# Deploy Django app using Helm chart
helm install my-django-app ./charts/django-app \
  --set image.repository=123456789012.dkr.ecr.us-west-2.amazonaws.com/django-app \
  --set image.tag=v1.0.0 \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=django-app.yourdomain.com \
  --set secrets.djangoSecretKey=your-secret-key \
  --set secrets.dbPassword=your-db-password

# Upgrade deployment
helm upgrade my-django-app ./charts/django-app \
  --set image.tag=v1.1.0

# Check deployment status
kubectl get pods -l app.kubernetes.io/name=django-app
kubectl logs -l app.kubernetes.io/name=django-app
```

### Завантаження образів

```bash
# Отримання команд
terraform output ecr_docker_push_commands

# Логін в ECR
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin 123456789012.dkr.ecr.us-west-2.amazonaws.com

# Збірка образу
docker build -t my-app .

# Тегування
docker tag my-app:latest 123456789012.dkr.ecr.us-west-2.amazonaws.com/my-app:latest
docker tag my-app:latest 123456789012.dkr.ecr.us-west-2.amazonaws.com/my-app:v1.0.0

# Завантаження
docker push 123456789012.dkr.ecr.us-west-2.amazonaws.com/my-app:latest
docker push 123456789012.dkr.ecr.us-west-2.amazonaws.com/my-app:v1.0.0
```

## 🔧 Робота з Jenkins

## 🔧 Робота з Argo CD

### Доступ до Argo CD

```bash
# Отримання URL
terraform output argocd_url

# Port-forward для локального доступу
kubectl port-forward -n argocd svc/argocd-argocd-server 8080:80

# Відкрити в браузері
open http://localhost:8080

# Логін: admin
# Пароль: terraform output argocd_admin_password
```

### Встановлення Argo CD CLI

```bash
# macOS
brew install argocd

# Linux
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64

# Логін через CLI
terraform output argocd_cli_login_command
```

### Створення Application

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/company/k8s-manifests
    targetRevision: HEAD
    path: apps/my-app
  destination:
    server: https://kubernetes.default.svc
    namespace: production
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
```

### ApplicationSet для множинних додатків

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: microservices
  namespace: argocd
spec:
  generators:
  - git:
      repoURL: https://github.com/company/k8s-manifests
      revision: HEAD
      directories:
      - path: apps/*
  template:
    metadata:
      name: '{{path.basename}}'
    spec:
      project: default
      source:
        repoURL: https://github.com/company/k8s-manifests
        targetRevision: HEAD
        path: '{{path}}'
      destination:
        server: https://kubernetes.default.svc
        namespace: '{{path.basename}}'
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
```

### Налаштування Git Webhooks

```bash
# Отримання webhook URLs
terraform output argocd_webhook_urls

# GitHub webhook URL: https://argocd.yourdomain.com/api/webhook
# GitLab webhook URL: https://argocd.yourdomain.com/api/webhook
```

### CLI команди

```bash
# Список додатків
argocd app list

# Синхронізація додатку
argocd app sync my-app

# Статус додатку
argocd app get my-app

# Логи синхронізації
argocd app logs my-app

# Rollback
argocd app rollback my-app

# Видалення додатку
argocd app delete my-app
```

### Доступ до Jenkins

```bash
# Отримання URL
terraform output jenkins_url

# Port-forward для локального доступу
kubectl port-forward -n jenkins svc/jenkins-jenkins 8080:8080

# Відкрити в браузері
open http://localhost:8080

# Логін: admin
# Пароль: terraform output jenkins_admin_password
```

### Налаштування GitHub Integration

1. **Webhook URL**: `https://jenkins.yourdomain.com/github-webhook/`
2. **API Token**: Створіть в Jenkins → Manage Jenkins → Configure System
3. **Credentials**: Додайте GitHub token в Jenkins credentials

### Приклад Pipeline

```groovy
pipeline {
    agent {
        kubernetes {
            yaml """
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: docker
    image: docker:latest
    command:
    - cat
    tty: true
    volumeMounts:
    - mountPath: /var/run/docker.sock
      name: docker-sock
  volumes:
  - name: docker-sock
    hostPath:
      path: /var/run/docker.sock
"""
        }
    }
    
    environment {
        ECR_REGISTRY = "${ECR_REGISTRY_URL}"
        IMAGE_TAG = "${BUILD_NUMBER}"
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Build') {
            steps {
                container('docker') {
                    script {
                        sh 'docker build -t $ECR_REGISTRY:$IMAGE_TAG .'
                    }
                }
            }
        }
        
        stage('Push to ECR') {
            steps {
                container('docker') {
                    script {
                        sh '''
                            aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin $ECR_REGISTRY
                            docker push $ECR_REGISTRY:$IMAGE_TAG
                        '''
                    }
                }
            }
        }
        
        stage('Deploy') {
            steps {
                script {
                    sh '''
                        kubectl set image deployment/my-app my-app=$ECR_REGISTRY:$IMAGE_TAG
                        kubectl rollout status deployment/my-app
                    '''
                }
            }
        }
    }
    
    post {
        success {
            slackSend(
                color: 'good',
                message: "✅ Build ${BUILD_NUMBER} успішно розгорнуто!"
            )
        }
        failure {
            slackSend(
                color: 'danger',
                message: "❌ Build ${BUILD_NUMBER} завершився з помилкою!"
            )
        }
    }
}
```

### Встановлення додаткових плагінів

```bash
# Через Jenkins UI
Manage Jenkins → Manage Plugins → Available

# Або через Configuration as Code
# Додайте плагіни в terraform.tfvars:
jenkins_install_plugins = [
  "kubernetes:latest",
  "workflow-aggregator:latest",
  "git:latest",
  "github:latest",
  "slack:latest",
  "sonar:latest",
  "docker-workflow:latest"
]
```

### Використання в Kubernetes

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: my-app
        image: 123456789012.dkr.ecr.us-west-2.amazonaws.com/my-app:v1.0.0
        ports:
        - containerPort: 8080
```

### CI/CD інтеграція

```yaml
# GitHub Actions приклад
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v1
  with:
    aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
    aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
    aws-region: us-west-2

- name: Login to Amazon ECR
  id: login-ecr
  uses: aws-actions/amazon-ecr-login@v1

- name: Build, tag, and push image to Amazon ECR
  env:
    ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
    ECR_REPOSITORY: my-app
    IMAGE_TAG: ${{ github.sha }}
  run: |
    docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG .
    docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
```

## 🔄 Зміна типу БД

### Міграція на S3 Backend

Якщо ви використовуєте локальний state і хочете перейти на S3:

```bash
# 1. Створіть S3 backend ресурси
terraform apply -var-file="backend-setup.tfvars" setup-backend.tf

# 2. Додайте backend конфігурацію в main.tf
terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket"
    key            = "terraform/state"
    region         = "us-west-2"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

# 3. Мігруйте state
terraform init -migrate-state
```

### З RDS на Aurora

1. Створіть snapshot поточної БД:
```bash
aws rds create-db-snapshot --db-instance-identifier mydb --db-snapshot-identifier mydb-migration-snapshot
```

2. Змініть конфігурацію:
```hcl
use_aurora = true
# Додайте Aurora-специфічні налаштування
```

3. Застосуйте зміни:
```bash
terraform apply
```

### Зміна движка

⚠️ **Увага**: Зміна движка вимагає міграції даних!

1. Створіть бекап даних
2. Змініть `engine` в конфігурації
3. Застосуйте зміни (створить нову БД)
4. Мігруйте дані з бекапу

### Зміна класу інстансу

```hcl
instance_class = "db.t3.small"  # Збільшення розміру
```

Застосуйте зміни:
```bash
terraform apply
```

## 🚀 Розгортання додатків в EKS

### Приклад Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: my-app
        image: nginx:latest
        ports:
        - containerPort: 80
        volumeMounts:
        - name: data
          mountPath: /data
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: my-app-pvc
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-app-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: gp3
  resources:
    requests:
      storage: 10Gi
```

## 🛡️ Безпека

### S3 Backend безпека

Модуль автоматично налаштовує:
- **Шифрування** всіх об'єктів в S3
- **Версіонування** для відстеження змін
- **Блокування публічного доступу**
- **Політику HTTPS-only**
- **Lifecycle правила** для оптимізації вартості
- **Point-in-Time Recovery** для DynamoDB

### Рекомендації

1. **Паролі**: Використовуйте AWS Secrets Manager або змінні середовища
2. **Мережа**: Розміщуйте БД в приватних підмережах
3. **Шифрування**: Завжди увімкнене за замовчуванням
4. **Доступ**: Обмежуйте через Security Groups
5. **EKS**: Використовуйте RBAC та Pod Security Standards
6. **Secrets**: Зберігайте секрети в AWS Secrets Manager або Kubernetes Secrets

### Приклад з Secrets Manager

```hcl
# Створення секрету
resource "aws_secretsmanager_secret" "db_password" {
  name = "rds-password"
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = var.db_password
}

# Використання в модулі
module "rds" {
  # ...
  password = aws_secretsmanager_secret_version.db_password.secret_string
}
```

### RBAC для EKS

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: developer
rules:
- apiGroups: [""]
  resources: ["pods", "services", "configmaps"]
  verbs: ["get", "list", "create", "update", "delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: developer-binding
subjects:
- kind: User
  name: developer@company.com
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: developer
  apiGroup: rbac.authorization.k8s.io
```

## 💰 Оптимізація вартості

### S3 Backend оптимізація

```hcl
# Для розробки
dynamodb_billing_mode = "PAY_PER_REQUEST"  # Платіть тільки за використання
state_retention_days  = 30                 # Коротший період зберігання
enable_access_logging = false              # Вимкнути логування

# Для продакшну
dynamodb_billing_mode = "PROVISIONED"      # Передбачувана вартість
enable_dynamodb_autoscaling = true         # Автоскейлінг для оптимізації
enable_cloudwatch_alarms = true            # Моніторинг для контролю
```

### Для розробки
```hcl
# RDS
instance_class = "db.t3.micro"
multi_az = false
backup_retention_period = 1
deletion_protection = false

# EKS
node_groups = [
  {
    name           = "dev"
    instance_types = ["t3.small"]
    capacity_type  = "SPOT"
    desired_size   = 1
    max_size       = 2
    min_size       = 1
  }
]
```

### Для продакшну
```hcl
# RDS
instance_class = "db.r6g.large"
multi_az = true
backup_retention_period = 30
deletion_protection = true
performance_insights_enabled = true

# EKS
node_groups = [
  {
    name           = "production"
    instance_types = ["m5.large"]
    capacity_type  = "ON_DEMAND"
    desired_size   = 3
    max_size       = 10
    min_size       = 3
  }
]
```

### Aurora Serverless для змінних навантажень
```hcl
use_aurora = true
aurora_serverless_v2 = true
aurora_serverless_v2_scaling = {
  min_capacity = 0.5  # Мінімальна вартість
  max_capacity = 4    # Обмеження максимуму
}
```

## 🔍 Моніторинг та логування

### S3 Backend моніторинг

```hcl
# Увімкнення моніторингу
enable_cloudwatch_alarms = true
sns_topic_arn = "arn:aws:sns:region:account:topic"

# Логування доступу
enable_access_logging = true
```

Доступні алерти:
- DynamoDB read/write throttling
- Автоматичне масштабування
- Помилки доступу до S3

### CloudWatch Logs
```hcl
enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
```

### Enhanced Monitoring
```hcl
monitoring_interval = 60  # Детальний моніторинг кожну хвилину
```

### Performance Insights
```hcl
performance_insights_enabled = true
```

### EKS Monitoring
```bash
# Встановлення Prometheus та Grafana
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/kube-prometheus-stack

# Доступ до Grafana
kubectl port-forward svc/prometheus-grafana 3000:80
```

## 🚨 Усунення проблем

### S3 Backend проблеми

1. **Бакет вже існує**: Змініть назву бакета на унікальну
2. **Права доступу**: Переконайтеся, що у вас є права на створення S3 та DynamoDB
3. **Регіон**: Перевірте, що всі ресурси в одному регіоні
4. **State lock**: Якщо state заблокований, видаліть запис з DynamoDB

```bash
# Розблокування state
terraform force-unlock LOCK_ID

# Перевірка стану DynamoDB
aws dynamodb scan --table-name terraform-state-lock
```

### Поширені помилки

1. **Недостатньо підмереж**: Потрібно мінімум 2 підмережі в різних AZ
2. **Неправильний CIDR**: Перевірте, що CIDR блоки не перетинаються
3. **Версія движка**: Використовуйте підтримувані версії AWS
4. **EKS версія**: Перевірте сумісність версій Kubernetes та add-ons
5. **IAM права**: Переконайтеся, що у вас є необхідні права для створення EKS

### Корисні команди

```bash
# S3 Backend
# Перевірка бакета
aws s3 ls s3://your-terraform-state-bucket

# Перевірка DynamoDB
aws dynamodb describe-table --table-name terraform-state-lock

# Доступ до Jenkins
kubectl port-forward -n jenkins svc/jenkins-jenkins 8080:8080

# Перевірка конфігурації
kubectl get configmap -n jenkins
kubectl get secret -n jenkins

# Terraform
# Перевірка стану
terraform state list
terraform state show module.rds.aws_db_instance.main

# Імпорт існуючих ресурсів
terraform import module.rds.aws_db_instance.main mydb-instance

# Планування змін
terraform plan -target=module.rds

# EKS
# Перевірка кластера
kubectl cluster-info
kubectl get nodes -o wide

# Логи pod'ів
kubectl logs -f deployment/my-app

# Опис ресурсів
kubectl describe node <node-name>
kubectl describe pod <pod-name>
```

### Jenkins проблеми

### Argo CD проблеми

1. **Application не синхронізується**: Перевірте права доступу до Git репозиторію
2. **Server недоступний**: Перевірте Ingress та DNS налаштування
3. **Sync помилки**: Перевірте RBAC права та namespace існування
4. **Webhook не працює**: Перевірте firewall та SSL сертифікати

```bash
# Діагностика Argo CD
kubectl describe pod -n argocd -l app.kubernetes.io/name=argocd-server
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller --tail=100
kubectl get events -n argocd --sort-by='.lastTimestamp'

# Перевірка Applications
kubectl get applications -n argocd
kubectl describe application -n argocd my-app

# Перевірка AppProjects
kubectl get appprojects -n argocd
kubectl describe appproject -n argocd default

# Перевірка Ingress
kubectl get ingress -n argocd
kubectl describe ingress -n argocd
```

1. **Pod не запускається**: Перевірте ресурси та PVC
2. **Ingress не працює**: Перевірте Ingress Controller та DNS
3. **Плагіни не встановлюються**: Перевірте інтернет-доступ з кластера
4. **Агенти не підключаються**: Перевірте Service Account права

```bash
# Діагностика Jenkins
kubectl describe pod -n jenkins -l app.kubernetes.io/instance=jenkins
kubectl logs -n jenkins -l app.kubernetes.io/instance=jenkins --tail=100
kubectl get events -n jenkins --sort-by='.lastTimestamp'

# Перевірка PVC
kubectl get pvc -n jenkins
kubectl describe pvc -n jenkins jenkins-home-pvc

# Перевірка Ingress
kubectl get ingress -n jenkins
kubectl describe ingress -n jenkins
```

## 📚 Додаткові ресурси

- [AWS RDS Documentation](https://docs.aws.amazon.com/rds/)
- [AWS Aurora Documentation](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/)
- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [Jenkins Kubernetes Plugin](https://plugins.jenkins.io/kubernetes/)
- [Argo CD Documentation](https://argo-cd.readthedocs.io/)
- [Argo CD CLI Documentation](https://argo-cd.readthedocs.io/en/stable/cli_installation/)
- [GitOps Best Practices](https://www.weave.works/technologies/gitops/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [Helm Charts](https://helm.sh/docs/)

## 🤝 Внесок

1. Fork проєкту
2. Створіть feature branch (`git checkout -b feature/amazing-feature`)
3. Commit змін (`git commit -m 'Add amazing feature'`)
4. Push в branch (`git push origin feature/amazing-feature`)
5. Створіть Pull Request

## 📄 Ліцензія

Цей проєкт ліцензовано під MIT License - дивіться файл [LICENSE](LICENSE) для деталей.

---

**Автор**: DevOps Engineer  
**Проєкт**: Terraform Infrastructure Modules  
**Версія**: 1.0.0
