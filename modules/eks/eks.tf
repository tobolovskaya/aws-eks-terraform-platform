# Create the EKS cluster and node groups

# Current region and caller identity
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# IAM role for the EKS cluster
resource "aws_iam_role" "cluster" {
  name = "${var.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Attach policies to the cluster role
resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.cluster.name
}

# Security group for the EKS cluster
resource "aws_security_group" "cluster" {
  #checkov:skip=CKV_AWS_382: control plane needs outbound HTTPS to AWS APIs; traffic leaves via NAT, no inbound from internet
  name_prefix = "${var.cluster_name}-cluster-"
  description = "EKS control plane security group"
  vpc_id      = var.vpc_id

  # Outbound traffic
  egress {
    description = "Outbound traffic to AWS APIs, ECR and the internet via NAT"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-cluster-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Extra rules for the cluster security group
resource "aws_security_group_rule" "cluster_ingress_workstation_https" {
  count = length(var.allowed_cidr_blocks) > 0 ? 1 : 0

  cidr_blocks       = var.allowed_cidr_blocks
  description       = "Allow workstation to communicate with the cluster API Server"
  from_port         = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.cluster.id
  to_port           = 443
  type              = "ingress"
}

# EKS cluster
resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster.arn
  version  = var.kubernetes_version

  vpc_config {
    security_group_ids      = [aws_security_group.cluster.id]
    subnet_ids              = var.subnet_ids
    endpoint_private_access = var.endpoint_private_access
    endpoint_public_access  = var.endpoint_public_access
    public_access_cidrs     = var.endpoint_public_access ? var.endpoint_public_access_cidrs : null
  }

  # Enable logging
  enabled_cluster_log_types = var.cluster_log_types

  # Secrets encryption
  encryption_config {
    provider {
      key_arn = local.create_kms_key ? aws_kms_key.eks_secrets[0].arn : var.cluster_encryption_config_kms_key_id
    }
    resources = ["secrets"]
  }

  tags = var.tags

  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.cluster_AmazonEKSVPCResourceController,
  ]
}

# IAM role for node groups
resource "aws_iam_role" "node_group" {
  name = "${var.cluster_name}-node-group-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Attach policies to the node group role
resource "aws_iam_role_policy_attachment" "node_group_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "node_group_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "node_group_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node_group.name
}

# EBS CSI Driver gets its own IAM role via IRSA (aws_ebs_csi_driver.tf),
# so the node role does not need AmazonEBSCSIDriverPolicy (least privilege).

# Launch template for node groups
resource "aws_launch_template" "node_group" {
  count = length(var.node_groups)

  name_prefix = "${var.cluster_name}-${var.node_groups[count.index].name}-"

  vpc_security_group_ids = [aws_security_group.node_group.id]

  # Block device settings
  dynamic "block_device_mappings" {
    for_each = var.node_groups[count.index].disk_size > 0 ? [1] : []
    content {
      device_name = "/dev/xvda"
      ebs {
        volume_size           = var.node_groups[count.index].disk_size
        volume_type           = var.node_groups[count.index].disk_type
        encrypted             = true
        delete_on_termination = true
      }
    }
  }

  # Instance metadata
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1 # pods cannot reach IMDS and steal node credentials
  }

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

# Security group for node groups
resource "aws_security_group" "node_group" {
  #checkov:skip=CKV_AWS_382: nodes pull images and call AWS APIs via NAT; VPC endpoints for every service would replace this but cost more
  name_prefix = "${var.cluster_name}-node-group-"
  description = "EKS worker nodes security group"
  vpc_id      = var.vpc_id

  # Outbound traffic
  egress {
    description = "Outbound traffic to AWS APIs, ECR and the internet via NAT"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-node-group-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Rules for the node group security group
resource "aws_security_group_rule" "node_group_ingress_self" {
  description              = "Allow node to communicate with each other"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.node_group.id
  source_security_group_id = aws_security_group.node_group.id
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "node_group_ingress_cluster" {
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  from_port                = 1025
  protocol                 = "tcp"
  security_group_id        = aws_security_group.node_group.id
  source_security_group_id = aws_security_group.cluster.id
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "cluster_ingress_node_https" {
  description              = "Allow pods to communicate with the cluster API Server"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.cluster.id
  source_security_group_id = aws_security_group.node_group.id
  to_port                  = 443
  type                     = "ingress"
}

# EKS Node Groups
resource "aws_eks_node_group" "main" {
  count = length(var.node_groups)

  cluster_name    = aws_eks_cluster.main.name
  node_group_name = var.node_groups[count.index].name
  node_role_arn   = aws_iam_role.node_group.arn
  # Empty list in the node group config means: use the cluster subnets
  subnet_ids = length(var.node_groups[count.index].subnet_ids) > 0 ? var.node_groups[count.index].subnet_ids : var.subnet_ids

  # Instance settings
  instance_types = var.node_groups[count.index].instance_types
  ami_type       = var.node_groups[count.index].ami_type
  capacity_type  = var.node_groups[count.index].capacity_type

  # Scaling
  scaling_config {
    desired_size = var.node_groups[count.index].desired_size
    max_size     = var.node_groups[count.index].max_size
    min_size     = var.node_groups[count.index].min_size
  }

  # Update settings
  update_config {
    max_unavailable_percentage = var.node_groups[count.index].max_unavailable_percentage
  }

  # Launch template
  launch_template {
    id      = aws_launch_template.node_group[count.index].id
    version = aws_launch_template.node_group[count.index].latest_version
  }

  # Taints
  dynamic "taint" {
    for_each = var.node_groups[count.index].taints
    content {
      key    = taint.value.key
      value  = taint.value.value
      effect = taint.value.effect
    }
  }

  # Labels
  labels = var.node_groups[count.index].labels

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-${var.node_groups[count.index].name}"
  })

  depends_on = [
    aws_iam_role_policy_attachment.node_group_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_group_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node_group_AmazonEC2ContainerRegistryReadOnly,
  ]

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}

# OIDC identity provider for EKS
data "tls_certificate" "cluster" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "cluster" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.cluster.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer

  tags = var.tags
}