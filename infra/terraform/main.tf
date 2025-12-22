# kumatomo Infrastructure - Terraform

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  # tfstate はローカル保存（backend 未設定 = ローカル）
}
