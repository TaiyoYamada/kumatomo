# =============================================================================
# General
# =============================================================================
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-1"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "kumatomo"
}

variable "environment" {
  description = "Environment (prod only for now)"
  type        = string
  default     = "prod"
}

# =============================================================================
# Network / Security
# =============================================================================
variable "my_ip" {
  description = "Your home IP address for RDS security group (CIDR format, e.g., 1.2.3.4/32)"
  type        = string
  # デプロイ時に指定必須
}

# =============================================================================
# RDS
# =============================================================================
variable "db_name" {
  description = "Database name"
  type        = string
  default     = "kumatomo"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "kumatomo_admin"
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
  # デプロイ時に指定必須
}
