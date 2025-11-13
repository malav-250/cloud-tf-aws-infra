# lambda.tf - Lambda Function for Email Verification
# Assignment 9 Phase 8 - Lambda Terraform Configuration

# ============================================================================
# LAMBDA EXECUTION ROLE
# ============================================================================
resource "aws_iam_role" "lambda_execution_role" {
  name = "${var.lambda_function_name}-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.lambda_function_name}-execution-role"
      Environment = var.environment
    }
  )
}

# ============================================================================
# IAM POLICIES FOR LAMBDA
# ============================================================================

# CloudWatch Logs Policy
resource "aws_iam_policy" "lambda_cloudwatch_policy" {
  name        = "${var.lambda_function_name}-cloudwatch-policy"
  description = "Policy for Lambda to write logs to CloudWatch"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.lambda_function_name}:*"
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.lambda_function_name}-cloudwatch-policy"
      Environment = var.environment
    }
  )
}

# DynamoDB Access Policy
resource "aws_iam_policy" "lambda_dynamodb_policy" {
  name        = "${var.lambda_function_name}-dynamodb-policy"
  description = "Policy for Lambda to access DynamoDB"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem"
        ]
        Resource = aws_dynamodb_table.email_verification_tokens.arn
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.lambda_function_name}-dynamodb-policy"
      Environment = var.environment
    }
  )
}

# Secrets Manager Access Policy
resource "aws_iam_policy" "lambda_secrets_manager_policy" {
  name        = "${var.lambda_function_name}-secrets-manager-policy"
  description = "Policy for Lambda to access Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = aws_secretsmanager_secret.sendgrid_api_key.arn
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.lambda_function_name}-secrets-manager-policy"
      Environment = var.environment
    }
  )
}

# KMS Decrypt Policy for Lambda
resource "aws_iam_policy" "lambda_kms_policy" {
  name        = "${var.lambda_function_name}-kms-policy"
  description = "Policy for Lambda to decrypt using KMS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:GenerateDataKey"
        ]
        Resource = [
          aws_kms_key.dynamodb.arn,
          aws_kms_key.secrets.arn,
          aws_kms_key.sns.arn
        ]
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.lambda_function_name}-kms-policy"
      Environment = var.environment
    }
  )
}

# ============================================================================
# ATTACH POLICIES TO LAMBDA ROLE
# ============================================================================

resource "aws_iam_role_policy_attachment" "lambda_cloudwatch_attach" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_cloudwatch_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_dynamodb_attach" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_dynamodb_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_secrets_manager_attach" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_secrets_manager_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_kms_attach" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_kms_policy.arn
}

# ============================================================================
# CLOUDWATCH LOG GROUP
# ============================================================================

resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${var.lambda_function_name}"
  retention_in_days = 14
  kms_key_id        = aws_kms_key.cloudwatch_key.arn

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.lambda_function_name}-log-group"
      Environment = var.environment
    }
  )
}

# ============================================================================
# LAMBDA FUNCTION
# ============================================================================

resource "aws_lambda_function" "email_verification" {
  filename         = var.lambda_zip_file
  function_name    = var.lambda_function_name
  role             = aws_iam_role.lambda_execution_role.arn
  handler          = "lambda_function.lambda_handler"
  source_code_hash = filebase64sha256(var.lambda_zip_file)
  runtime          = "python3.11"
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory_size

  environment {
    variables = {
      DYNAMODB_TABLE_NAME          = aws_dynamodb_table.email_verification_tokens.name
      SENDGRID_API_KEY_SECRET_NAME = aws_secretsmanager_secret.sendgrid_api_key.name
      REGION                       = var.aws_region
      TOKEN_EXPIRY_MINUTES         = var.token_expiry_minutes
      FROM_EMAIL                   = "noreply@${var.domain_name}"
      DOMAIN                       = var.subdomain != "" ? "${var.subdomain}.${var.domain_name}" : var.domain_name
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.lambda_log_group,
    aws_iam_role_policy_attachment.lambda_cloudwatch_attach,
    aws_iam_role_policy_attachment.lambda_dynamodb_attach,
    aws_iam_role_policy_attachment.lambda_secrets_manager_attach,
    aws_iam_role_policy_attachment.lambda_kms_attach
  ]

  tags = merge(
    var.common_tags,
    {
      Name        = var.lambda_function_name
      Environment = var.environment
    }
  )
}

# ============================================================================
# SNS TOPIC SUBSCRIPTION
# ============================================================================

resource "aws_sns_topic_subscription" "lambda_subscription" {
  topic_arn = aws_sns_topic.email_verification.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.email_verification.arn
}

# ============================================================================
# LAMBDA PERMISSION FOR SNS
# ============================================================================

resource "aws_lambda_permission" "allow_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.email_verification.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.email_verification.arn
}

# ============================================================================
# OUTPUTS
# ============================================================================

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.email_verification.function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.email_verification.arn
}

output "lambda_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = aws_iam_role.lambda_execution_role.arn
}

output "lambda_log_group_name" {
  description = "Name of the Lambda CloudWatch log group"
  value       = aws_cloudwatch_log_group.lambda_log_group.name
}