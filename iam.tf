# iam.tf

# IAM Policy for S3 access
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
        Resource = "${aws_s3_bucket.product_images.arn}/*" # Changed from user_images
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.product_images.arn # Changed from user_images
      }
    ]
  })

  tags = {
    Name        = "WebApp-S3-Policy-${var.environment}"
    Environment = var.environment
  }
}

# IAM Role that EC2 instances will assume
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

  tags = {
    Name        = "WebApp-EC2-Role-${var.environment}"
    Environment = var.environment
  }
}

# Attach the S3 policy to the EC2 role
resource "aws_iam_role_policy_attachment" "webapp_s3_policy_attachment" {
  role       = aws_iam_role.webapp_ec2_role.name
  policy_arn = aws_iam_policy.webapp_s3_policy.arn
}

# Instance Profile - container to pass IAM role to EC2
resource "aws_iam_instance_profile" "webapp_instance_profile" {
  name = "WebAppInstanceProfile-${var.environment}"
  role = aws_iam_role.webapp_ec2_role.name

  tags = {
    Name        = "WebApp-Instance-Profile-${var.environment}"
    Environment = var.environment
  }
}