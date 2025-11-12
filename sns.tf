# sns.tf - SNS Topic for Email Verification
# Assignment 9 - Email verification workflow trigger

# ============================================================================
# KMS KEY FOR SNS
# ============================================================================
resource "aws_kms_key" "sns" {
  description             = "KMS key for SNS topic encryption - ${var.environment}"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  # Key policy to allow SNS service to use this key
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
        Sid    = "Allow SNS to use the key"
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow CloudWatch Events to use the key"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name        = "csye6225-sns-key-${var.environment}"
      Environment = var.environment
      Purpose     = "SNS Topic Encryption"
    }
  )
}

resource "aws_kms_alias" "sns" {
  name          = "alias/csye6225-sns-${var.environment}"
  target_key_id = aws_kms_key.sns.key_id
}

# ============================================================================
# SNS TOPIC FOR EMAIL VERIFICATION
# ============================================================================
resource "aws_sns_topic" "email_verification" {
  name              = "csye6225-email-verification-${var.environment}"
  display_name      = "Email Verification Topic"
  kms_master_key_id = aws_kms_key.sns.id

  tags = merge(
    var.common_tags,
    {
      Name        = "csye6225-email-verification-${var.environment}"
      Environment = var.environment
      Purpose     = "Email Verification Workflow"
    }
  )
}

# ============================================================================
# SNS TOPIC POLICY
# ============================================================================
resource "aws_sns_topic_policy" "email_verification_policy" {
  arn = aws_sns_topic.email_verification.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEC2Publish"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.webapp_ec2_role.arn
        }
        Action = [
          "SNS:Publish"
        ]
        Resource = aws_sns_topic.email_verification.arn
      },
      {
        Sid    = "AllowAWSServices"
        Effect = "Allow"
        Principal = {
          Service = [
            "events.amazonaws.com",
            "cloudwatch.amazonaws.com"
          ]
        }
        Action = [
          "SNS:Publish"
        ]
        Resource = aws_sns_topic.email_verification.arn
      }
    ]
  })
}

# ============================================================================
# OUTPUTS
# ============================================================================
output "sns_topic_arn" {
  description = "ARN of the SNS topic for email verification"
  value       = aws_sns_topic.email_verification.arn
}

output "sns_topic_name" {
  description = "Name of the SNS topic"
  value       = aws_sns_topic.email_verification.name
}

output "kms_key_sns_arn" {
  description = "ARN of KMS key for SNS encryption"
  value       = aws_kms_key.sns.arn
}

output "kms_key_sns_id" {
  description = "ID of KMS key for SNS encryption"
  value       = aws_kms_key.sns.key_id
}