# Providers for the Argo CD module

terraform {
  required_version = ">= 1.0"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
  }
}

# Kubernetes provider
# Configuration must be passed in from the root module
# provider "kubernetes" {
#   host                   = var.cluster_endpoint
#   cluster_ca_certificate = base64decode(var.cluster_ca_certificate)
#   token                  = var.cluster_token
# 
#   # Or use AWS EKS
#   exec {
#     api_version = "client.authentication.k8s.io/v1beta1"
#     command     = "aws"
#     args = [
#       "eks",
#       "get-token",
#       "--cluster-name",
#       var.cluster_name,
#       "--region",
#       var.aws_region
#     ]
#   }
# }

# Helm provider
# Configuration must be passed in from the root module
# provider "helm" {
#   kubernetes {
#     host                   = var.cluster_endpoint
#     cluster_ca_certificate = base64decode(var.cluster_ca_certificate)
#     token                  = var.cluster_token
# 
#     # Or use AWS EKS
#     exec {
#       api_version = "client.authentication.k8s.io/v1beta1"
#       command     = "aws"
#       args = [
#         "eks",
#         "get-token",
#         "--cluster-name",
#         var.cluster_name,
#         "--region",
#         var.aws_region
#       ]
#     }
#   }
# }