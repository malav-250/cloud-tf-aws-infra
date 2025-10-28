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
# CLOUDWATCH POLICY (NEW - Phase 7)
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

# Attach CloudWatch policy to the EC2 role (NEW)
resource "aws_iam_role_policy_attachment" "webapp_cloudwatch_policy_attachment" {
  role       = aws_iam_role.webapp_ec2_role.name
  policy_arn = aws_iam_policy.webapp_cloudwatch_policy.arn
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