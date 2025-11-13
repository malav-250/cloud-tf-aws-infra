# kms.tf - KMS Key Management for Encryption
# Assignment 9 - Encrypt all resources with customer-managed keys

# ============================================================================
# DATA SOURCE - Get Current AWS Account ID
# ============================================================================
data "aws_caller_identity" "current" {}

# ============================================================================
# KMS KEY FOR EC2 (EBS Volumes)
# ============================================================================
resource "aws_kms_key" "ebs" {
  description             = "KMS key for EC2 EBS volume encryption - ${var.environment}"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  rotation_period_in_days = 90

  tags = merge(
    var.common_tags,
    {
      Name        = "csye6225-ebs-key-${var.environment}"
      Environment = var.environment
      Purpose     = "EC2 EBS Volume Encryption"
    }
  )
}

resource "aws_kms_alias" "ebs" {
  name          = "alias/csye6225-ebs-${var.environment}"
  target_key_id = aws_kms_key.ebs.key_id
}

# ============================================================================
# KMS KEY FOR RDS (Database Encryption)
# ============================================================================
resource "aws_kms_key" "rds" {
  description             = "KMS key for RDS database encryption - ${var.environment}"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  rotation_period_in_days = 90

  tags = merge(
    var.common_tags,
    {
      Name        = "csye6225-rds-key-${var.environment}"
      Environment = var.environment
      Purpose     = "RDS Database Encryption"
    }
  )
}

resource "aws_kms_alias" "rds" {
  name          = "alias/csye6225-rds-${var.environment}"
  target_key_id = aws_kms_key.rds.key_id
}

# ============================================================================
# KMS KEY FOR S3 (Bucket Encryption)
# ============================================================================
resource "aws_kms_key" "s3" {
  description             = "KMS key for S3 bucket encryption - ${var.environment}"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  rotation_period_in_days = 90

  tags = merge(
    var.common_tags,
    {
      Name        = "csye6225-s3-key-${var.environment}"
      Environment = var.environment
      Purpose     = "S3 Bucket Encryption"
    }
  )
}

resource "aws_kms_alias" "s3" {
  name          = "alias/csye6225-s3-${var.environment}"
  target_key_id = aws_kms_key.s3.key_id
}

# ============================================================================
# KMS KEY FOR SECRETS MANAGER
# ============================================================================
resource "aws_kms_key" "secrets" {
  description             = "KMS key for Secrets Manager encryption - ${var.environment}"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  rotation_period_in_days = 90

  tags = merge(
    var.common_tags,
    {
      Name        = "csye6225-secrets-key-${var.environment}"
      Environment = var.environment
      Purpose     = "Secrets Manager Encryption"
    }
  )
}

resource "aws_kms_alias" "secrets" {
  name          = "alias/csye6225-secrets-${var.environment}"
  target_key_id = aws_kms_key.secrets.key_id
}

# ============================================================================
# KMS KEY POLICY FOR EC2 (Auto Scaling Service Access)
# ============================================================================
resource "aws_kms_grant" "ebs_autoscaling" {
  name              = "ebs-autoscaling-grant-${var.environment}"
  key_id            = aws_kms_key.ebs.key_id
  grantee_principal = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"


  operations = [
    "Encrypt",
    "Decrypt",
    "ReEncryptFrom",
    "ReEncryptTo",
    "GenerateDataKey",
    "GenerateDataKeyWithoutPlaintext",
    "CreateGrant",
    "DescribeKey"
  ]
}

# ============================================================================
# OUTPUTS
# ============================================================================
output "kms_key_ebs_arn" {
  description = "ARN of KMS key for EBS encryption"
  value       = aws_kms_key.ebs.arn
}

output "kms_key_ebs_id" {
  description = "ID of KMS key for EBS encryption"
  value       = aws_kms_key.ebs.key_id
}

output "kms_key_rds_arn" {
  description = "ARN of KMS key for RDS encryption"
  value       = aws_kms_key.rds.arn
}

output "kms_key_rds_id" {
  description = "ID of KMS key for RDS encryption"
  value       = aws_kms_key.rds.key_id
}

output "kms_key_s3_arn" {
  description = "ARN of KMS key for S3 encryption"
  value       = aws_kms_key.s3.arn
}

output "kms_key_s3_id" {
  description = "ID of KMS key for S3 encryption"
  value       = aws_kms_key.s3.key_id
}

output "kms_key_secrets_arn" {
  description = "ARN of KMS key for Secrets Manager encryption"
  value       = aws_kms_key.secrets.arn
}

output "kms_key_secrets_id" {
  description = "ID of KMS key for Secrets Manager encryption"
  value       = aws_kms_key.secrets.key_id
}


# CloudWatch Logs KMS Key
resource "aws_kms_key" "cloudwatch_key" {
  description             = "KMS key for CloudWatch Logs encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow CloudWatch Logs"
        Effect = "Allow"
        Principal = {
          Service = "logs.${var.aws_region}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:CreateGrant",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          ArnLike = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:*"
          }
        }
      }
    ]
  })

  tags = {
    Name        = "cloudwatch-logs-key"
    Environment = var.environment
  }
}

resource "aws_kms_alias" "cloudwatch_key_alias" {
  name          = "alias/cloudwatch-logs-key"
  target_key_id = aws_kms_key.cloudwatch_key.key_id
}