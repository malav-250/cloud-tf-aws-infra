# rds.tf - RDS PostgreSQL Database Configuration

# ============================================================================
# DB SUBNET GROUP
# ============================================================================
# RDS requires a DB subnet group with subnets in at least 2 AZs
resource "aws_db_subnet_group" "webapp" {
  name        = "${var.vpc_name}-db-subnet-group"
  description = "Database subnet group for ${var.vpc_name}"
  subnet_ids  = aws_subnet.private[*].id

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.vpc_name}-db-subnet-group"
      Environment = var.environment
    }
  )
}

# ============================================================================
# RDS SECURITY GROUP
# ============================================================================
resource "aws_security_group" "rds" {
  name        = "${var.vpc_name}-rds-sg"
  description = "Security group for RDS database - allows access from application instances"
  vpc_id      = aws_vpc.main.id

  # Ingress rule: Allow PostgreSQL access from application security group
  ingress {
    description     = "PostgreSQL from application instances"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.application.id]
  }

  # Egress rule: Allow all outbound traffic (for updates, backups, etc.)
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.vpc_name}-rds-sg"
      Environment = var.environment
    }
  )
}

# ============================================================================
# RDS PARAMETER GROUP (Optional - for customization)
# ============================================================================
resource "aws_db_parameter_group" "webapp" {
  name        = "${var.vpc_name}-postgres-params"
  family      = "postgres16"
  description = "Custom parameter group for ${var.vpc_name} PostgreSQL"

  # Example parameters - adjust as needed
  parameter {
    name  = "log_connections"
    value = "1"
  }

  parameter {
    name  = "log_disconnections"
    value = "1"
  }

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.vpc_name}-postgres-params"
      Environment = var.environment
    }
  )
}

# ============================================================================
# RDS INSTANCE
# ============================================================================
resource "aws_db_instance" "webapp_db" {
  # Instance identification
  identifier = "csye6225"

  # Engine configuration
  engine               = "postgres"
  engine_version       = var.db_engine_version
  instance_class       = var.db_instance_class
  parameter_group_name = aws_db_parameter_group.webapp.name

  # Database configuration
  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  # Storage configuration
  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  storage_type          = var.db_storage_type
  storage_encrypted     = true

  # Network configuration
  db_subnet_group_name   = aws_db_subnet_group.webapp.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false

  # High Availability and Backup
  multi_az                = var.db_multi_az
  backup_retention_period = var.db_backup_retention_period
  backup_window           = var.db_backup_window
  maintenance_window      = var.db_maintenance_window

  # Deletion protection
  deletion_protection       = var.db_deletion_protection
  skip_final_snapshot       = var.environment == "dev" ? true : false
  final_snapshot_identifier = var.environment == "dev" ? null : "${var.vpc_name}-db-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  # Performance Insights (optional)
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  # Auto minor version upgrade
  auto_minor_version_upgrade = true

  # Apply changes immediately in dev, during maintenance window in prod
  apply_immediately = var.environment == "dev" ? true : false

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.vpc_name}-db-instance"
      Environment = var.environment
    }
  )

  # Lifecycle to prevent accidental deletion
  lifecycle {
    prevent_destroy = false # Set to true in production
  }

  # Depends on subnet group and security group
  depends_on = [
    aws_db_subnet_group.webapp,
    aws_security_group.rds
  ]
}