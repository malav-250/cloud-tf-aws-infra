# secrets.tf - AWS Secrets Manager Configuration
# Assignment 9 Phase 3 - Store sensitive credentials securely

# ============================================================================
# SECRET FOR RDS DATABASE PASSWORD
# ============================================================================

# Create a secret to store RDS database password
resource "aws_secretsmanager_secret" "db_password" {
  name        = "csye6225-db-password-${var.environment}"
  description = "RDS PostgreSQL database password for ${var.environment} environment"

  # Encrypt with KMS key
  kms_key_id = aws_kms_key.secrets.key_id

  # Recovery window (7-30 days) - time to recover if accidentally deleted
  recovery_window_in_days = 0

  tags = merge(
    var.common_tags,
    {
      Name        = "csye6225-db-password-${var.environment}"
      Environment = var.environment
      Purpose     = "RDS Database Credentials"
    }
  )
}

# Store the actual password value
resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id = aws_secretsmanager_secret.db_password.id

  # Store as JSON for easy parsing
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db_password.result
    engine   = "postgres"
    host     = aws_db_instance.webapp_db.address
    port     = aws_db_instance.webapp_db.port
    dbname   = var.db_name
  })
}

# ============================================================================
# SECRET FOR SENDGRID API KEY
# ============================================================================

# Create a secret to store SendGrid API key
resource "aws_secretsmanager_secret" "sendgrid_api_key" {
  name        = "csye6225-sendgrid-key-${var.environment}"
  description = "SendGrid API key for email notifications - ${var.environment}"

  # Encrypt with KMS key
  kms_key_id = aws_kms_key.secrets.key_id

  recovery_window_in_days = 0

  tags = merge(
    var.common_tags,
    {
      Name        = "csye6225-sendgrid-key-${var.environment}"
      Environment = var.environment
      Purpose     = "Email Service API Key"
    }
  )
}

# Store the SendGrid API key
# NOTE: This will be added manually first, then imported
resource "aws_secretsmanager_secret_version" "sendgrid_api_key" {
  secret_id = aws_secretsmanager_secret.sendgrid_api_key.id

  # Store as JSON for easy parsing
  secret_string = jsonencode({
    api_key    = var.sendgrid_api_key
    from_email = "noreply@${var.domain_name}"
    from_name  = "CSYE6225 WebApp"
  })
}

# ============================================================================
# OUTPUTS
# ============================================================================

output "db_password_secret_arn" {
  description = "ARN of the database password secret"
  value       = aws_secretsmanager_secret.db_password.arn
}

output "db_password_secret_name" {
  description = "Name of the database password secret"
  value       = aws_secretsmanager_secret.db_password.name
}

output "sendgrid_secret_arn" {
  description = "ARN of the SendGrid API key secret"
  value       = aws_secretsmanager_secret.sendgrid_api_key.arn
}

output "sendgrid_secret_name" {
  description = "Name of the SendGrid API key secret"
  value       = aws_secretsmanager_secret.sendgrid_api_key.name
}