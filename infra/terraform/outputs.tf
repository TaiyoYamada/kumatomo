# =============================================================================
# RDS Outputs
# =============================================================================
output "rds_endpoint" {
  description = "RDS MySQL endpoint"
  value       = aws_db_instance.main.endpoint
}

output "rds_hostname" {
  description = "RDS MySQL hostname (without port)"
  value       = aws_db_instance.main.address
}

# =============================================================================
# S3 Outputs
# =============================================================================
output "s3_media_bucket" {
  description = "S3 media bucket name"
  value       = aws_s3_bucket.media.id
}

output "s3_admin_bucket" {
  description = "S3 admin static hosting bucket name"
  value       = aws_s3_bucket.admin.id
}

# =============================================================================
# CloudFront Outputs
# =============================================================================
output "cloudfront_domain" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.main.domain_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID (for cache invalidation)"
  value       = aws_cloudfront_distribution.main.id
}

# =============================================================================
# SSM Parameter Paths
# =============================================================================
output "ssm_parameter_prefix" {
  description = "SSM Parameter Store prefix for this environment"
  value       = "/${var.project_name}/${var.environment}"
}
