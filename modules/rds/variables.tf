# Variables for the RDS module

# Basic parameters
variable "use_aurora" {
  description = "Use an Aurora cluster instead of a regular RDS instance"
  type        = bool
  default     = false
}

variable "engine" {
  description = "Database engine (postgres, mysql, mariadb)"
  type        = string
  default     = "postgres"

  validation {
    condition = contains([
      "postgres", "mysql", "mariadb",
      "aurora-postgresql", "aurora-mysql"
    ], var.engine)
    error_message = "Engine must be one of: postgres, mysql, mariadb, aurora-postgresql, aurora-mysql."
  }
}

variable "engine_version" {
  description = "Database engine version"
  type        = string
  default     = ""
}

variable "instance_class" {
  description = "Database instance class"
  type        = string
  default     = "db.t3.micro"
}

# Network parameters
variable "vpc_id" {
  description = "ID VPC"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the DB subnet group"
  type        = list(string)
  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "At least 2 subnets are required for the DB subnet group."
  }
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to connect to the database"
  type        = list(string)
  default     = []
}

variable "allowed_security_groups" {
  description = "Security groups allowed to connect to the database"
  type        = list(string)
  default     = []
}

# Database parameters
variable "database_name" {
  description = "Database name"
  type        = string
  default     = "myapp"
}

variable "username" {
  description = "Master database user"
  type        = string
  default     = "dbadmin"
}

variable "password" {
  description = "Master user password"
  type        = string
  sensitive   = true
}

variable "port" {
  description = "Database port (picked from the engine if not set)"
  type        = number
  default     = null
}

# Performance and availability settings
variable "allocated_storage" {
  description = "Storage size in GB (RDS only)"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Maximum storage size for autoscaling (RDS only)"
  type        = number
  default     = 100
}

variable "storage_type" {
  description = "Storage type (gp2, gp3, io1)"
  type        = string
  default     = "gp3"
}

variable "storage_encrypted" {
  description = "Encrypt storage"
  type        = bool
  default     = true
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment"
  type        = bool
  default     = false
}

variable "publicly_accessible" {
  description = "Whether the database is reachable from the internet"
  type        = bool
  default     = false
}

# Backup and maintenance settings
variable "backup_retention_period" {
  description = "Backup retention period in days"
  type        = number
  default     = 7

  validation {
    condition     = var.backup_retention_period >= 0 && var.backup_retention_period <= 35
    error_message = "Backup retention must be between 0 and 35 days."
  }
}

variable "backup_window" {
  description = "Backup window (UTC)"
  type        = string
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  description = "Maintenance window (UTC)"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

variable "skip_final_snapshot" {
  description = "Skip the final snapshot on deletion"
  type        = bool
  default     = false
}

variable "deletion_protection" {
  description = "Deletion protection"
  type        = bool
  default     = true
}

# Monitoring and logging
variable "monitoring_interval" {
  description = "Monitoring interval in seconds (0, 1, 5, 10, 15, 30, 60)"
  type        = number
  default     = 60

  validation {
    condition     = contains([0, 1, 5, 10, 15, 30, 60], var.monitoring_interval)
    error_message = "Monitoring interval must be one of: 0, 1, 5, 10, 15, 30, 60."
  }
}

variable "performance_insights_enabled" {
  description = "Enable Performance Insights"
  type        = bool
  default     = true
}

variable "enabled_cloudwatch_logs_exports" {
  description = "Log types to export to CloudWatch"
  type        = list(string)
  default     = []
}

# Aurora-specific parameters
variable "aurora_cluster_instances" {
  description = "Number of instances in the Aurora cluster"
  type        = number
  default     = 2

  validation {
    condition     = var.aurora_cluster_instances >= 1 && var.aurora_cluster_instances <= 15
    error_message = "Number of instances must be between 1 and 15."
  }
}

variable "aurora_serverless_v2" {
  description = "Use Aurora Serverless v2"
  type        = bool
  default     = false
}

variable "aurora_serverless_v2_scaling" {
  description = "Scaling settings for Aurora Serverless v2"
  type = object({
    max_capacity = number
    min_capacity = number
  })
  default = {
    max_capacity = 1
    min_capacity = 0.5
  }
}

# Custom database parameters
variable "custom_db_parameters" {
  description = "Custom parameters for the parameter group"
  type = map(object({
    value        = string
    apply_method = string
  }))
  default = {}
}

# Tags
variable "tags" {
  description = "Tags for resources"
  type        = map(string)
  default     = {}
}