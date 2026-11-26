# RDS module outputs

# General outputs
output "endpoint" {
  description = "Database endpoint"
  value = var.use_aurora ? (
    length(aws_rds_cluster.main) > 0 ? aws_rds_cluster.main[0].endpoint : null
    ) : (
    length(aws_db_instance.main) > 0 ? aws_db_instance.main[0].endpoint : null
  )
}

output "reader_endpoint" {
  description = "Reader endpoint (Aurora only)"
  value       = var.use_aurora && length(aws_rds_cluster.main) > 0 ? aws_rds_cluster.main[0].reader_endpoint : null
}

output "port" {
  description = "Database port"
  value       = local.default_port
}

output "database_name" {
  description = "Database name"
  value       = var.database_name
}

output "username" {
  description = "Database username"
  value       = var.username
  sensitive   = true
}

# Resource identifiers
output "db_instance_id" {
  description = "RDS instance ID (if RDS is used)"
  value = var.use_aurora ? null : (
    length(aws_db_instance.main) > 0 ? aws_db_instance.main[0].id : null
  )
}

output "cluster_id" {
  description = "Aurora cluster ID (if Aurora is used)"
  value       = var.use_aurora && length(aws_rds_cluster.main) > 0 ? aws_rds_cluster.main[0].id : null
}

output "cluster_resource_id" {
  description = "Aurora cluster resource ID (if Aurora is used)"
  value       = var.use_aurora && length(aws_rds_cluster.main) > 0 ? aws_rds_cluster.main[0].cluster_resource_id : null
}

output "cluster_members" {
  description = "Aurora cluster members"
  value       = var.use_aurora && length(aws_rds_cluster.main) > 0 ? aws_rds_cluster.main[0].cluster_members : []
}

# Network resources
output "security_group_id" {
  description = "Database security group ID"
  value       = aws_security_group.db.id
}

output "subnet_group_name" {
  description = "DB subnet group name"
  value       = aws_db_subnet_group.main.name
}

# Parameter Groups
output "parameter_group_name" {
  description = "Parameter group name"
  value = var.use_aurora ? (
    length(aws_rds_cluster_parameter_group.main) > 0 ? aws_rds_cluster_parameter_group.main[0].name : null
    ) : (
    length(aws_db_parameter_group.main) > 0 ? aws_db_parameter_group.main[0].name : null
  )
}

# Engine information
output "engine" {
  description = "Database engine"
  value       = local.aurora_engine
}

output "engine_version" {
  description = "Database engine version"
  value       = local.default_engine_version
}

# Status and availability
output "availability_zone" {
  description = "Availability zone (RDS only)"
  value = var.use_aurora ? null : (
    length(aws_db_instance.main) > 0 ? aws_db_instance.main[0].availability_zone : null
  )
}

output "multi_az" {
  description = "Whether Multi-AZ is enabled"
  value       = var.use_aurora ? true : var.multi_az
}

# Monitoring
output "monitoring_role_arn" {
  description = "ARN of the Enhanced Monitoring role"
  value       = var.monitoring_interval > 0 ? aws_iam_role.rds_enhanced_monitoring[0].arn : null
}

# Connection
output "connection_string" {
  description = "Database connection string"
  value = var.use_aurora ? (
    length(aws_rds_cluster.main) > 0 ?
    "postgresql://${var.username}:${var.password}@${aws_rds_cluster.main[0].endpoint}:${local.default_port}/${var.database_name}" : null
    ) : (
    length(aws_db_instance.main) > 0 ?
    "${local.aurora_engine}://${var.username}:${var.password}@${aws_db_instance.main[0].endpoint}:${local.default_port}/${var.database_name}" : null
  )
  sensitive = true
}