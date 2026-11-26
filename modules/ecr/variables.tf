# Variables for the ECR module

# Basic parameters
variable "repository_name" {
  description = "ECR repository name"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9](?:[a-z0-9._-]*[a-z0-9])?$", var.repository_name))
    error_message = "Repository name may only contain lowercase letters, digits, dots, hyphens and underscores."
  }
}

variable "image_tag_mutability" {
  description = "Image tag mutability (MUTABLE or IMMUTABLE)"
  type        = string
  default     = "IMMUTABLE"

  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "Image tag mutability must be MUTABLE or IMMUTABLE."
  }
}

# Scanning settings
variable "scan_on_push" {
  description = "Scan images on push"
  type        = bool
  default     = true
}

variable "enable_registry_scanning" {
  description = "Enable enhanced registry scanning"
  type        = bool
  default     = false
}

variable "registry_scan_type" {
  description = "Registry scan type (BASIC or ENHANCED)"
  type        = string
  default     = "BASIC"

  validation {
    condition     = contains(["BASIC", "ENHANCED"], var.registry_scan_type)
    error_message = "Registry scan type must be BASIC or ENHANCED."
  }
}

variable "registry_scan_filters" {
  description = "Filters for registry scanning"
  type = list(object({
    filter         = string
    filter_type    = string
    scan_frequency = string
  }))
  default = []
}

# Encryption
variable "encryption_type" {
  description = "Encryption type (AES256 or KMS)"
  type        = string
  default     = "KMS"

  validation {
    condition     = contains(["AES256", "KMS"], var.encryption_type)
    error_message = "Encryption type must be AES256 or KMS."
  }
}

variable "kms_key" {
  description = "KMS key ARN for encryption (KMS type only)"
  type        = string
  default     = null
}

# Lifecycle policy
variable "enable_lifecycle_policy" {
  description = "Enable lifecycle policy"
  type        = bool
  default     = true
}

variable "max_image_count" {
  description = "Maximum number of images to keep"
  type        = number
  default     = 10

  validation {
    condition     = var.max_image_count > 0 && var.max_image_count <= 1000
    error_message = "Maximum number of images must be between 1 and 1000."
  }
}

variable "untagged_image_days" {
  description = "Days to keep untagged images"
  type        = number
  default     = 1

  validation {
    condition     = var.untagged_image_days >= 1 && var.untagged_image_days <= 365
    error_message = "Number of days must be between 1 and 365."
  }
}

variable "lifecycle_tag_prefixes" {
  description = "Tag prefixes for the lifecycle policy"
  type        = list(string)
  default     = ["v", "release", "latest"]
}

# Cross-account access
variable "enable_cross_account_access" {
  description = "Enable cross-account access"
  type        = bool
  default     = false
}

variable "cross_account_arns" {
  description = "Account ARNs for cross-account access"
  type        = list(string)
  default     = []
}

# Replication
variable "replication_regions" {
  description = "Regions to replicate to"
  type = list(object({
    region      = string
    registry_id = string
  }))
  default = []
}

# Tags
variable "tags" {
  description = "Tags for resources"
  type        = map(string)
  default = {
    ManagedBy = "terraform"
    Module    = "ecr"
  }
}

# Extra settings