# dynamodb.tf - DynamoDB Table for Email Verification Tokens
# Assignment 9 - Store verification tokens with TTL

# ============================================================================
# KMS KEY FOR DYNAMODB
# ============================================================================
resource "aws_kms_key" "dynamodb" {
  description             = "KMS key for DynamoDB table encryption - ${var.environment}"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = merge(
    var.common_tags,
    {
      Name        = "csye6225-dynamodb-key-${var.environment}"
      Environment = var.environment
      Purpose     = "DynamoDB Table Encryption"
    }
  )
}

resource "aws_kms_alias" "dynamodb" {
  name          = "alias/csye6225-dynamodb-${var.environment}"
  target_key_id = aws_kms_key.dynamodb.key_id
}

# ============================================================================
# DYNAMODB TABLE FOR EMAIL VERIFICATION TOKENS
# ============================================================================
resource "aws_dynamodb_table" "email_verification_tokens" {
  name         = "email-verification-tokens-${var.environment}"
  billing_mode = "PAY_PER_REQUEST" # On-demand pricing
  hash_key     = "email"

  attribute {
    name = "email"
    type = "S" # String
  }

  # TTL configuration - automatically delete expired tokens
  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  # Server-side encryption with customer-managed KMS key
  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.dynamodb.arn
  }

  # Point-in-time recovery for production safety
  point_in_time_recovery {
    enabled = true
  }

  tags = merge(
    var.common_tags,
    {
      Name        = "email-verification-tokens-${var.environment}"
      Environment = var.environment
      Purpose     = "Email Verification Token Storage"
    }
  )
}

# ============================================================================
# OUTPUTS
# ============================================================================
output "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  value       = aws_dynamodb_table.email_verification_tokens.name
}

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table"
  value       = aws_dynamodb_table.email_verification_tokens.arn
}

output "kms_key_dynamodb_arn" {
  description = "ARN of KMS key for DynamoDB encryption"
  value       = aws_kms_key.dynamodb.arn
}

output "kms_key_dynamodb_id" {
  description = "ID of KMS key for DynamoDB encryption"
  value       = aws_kms_key.dynamodb.key_id
}