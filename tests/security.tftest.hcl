# Security regression tests.
#
# These tests run `terraform plan` against mocked providers, so they need
# no AWS account and cost nothing. They check that the hardening done in
# earlier pull requests stays in place: if someone flips a secure default,
# CI fails.
#
# Run locally: terraform init -backend=false && terraform test

mock_provider "aws" {
  mock_data "aws_availability_zones" {
    defaults = {
      names = ["eu-north-1a", "eu-north-1b"]
    }
  }
}

mock_provider "kubernetes" {}

mock_provider "tls" {
  mock_data "tls_certificate" {
    defaults = {
      certificates = [{ sha1_fingerprint = "0000000000000000000000000000000000000000" }]
    }
  }
}

variables {
  tags = {
    Project     = "test"
    Environment = "test"
  }
}

run "vpc_is_locked_down" {
  command = plan

  module {
    source = "./modules/vpc"
  }

  variables {
    vpc_cidr             = "10.0.0.0/16"
    availability_zones   = ["eu-north-1a", "eu-north-1b"]
    public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
    private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]
  }

  assert {
    condition     = length(aws_default_security_group.default.ingress) == 0 && length(aws_default_security_group.default.egress) == 0
    error_message = "The default security group must have no rules."
  }

  assert {
    condition     = aws_flow_log.main[0].traffic_type == "ALL"
    error_message = "VPC flow logs must capture all traffic."
  }

  assert {
    condition     = aws_cloudwatch_log_group.flow_logs[0].retention_in_days == 365
    error_message = "Flow logs must be kept for 365 days."
  }
}

run "eks_api_is_private_and_secrets_encrypted" {
  command = plan

  module {
    source = "./modules/eks"
  }

  variables {
    cluster_name = "test-cluster"
    vpc_id       = "vpc-12345678"
    subnet_ids   = ["subnet-11111111", "subnet-22222222"]
  }

  assert {
    condition     = aws_eks_cluster.main.vpc_config[0].endpoint_public_access == false
    error_message = "The Kubernetes API endpoint must not be public."
  }

  assert {
    condition     = contains(aws_eks_cluster.main.encryption_config[0].resources, "secrets")
    error_message = "Kubernetes secrets must be encrypted with KMS."
  }

  assert {
    condition     = aws_launch_template.node_group[0].metadata_options[0].http_tokens == "required"
    error_message = "Nodes must require IMDSv2."
  }

  assert {
    condition     = aws_launch_template.node_group[0].metadata_options[0].http_put_response_hop_limit == 1
    error_message = "IMDS hop limit must be 1 so pods cannot reach node credentials."
  }
}

run "rds_password_is_managed_by_aws" {
  command = plan

  module {
    source = "./modules/rds"
  }

  variables {
    vpc_id     = "vpc-12345678"
    subnet_ids = ["subnet-11111111", "subnet-22222222"]
  }

  assert {
    condition     = aws_db_instance.main[0].manage_master_user_password == true
    error_message = "The master password must be managed by Secrets Manager."
  }

  assert {
    condition     = aws_db_instance.main[0].storage_encrypted == true
    error_message = "Database storage must be encrypted."
  }

  assert {
    condition     = aws_db_instance.main[0].publicly_accessible == false
    error_message = "The database must not be reachable from the internet."
  }
}

run "ecr_tags_are_immutable_and_encrypted" {
  command = plan

  module {
    source = "./modules/ecr"
  }

  variables {
    repository_name = "test-app"
  }

  assert {
    condition     = aws_ecr_repository.main.image_tag_mutability == "IMMUTABLE"
    error_message = "Image tags must be immutable."
  }

  assert {
    condition     = aws_ecr_repository.main.encryption_configuration[0].encryption_type == "KMS"
    error_message = "Images must be encrypted with KMS."
  }
}
