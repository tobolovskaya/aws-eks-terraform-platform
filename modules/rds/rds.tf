# Create a regular RDS database

resource "aws_db_instance" "main" {
  #checkov:skip=CKV_AWS_157: Multi-AZ doubles the cost; lab default is single-AZ, set multi_az = true for production
  #checkov:skip=CKV_AWS_354: Performance Insights is off by default; when enabled it uses the AWS-managed KMS key
  #checkov:skip=CKV2_AWS_69: TLS is enforced in the parameter group (rds.force_ssl / require_secure_transport, modules/rds/shared.tf). Checkov cannot resolve the dynamic parameter block.
  count = var.use_aurora ? 0 : 1

  # Basic parameters
  identifier     = "${var.tags.Project}-db"
  engine         = local.aurora_engine
  engine_version = local.default_engine_version
  instance_class = var.instance_class

  # Database
  db_name  = var.database_name
  username = var.username
  # Password lives in Secrets Manager, managed and rotated by RDS
  manage_master_user_password = true
  port     = local.default_port

  # Storage
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = var.storage_type
  storage_encrypted     = var.storage_encrypted

  # Network and security
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db.id]
  publicly_accessible    = var.publicly_accessible

  # Availability
  multi_az          = var.multi_az
  availability_zone = var.multi_az ? null : data.aws_availability_zones.available.names[0]

  # Parameters
  parameter_group_name = aws_db_parameter_group.main[0].name

  # Backups and maintenance
  backup_retention_period   = var.backup_retention_period
  backup_window             = var.backup_window
  maintenance_window        = var.maintenance_window
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.tags.Project}-db-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  # Protection
  deletion_protection   = var.deletion_protection
  copy_tags_to_snapshot = true

  # Monitoring
  monitoring_interval = var.monitoring_interval
  monitoring_role_arn = var.monitoring_interval > 0 ? aws_iam_role.rds_enhanced_monitoring[0].arn : null

  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_enabled ? 7 : null

  # Logs
  enabled_cloudwatch_logs_exports = local.logs_exports

  # Automatic upgrades
  auto_minor_version_upgrade  = true
  allow_major_version_upgrade = false

  tags = merge(var.tags, {
    Name = "${var.tags.Project}-database"
  })

  lifecycle {
    ignore_changes = [
      password,
      final_snapshot_identifier
    ]
  }

  depends_on = [
    aws_db_subnet_group.main,
    aws_security_group.db,
    aws_db_parameter_group.main
  ]
}

# Available availability zones
data "aws_availability_zones" "available" {
  #checkov:skip=CKV_AWS_394: only used to pick one AZ for a single-AZ lab database
  state = "available"
}