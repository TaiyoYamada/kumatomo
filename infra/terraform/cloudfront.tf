# =============================================================================
# CloudFront Distribution (Static assets only - NOT API Gateway)
# =============================================================================
resource "aws_cloudfront_distribution" "main" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${var.project_name} CDN"
  default_root_object = "index.html"
  price_class         = "PriceClass_200" # Asia + Europe + North America

  # -----------------------------------------------------------------------------
  # Origin 1: Admin S3 Bucket
  # -----------------------------------------------------------------------------
  origin {
    domain_name              = aws_s3_bucket.admin.bucket_regional_domain_name
    origin_id                = "admin-s3"
    origin_access_control_id = aws_cloudfront_origin_access_control.admin.id
  }

  # -----------------------------------------------------------------------------
  # Origin 2: Media S3 Bucket
  # -----------------------------------------------------------------------------
  origin {
    domain_name              = aws_s3_bucket.media.bucket_regional_domain_name
    origin_id                = "media-s3"
    origin_access_control_id = aws_cloudfront_origin_access_control.media.id
  }

  # -----------------------------------------------------------------------------
  # Default behavior (Admin)
  # -----------------------------------------------------------------------------
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "admin-s3"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
  }

  # -----------------------------------------------------------------------------
  # Media path behavior
  # -----------------------------------------------------------------------------
  ordered_cache_behavior {
    path_pattern     = "/media/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "media-s3"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 604800 # 1 week
    compress               = true
  }

  # -----------------------------------------------------------------------------
  # Custom error responses for SPA
  # -----------------------------------------------------------------------------
  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }

  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  # -----------------------------------------------------------------------------
  # Restrictions
  # -----------------------------------------------------------------------------
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # -----------------------------------------------------------------------------
  # SSL Certificate (CloudFront default)
  # -----------------------------------------------------------------------------
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name = "${var.project_name}-cloudfront"
  }
}
