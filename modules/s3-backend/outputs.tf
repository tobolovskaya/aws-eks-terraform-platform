# S3 and DynamoDB outputs

# S3 outputs
output "s3_bucket_id" {
  description = "S3 bucket ID"
  value       = aws_s3_bucket.terraform_state.id
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.terraform_state.arn
}

output "s3_bucket_domain_name" {
  description = "S3 bucket domain name"
  value       = aws_s3_bucket.terraform_state.bucket_domain_name
}

output "s3_bucket_regional_domain_name" {
  description = "S3 bucket regional domain name"
  value       = aws_s3_bucket.terraform_state.bucket_regional_domain_name
}

output "s3_bucket_region" {
  description = "S3 bucket region"
  value       = aws_s3_bucket.terraform_state.region
}

# DynamoDB outputs
output "dynamodb_table_id" {
  description = "DynamoDB table ID"
  value       = aws_dynamodb_table.terraform_state_lock.id
}

output "dynamodb_table_arn" {
  description = "DynamoDB table ARN"
  value       = aws_dynamodb_table.terraform_state_lock.arn
}

output "dynamodb_table_name" {
  description = "DynamoDB table name"
  value       = aws_dynamodb_table.terraform_state_lock.name
}

output "dynamodb_table_stream_arn" {
  description = "DynamoDB stream ARN (if enabled)"
  value       = aws_dynamodb_table.terraform_state_lock.stream_arn
}

# Backend configuration
output "terraform_backend_config" {
  description = "Configuration for the Terraform backend"
  value = {
    bucket         = aws_s3_bucket.terraform_state.id
    key            = "terraform/state"
    region         = aws_s3_bucket.terraform_state.region
    dynamodb_table = aws_dynamodb_table.terraform_state_lock.name
    encrypt        = true
  }
}

# Ready-to-copy backend block
output "backend_configuration" {
  description = "Ready backend configuration to paste into the terraform block"
  value       = <<-EOT
    terraform {
      backend "s3" {
        bucket         = "${aws_s3_bucket.terraform_state.id}"
        key            = "terraform/state"
        region         = "${aws_s3_bucket.terraform_state.region}"
        dynamodb_table = "${aws_dynamodb_table.terraform_state_lock.name}"
        encrypt        = true
      }
    }
  EOT
}

# Logging (if enabled)
output "access_logs_bucket_id" {
  description = "ID of the access log bucket"
  value       = var.enable_access_logging ? aws_s3_bucket.access_logs[0].id : null
}

# Auto Scaling outputs
output "autoscaling_read_target_arn" {
  description = "ARN of the read autoscaling target"
  value       = var.dynamodb_billing_mode == "PROVISIONED" && var.enable_dynamodb_autoscaling ? aws_appautoscaling_target.dynamodb_table_read_target[0].arn : null
}

output "autoscaling_write_target_arn" {
  description = "ARN of the write autoscaling target"
  value       = var.dynamodb_billing_mode == "PROVISIONED" && var.enable_dynamodb_autoscaling ? aws_appautoscaling_target.dynamodb_table_write_target[0].arn : null
}

# CloudWatch alarms
output "read_throttle_alarm_arn" {
  description = "ARN of the read throttle alarm"
  value       = var.enable_cloudwatch_alarms ? aws_cloudwatch_metric_alarm.dynamodb_read_throttle[0].arn : null
}

output "write_throttle_alarm_arn" {
  description = "ARN of the write throttle alarm"
  value       = var.enable_cloudwatch_alarms ? aws_cloudwatch_metric_alarm.dynamodb_write_throttle[0].arn : null
}