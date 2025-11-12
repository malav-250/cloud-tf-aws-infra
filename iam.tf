# iam.tf
# ============================================================================
# S3 POLICY
# ============================================================================
resource "aws_iam_policy" "webapp_s3_policy" {
  name        = "WebAppS3Policy-${var.environment}"
  description = "Policy for web application to access S3 bucket for product images"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ]
        Resource = "${aws_s3_bucket.product_images.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.product_images.arn
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name        = "WebApp-S3-Policy-${var.environment}"
      Environment = var.environment
    }
  )
}

# ============================================================================
# CLOUDWATCH POLICY
# ============================================================================
resource "aws_iam_policy" "webapp_cloudwatch_policy" {
  name        = "WebAppCloudWatchPolicy-${var.environment}"
  description = "Policy for web application to write logs and metrics to CloudWatch"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          # CloudWatch Logs permissions
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = [
          "arn:aws:logs:${var.aws_region}:*:log-group:csye6225-webapp-*",
          "arn:aws:logs:${var.aws_region}:*:log-group:csye6225-webapp-*:log-stream:*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          # CloudWatch Metrics permissions
          "cloudwatch:PutMetricData"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "cloudwatch:namespace" = "CSYE6225-Webapp"
          }
        }
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name        = "WebApp-CloudWatch-Policy-${var.environment}"
      Environment = var.environment
    }
  )
}

# ============================================================================
# KMS POLICY (NEW - Assignment 9)
# ============================================================================
resource "aws_iam_policy" "webapp_kms_policy" {
  name        = "WebAppKMSPolicy-${var.environment}"
  description = "Policy for web application to use KMS keys for encryption/decryption"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowKMSForEBS"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:CreateGrant",
          "kms:DescribeKey"
        ]
        Resource = [
          aws_kms_key.ebs.arn
        ]
      },
      {
        Sid    = "AllowKMSForS3"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = [
          aws_kms_key.s3.arn
        ]
      },
      {
        Sid    = "AllowKMSForSecretsManager"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = [
          aws_kms_key.secrets.arn
        ]
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name        = "WebApp-KMS-Policy-${var.environment}"
      Environment = var.environment
    }
  )
}

# ============================================================================
# SECRETS MANAGER POLICY (Assignment 9)
# ============================================================================
resource "aws_iam_policy" "webapp_secrets_policy" {
  name        = "WebAppSecretsPolicy-${var.environment}"
  description = "Policy for web application to read secrets from Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          aws_secretsmanager_secret.db_password.arn,
          aws_secretsmanager_secret.sendgrid_api_key.arn
        ]
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name        = "WebApp-Secrets-Policy-${var.environment}"
      Environment = var.environment
    }
  )
}

# ============================================================================
# IAM ROLE
# ============================================================================
resource "aws_iam_role" "webapp_ec2_role" {
  name = "WebAppEC2Role-${var.environment}"

  # Trust policy - allows EC2 service to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name        = "WebApp-EC2-Role-${var.environment}"
      Environment = var.environment
    }
  )
}

# ============================================================================
# POLICY ATTACHMENTS
# ============================================================================

# Attach S3 policy to the EC2 role
resource "aws_iam_role_policy_attachment" "webapp_s3_policy_attachment" {
  role       = aws_iam_role.webapp_ec2_role.name
  policy_arn = aws_iam_policy.webapp_s3_policy.arn
}

# Attach CloudWatch policy to the EC2 role
resource "aws_iam_role_policy_attachment" "webapp_cloudwatch_policy_attachment" {
  role       = aws_iam_role.webapp_ec2_role.name
  policy_arn = aws_iam_policy.webapp_cloudwatch_policy.arn
}

# Attach KMS policy to the EC2 role (NEW - Assignment 9)
resource "aws_iam_role_policy_attachment" "webapp_kms_policy_attachment" {
  role       = aws_iam_role.webapp_ec2_role.name
  policy_arn = aws_iam_policy.webapp_kms_policy.arn
}

# Attach Secrets Manager policy to the EC2 role (NEW - Assignment 9)
resource "aws_iam_role_policy_attachment" "webapp_secrets_policy_attachment" {
  role       = aws_iam_role.webapp_ec2_role.name
  policy_arn = aws_iam_policy.webapp_secrets_policy.arn
}

# ============================================================================
# INSTANCE PROFILE
# ============================================================================
resource "aws_iam_instance_profile" "webapp_instance_profile" {
  name = "WebAppInstanceProfile-${var.environment}"
  role = aws_iam_role.webapp_ec2_role.name

  tags = merge(
    var.common_tags,
    {
      Name        = "WebApp-Instance-Profile-${var.environment}"
      Environment = var.environment
    }
  )
}


# ============================================================================
# SNS POLICY (Assignment 9)
# ============================================================================
resource "aws_iam_policy" "webapp_sns_policy" {
  name        = "WebAppSNSPolicy-${var.environment}"
  description = "Policy for web application to publish messages to SNS topics"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.email_verification.arn
      },
      {
        Sid    = "AllowKMSForSNS"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = aws_kms_key.sns.arn
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name        = "WebApp-SNS-Policy-${var.environment}"
      Environment = var.environment
    }
  )
}

# ============================================================================
# POLICY ATTACHMENTS (Add this after existing attachments)
# ============================================================================

# Attach SNS policy to the EC2 role (NEW - Assignment 9)
resource "aws_iam_role_policy_attachment" "webapp_sns_policy_attachment" {
  role       = aws_iam_role.webapp_ec2_role.name
  policy_arn = aws_iam_policy.webapp_sns_policy.arn
}