# Backend S3 parcial: bucket/key/region se entregan con -backend-config
# desde el workflow (patrón del laboratorio EA2, tfstate persistente).
terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  backend "s3" {}
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "AutomovilTech-EFT"
      Environment = "produccion"
      Owner       = "mdelrio"
      ManagedBy   = "terraform"
    }
  }
}
