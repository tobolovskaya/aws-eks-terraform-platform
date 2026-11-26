# Variables for the EKS module

# Basic cluster parameters
variable "cluster_name" {
  description = "EKS cluster name"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]*$", var.cluster_name))
    error_message = "Cluster name must start with a letter and contain only letters, digits and hyphens."
  }
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.35"

  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+$", var.kubernetes_version))
    error_message = "Kubernetes version must be in X.Y format (for example 1.35)."
  }
}

# Network parameters
variable "vpc_id" {
  description = "VPC ID for the EKS cluster"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the EKS cluster"
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "At least 2 subnets are required for the EKS cluster."
  }
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to reach the API server"
  type        = list(string)
  default     = []
}

# Endpoint settings
variable "endpoint_private_access" {
  description = "Enable private access to the API endpoint"
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Enable public access to the API endpoint"
  type        = bool
  default     = false
}

variable "endpoint_public_access_cidrs" {
  description = "CIDR blocks for public access to the API endpoint"
  type        = list(string)
  default     = []
}

# Logging
variable "cluster_log_types" {
  description = "Log types to enable in CloudWatch"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  validation {
    condition = alltrue([
      for log_type in var.cluster_log_types : contains([
        "api", "audit", "authenticator", "controllerManager", "scheduler"
      ], log_type)
    ])
    error_message = "Allowed log types: api, audit, authenticator, controllerManager, scheduler."
  }
}

# Encryption
variable "cluster_encryption_config_kms_key_id" {
  description = "ARN of an existing KMS key for EKS secrets encryption. Leave empty to create a new key."
  type        = string
  default     = ""
}

# Node groups configuration
variable "node_groups" {
  description = "Node groups configuration"
  type = list(object({
    name                       = string
    instance_types             = list(string)
    ami_type                   = string
    capacity_type              = string
    desired_size               = number
    max_size                   = number
    min_size                   = number
    max_unavailable_percentage = number
    disk_size                  = number
    disk_type                  = string
    subnet_ids                 = list(string)
    labels                     = map(string)
    taints = list(object({
      key    = string
      value  = string
      effect = string
    }))
  }))

  default = [
    {
      name                       = "main"
      instance_types             = ["t3.medium"]
      ami_type                   = "AL2023_x86_64_STANDARD"
      capacity_type              = "ON_DEMAND"
      desired_size               = 2
      max_size                   = 4
      min_size                   = 1
      max_unavailable_percentage = 25
      disk_size                  = 50
      disk_type                  = "gp3"
      subnet_ids                 = []
      labels                     = {}
      taints                     = []
    }
  ]

  validation {
    condition = alltrue([
      for ng in var.node_groups : ng.min_size <= ng.desired_size && ng.desired_size <= ng.max_size
    ])
    error_message = "For each node group: min_size <= desired_size <= max_size."
  }

  validation {
    condition = alltrue([
      for ng in var.node_groups : contains([
        "AL2023_x86_64_STANDARD", "AL2023_ARM_64_STANDARD", "AL2023_x86_64_NVIDIA", "CUSTOM", "BOTTLEROCKET_ARM_64", "BOTTLEROCKET_x86_64"
      ], ng.ami_type)
    ])
    error_message = "AMI type must be one of the supported types."
  }

  validation {
    condition = alltrue([
      for ng in var.node_groups : contains(["ON_DEMAND", "SPOT"], ng.capacity_type)
    ])
    error_message = "Capacity type must be ON_DEMAND or SPOT."
  }
}

# EBS CSI Driver settings
variable "enable_ebs_csi_driver" {
  description = "Enable the AWS EBS CSI Driver"
  type        = bool
  default     = true
}

variable "ebs_csi_driver_version" {
  description = "EBS CSI Driver add-on version"
  type        = string
  default     = null
}

variable "ebs_csi_kms_key_id" {
  description = "KMS key ARN to encrypt EBS volumes"
  type        = string
  default     = ""
}

variable "create_storage_classes" {
  description = "Create storage classes for the EBS CSI Driver"
  type        = bool
  default     = true
}

variable "set_gp3_as_default_storage_class" {
  description = "Make gp3 the default storage class"
  type        = bool
  default     = true
}

variable "remove_default_gp2_storage_class" {
  description = "Remove the default annotation from the gp2 storage class"
  type        = bool
  default     = true
}

# Extra add-ons
variable "enable_vpc_cni_addon" {
  description = "Enable the VPC CNI add-on"
  type        = bool
  default     = true
}

variable "vpc_cni_addon_version" {
  description = "VPC CNI add-on version"
  type        = string
  default     = null
}

variable "enable_coredns_addon" {
  description = "Enable the CoreDNS add-on"
  type        = bool
  default     = true
}

variable "coredns_addon_version" {
  description = "CoreDNS add-on version"
  type        = string
  default     = null
}

variable "enable_kube_proxy_addon" {
  description = "Enable the kube-proxy add-on"
  type        = bool
  default     = true
}

variable "kube_proxy_addon_version" {
  description = "kube-proxy add-on version"
  type        = string
  default     = null
}

# Tags
variable "tags" {
  description = "Tags for resources"
  type        = map(string)
  default = {
    ManagedBy = "terraform"
    Module    = "eks"
  }
}