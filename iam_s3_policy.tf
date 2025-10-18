# iam_s3_policy.tf - IAM policy for EC2 to access S3 bucket

# IAM Policy Document - Minimum required S3 permissions
data "aws_iam_policy_document" "s3_access" {
  # Allow putting objects (upload)
  statement {
    sid    = "AllowS3Upload"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl"
    ]
    resources = [
      "${aws_s3_bucket.product_images.arn}/*"
    ]
  }

  # Allow deleting objects
  statement {
    sid    = "AllowS3Delete"
    effect = "Allow"
    actions = [
      "s3:DeleteObject"
    ]
    resources = [
      "${aws_s3_bucket.product_images.arn}/*"
    ]
  }

  # Allow getting objects (for future download feature)
  statement {
    sid    = "AllowS3Download"
    effect = "Allow"
    actions = [
      "s3:GetObject"
    ]
    resources = [
      "${aws_s3_bucket.product_images.arn}/*"
    ]
  }

  # Allow listing bucket contents
  statement {
    sid    = "AllowS3ListBucket"
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      aws_s3_bucket.product_images.arn
    ]
  }
}

# Create IAM Policy from document
resource "aws_iam_policy" "s3_access" {
  name        = "WebAppS3Access-${var.environment}"
  description = "Allows EC2 instances to access S3 bucket for product images"
  policy      = data.aws_iam_policy_document.s3_access.json

  tags = merge(
    var.common_tags,
    {
      Name        = "WebApp S3 Access Policy"
      Environment = var.environment
    }
  )
}

# Attach policy to existing EC2 IAM role
resource "aws_iam_role_policy_attachment" "ec2_s3_access" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.s3_access.arn
}