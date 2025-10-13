# File: providers.tf
terraform {
  required_providers {
    minio = {
      source  = "aminueza/minio"
      version = "~> 3.0.0"
    }
    sops = {
      source  = "carlpett/sops"
      version = "~> 1.0"
    }
  }
}
