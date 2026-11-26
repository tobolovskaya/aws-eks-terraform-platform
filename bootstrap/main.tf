# File for the initial S3 backend setup
# Use this file to create the S3 and DynamoDB resources
# After they are created, move the configuration into backend.tf

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

# Module that creates the S3 backend
module "s3_backend" {
  source = "../modules/s3-backend"

  # Basic parameters
  bucket_name         = var.backend_bucket_name
  dynamodb_table_name = var.backend_dynamodb_table_name
  environment         = var.environment

  # S3 settings
  state_retention_days  = var.state_retention_days
  enable_access_logging = var.enable_access_logging

  # DynamoDB settings
  dynamodb_billing_mode                   = var.dynamodb_billing_mode
  dynamodb_read_capacity                  = var.dynamodb_read_capacity
  dynamodb_write_capacity                 = var.dynamodb_write_capacity
  enable_point_in_time_recovery           = var.enable_point_in_time_recovery
  enable_dynamodb_autoscaling             = var.enable_dynamodb_autoscaling
  dynamodb_autoscaling_read_max_capacity  = var.dynamodb_autoscaling_read_max_capacity
  dynamodb_autoscaling_write_max_capacity = var.dynamodb_autoscaling_write_max_capacity
  dynamodb_autoscaling_target_value       = var.dynamodb_autoscaling_target_value

  # Monitoring
  enable_cloudwatch_alarms = var.enable_cloudwatch_alarms
  sns_topic_arn            = var.sns_topic_arn

  # Tags
  tags = var.backend_tags
}

# Backend setup variables
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "backend_bucket_name" {
  description = "S3 bucket name for Terraform state"
  type        = string
}

variable "backend_dynamodb_table_name" {
  description = "DynamoDB table name for state locking"
  type        = string
  default     = "terraform-state-lock"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "state_retention_days" {
  description = "Days to keep old state versions"
  type        = number
  default     = 90
}

variable "enable_access_logging" {
  description = "Enable access logging for S3"
  type        = bool
  default     = false
}

variable "dynamodb_billing_mode" {
  description = "DynamoDB billing mode"
  type        = string
  default     = "PAY_PER_REQUEST"
}

variable "dynamodb_read_capacity" {
  description = "DynamoDB read capacity (PROVISIONED mode)"
  type        = number
  default     = 5
}

variable "dynamodb_write_capacity" {
  description = "DynamoDB write capacity (PROVISIONED mode)"
  type        = number
  default     = 5
}

variable "enable_point_in_time_recovery" {
  description = "Enable Point-in-Time Recovery"
  type        = bool
  default     = true
}

variable "enable_dynamodb_autoscaling" {
  description = "Enable autoscaling for DynamoDB"
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
  description = "Target utilization for autoscaling"
  type        = number
  default     = 70
}

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

variable "backend_tags" {
  description = "Tags for backend resources"
  type        = map(string)
  default = {
    ManagedBy = "terraform"
    Purpose   = "terraform-backend"
  }
}

# Outputs
output "s3_bucket_name" {
  description = "S3 bucket name"
  value       = module.s3_backend.s3_bucket_id
}

output "dynamodb_table_name" {
  description = "DynamoDB table name"
  value       = module.s3_backend.dynamodb_table_name
}

output "backend_configuration" {
  description = "Ready-to-copy backend configuration"
  value       = module.s3_backend.backend_configuration
}