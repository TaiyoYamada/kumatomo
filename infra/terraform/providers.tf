provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "kumatomo"
      Environment = "prod"
      ManagedBy   = "terraform"
    }
  }
}
