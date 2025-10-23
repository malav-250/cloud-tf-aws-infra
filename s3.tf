# s3.tf - S3 Bucket for Product Images

# Generate unique bucket name using UUID
resource "random_uuid" "s3_bucket_suffix" {
  keepers = {
    # Regenerate if environment changes
    environment = var.environment
  }
}

locals {
  # Construct bucket name: webapp-images-{environment}-{uuid}
  # Example: webapp-images-dev-a1b2c3d4-e5f6-7890-abcd-ef1234567890
  s3_bucket_name = "webapp-images-${var.environment}-${random_uuid.s3_bucket_suffix.result}"
}

# S3 Bucket for storing product images
resource "aws_s3_bucket" "product_images" {
  bucket = local.s3_bucket_name

  force_destroy = var.environment == "prod" ? false : true

  tags = merge(
    var.common_tags,
    {
      Name        = "Product Images Bucket"
      Purpose     = "Store product images uploaded by users"
      Environment = var.environment
    }
  )
}

# Block all public access to S3 bucket
# Images should only be accessible via application
resource "aws_s3_bucket_public_access_block" "product_images" {
  bucket = aws_s3_bucket.product_images.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable versioning for data protection
resource "aws_s3_bucket_versioning" "product_images" {
  bucket = aws_s3_bucket.product_images.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Server-side encryption for security
resource "aws_s3_bucket_server_side_encryption_configuration" "product_images" {
  bucket = aws_s3_bucket.product_images.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Lifecycle policy to manage storage costs and old versions
resource "aws_s3_bucket_lifecycle_configuration" "product_images" {
  bucket = aws_s3_bucket.product_images.id

  rule {
    id     = "transition-to-standard-ia-and-cleanup"
    status = "Enabled"

    filter {}


    # This is the main requirement from the assignment
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    # Clean up old versions after 30 days
    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    # Clean up incomplete multipart uploads after 7 days
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}