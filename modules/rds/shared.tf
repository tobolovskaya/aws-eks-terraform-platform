# Shared resources for RDS and Aurora

# Local values to work out parameters
locals {
  # Engine selection for Aurora
  aurora_engine = var.use_aurora ? (
    var.engine == "postgres" ? "aurora-postgresql" :
    var.engine == "mysql" ? "aurora-mysql" :
    var.engine
  ) : var.engine

  # Pick the port automatically
  default_port = var.port != null ? var.port : (
    contains(["postgres", "aurora-postgresql"], local.aurora_engine) ? 5432 :
    contains(["mysql", "aurora-mysql", "mariadb"], local.aurora_engine) ? 3306 :
    5432
  )

  # Pick the engine version automatically
  default_engine_version = var.engine_version != "" ? var.engine_version : (
    local.aurora_engine == "aurora-postgresql" ? "15.4" :
    local.aurora_engine == "aurora-mysql" ? "8.0.mysql_aurora.3.04.0" :
    local.aurora_engine == "postgres" ? "15.4" :
    local.aurora_engine == "mysql" ? "8.0.35" :
    local.aurora_engine == "mariadb" ? "10.11.5" :
    "15.4"
  )

  # Base parameters for each engine
  base_db_parameters = {
    postgres = {
      "rds.force_ssl" = {
        value        = "1"
        apply_method = "immediate"
      }
      "shared_preload_libraries" = {
        value        = "pg_stat_statements"
        apply_method = "pending-reboot"
      }
      "log_statement" = {
        value        = "ddl"
        apply_method = "immediate"
      }
      "log_min_duration_statement" = {
        value        = "1000"
        apply_method = "immediate"
      }
      "max_connections" = {
        value        = "100"
        apply_method = "pending-reboot"
      }
      "work_mem" = {
        value        = "4096"
        apply_method = "immediate"
      }
    }
    mysql = {
      "require_secure_transport" = {
        value        = "1"
        apply_method = "immediate"
      }
      "innodb_buffer_pool_size" = {
        value        = "{DBInstanceClassMemory*3/4}"
        apply_method = "pending-reboot"
      }
      "max_connections" = {
        value        = "100"
        apply_method = "immediate"
      }
      "slow_query_log" = {
        value        = "1"
        apply_method = "immediate"
      }
      "long_query_time" = {
        value        = "1"
        apply_method = "immediate"
      }
    }
    mariadb = {
      "require_secure_transport" = {
        value        = "1"
        apply_method = "immediate"
      }
      "innodb_buffer_pool_size" = {
        value        = "{DBInstanceClassMemory*3/4}"
        apply_method = "pending-reboot"
      }
      "max_connections" = {
        value        = "100"
        apply_method = "immediate"
      }
      "slow_query_log" = {
        value        = "1"
        apply_method = "immediate"
      }
      "long_query_time" = {
        value        = "1"
        apply_method = "immediate"
      }
    }
  }

  # Merge base and custom parameters
  final_db_parameters = merge(
    lookup(local.base_db_parameters, var.engine, {}),
    var.custom_db_parameters
  )

  # CloudWatch logs for each engine
  default_logs_exports = {
    postgres          = ["postgresql"]
    mysql             = ["error", "general", "slow-query"]
    mariadb           = ["error", "general", "slow-query"]
    aurora-postgresql = ["postgresql"]
    aurora-mysql      = ["error", "general", "slow-query"]
  }

  logs_exports = length(var.enabled_cloudwatch_logs_exports) > 0 ? var.enabled_cloudwatch_logs_exports : lookup(local.default_logs_exports, local.aurora_engine, [])
}

# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.tags.Project}-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, {
    Name = "${var.tags.Project}-db-subnet-group"
  })
}

# Security group for the database
resource "aws_security_group" "db" {
  name_prefix = "${var.tags.Project}-db-"
  description = "Database: inbound only from allowed sources, no outbound"
  vpc_id      = var.vpc_id

  # Inbound rules for CIDR blocks
  dynamic "ingress" {
    for_each = length(var.allowed_cidr_blocks) > 0 ? [1] : []
    content {
      description = "Database port from allowed CIDR blocks"
      from_port   = local.default_port
      to_port     = local.default_port
      protocol    = "tcp"
      cidr_blocks = var.allowed_cidr_blocks
    }
  }

  # Inbound rules for security groups
  dynamic "ingress" {
    for_each = var.allowed_security_groups
    content {
      description     = "Database port from allowed security groups"
      from_port       = local.default_port
      to_port         = local.default_port
      protocol        = "tcp"
      security_groups = [ingress.value]
    }
  }

  # No egress rules: the database only answers connections (security groups are stateful).
  # Terraform removes the default allow-all egress rule that AWS creates.

  tags = merge(var.tags, {
    Name = "${var.tags.Project}-db-security-group"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Parameter Group
resource "aws_db_parameter_group" "main" {
  count = var.use_aurora ? 0 : 1

  family = (local.aurora_engine == "postgres" ? "postgres15" :
    local.aurora_engine == "mysql" ? "mysql8.0" :
    local.aurora_engine == "mariadb" ? "mariadb10.11" :
  "postgres15")

  name = "${var.tags.Project}-db-params"

  dynamic "parameter" {
    for_each = local.final_db_parameters
    content {
      name         = parameter.key
      value        = parameter.value.value
      apply_method = parameter.value.apply_method
    }
  }

  tags = merge(var.tags, {
    Name = "${var.tags.Project}-db-parameter-group"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Cluster parameter group for Aurora
resource "aws_rds_cluster_parameter_group" "main" {
  count = var.use_aurora ? 1 : 0

  family = (local.aurora_engine == "aurora-postgresql" ? "aurora-postgresql15" :
    local.aurora_engine == "aurora-mysql" ? "aurora-mysql8.0" :
  "aurora-postgresql15")

  name = "${var.tags.Project}-cluster-params"

  dynamic "parameter" {
    for_each = local.final_db_parameters
    content {
      name         = parameter.key
      value        = parameter.value.value
      apply_method = parameter.value.apply_method
    }
  }

  tags = merge(var.tags, {
    Name = "${var.tags.Project}-cluster-parameter-group"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# IAM role for Enhanced Monitoring
resource "aws_iam_role" "rds_enhanced_monitoring" {
  count = var.monitoring_interval > 0 ? 1 : 0

  name = "${var.tags.Project}-rds-enhanced-monitoring"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  count = var.monitoring_interval > 0 ? 1 : 0

  role       = aws_iam_role.rds_enhanced_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}