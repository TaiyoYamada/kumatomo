# =============================================================================
# RDS Subnet Group
# =============================================================================
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = [aws_subnet.public_a.id, aws_subnet.public_c.id]

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

# =============================================================================
# RDS MySQL Instance
# =============================================================================
resource "aws_db_instance" "main" {
  identifier = "${var.project_name}-mysql"

  # Engine
  engine                = "mysql"
  engine_version        = "8.0"
  instance_class        = "db.t3.micro" # Free Tier
  allocated_storage     = 20            # Free Tier: 20GB
  max_allocated_storage = 20            # Disable auto-scaling to stay in Free Tier

  # Database
  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  # Network
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = true # Required for Lambda VPC外 access

  # Availability
  multi_az = false # Single AZ for cost savings

  # Backup
  backup_retention_period = 1 # Minimum (1 day)
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"

  # Storage
  storage_type      = "gp2"
  storage_encrypted = true

  # Other
  skip_final_snapshot        = true # For dev simplicity (change for real prod)
  delete_automated_backups   = true
  auto_minor_version_upgrade = true

  tags = {
    Name = "${var.project_name}-mysql"
  }
}
