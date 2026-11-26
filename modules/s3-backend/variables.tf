# Variables for the s3-backend module

# Basic parameters
variable "bucket_name" {
  description = "S3 bucket name for Terraform state"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.bucket_name))
    error_message = "Bucket name may only contain lowercase letters, digits and hyphens, and must start and end with a letter or digit."
  }
}

variable "dynamodb_table_name" {
  description = "DynamoDB table name for state locking"
  type        = string
  default     = "terraform-state-lock"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

# S3 settings
variable "state_retention_days" {
  description = "Days to keep old state versions"
  type        = number
  default     = 90

  validation {
    condition     = var.state_retention_days >= 1 && var.state_retention_days <= 365
    error_message = "Retention period must be between 1 and 365 days."
  }
}

variable "enable_access_logging" {
  description = "Enable access logging for the S3 bucket"
  type        = bool
  default     = false
}

# DynamoDB settings
variable "dynamodb_billing_mode" {
  description = "DynamoDB billing mode (PAY_PER_REQUEST or PROVISIONED)"
  type        = string
  default     = "PAY_PER_REQUEST"

  validation {
    condition     = contains(["PAY_PER_REQUEST", "PROVISIONED"], var.dynamodb_billing_mode)
    error_message = "Billing mode must be PAY_PER_REQUEST or PROVISIONED."
  }
}

variable "dynamodb_read_capacity" {
  description = "DynamoDB read capacity units (PROVISIONED mode only)"
  type        = number
  default     = 5

  validation {
    condition     = var.dynamodb_read_capacity >= 1
    error_message = "Read capacity must be at least 1."
  }
}

variable "dynamodb_write_capacity" {
  description = "DynamoDB write capacity units (PROVISIONED mode only)"
  type        = number
  default     = 5

  validation {
    condition     = var.dynamodb_write_capacity >= 1
    error_message = "Write capacity must be at least 1."
  }
}

variable "enable_point_in_time_recovery" {
  description = "Enable Point-in-Time Recovery for DynamoDB"
  type        = bool
  default     = true
}

# Auto Scaling settings
variable "enable_dynamodb_autoscaling" {
  description = "Enable autoscaling for DynamoDB (PROVISIONED mode only)"
  type        = bool
  default     = true
}

variable "dynamodb_autoscaling_read_max_capacity" {
  description = "Maximum read capacity for autoscaling"
  type        = number
  default     = 100
}

variable "dynamodb_autoscaling_write_max_capacity" {
  description = "Maximum write capacity for autoscaling"
  type        = number
  default     = 100
}

variable "dynamodb_autoscaling_target_value" {
  description = "Target utilization for autoscaling (%)"
  type        = number
  default     = 70

  validation {
    condition     = var.dynamodb_autoscaling_target_value >= 10 && var.dynamodb_autoscaling_target_value <= 90
    error_message = "Target value must be between 10% and 90%."
  }
}

# Monitoring
variable "enable_cloudwatch_alarms" {
  description = "Enable CloudWatch alarms"
  type        = bool
  default     = false
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for alarms"
  type        = string
  default     = ""
}

# Tags
variable "tags" {
  description = "Tags for resources"
  type        = map(string)
  default = {
    ManagedBy = "terraform"
    Module    = "s3-backend"
  }
}
variable "access_logs_retention_days" {
  description = "How long to keep S3 access logs (days)"
  type        = number
  default     = 365
}
