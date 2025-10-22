# ec2.tf - Phase 6 Testing Version (No RDS references)

# Data source to fetch the latest custom AMI
data "aws_ami" "latest_custom_ami" {
  most_recent = true
  owners      = [var.ami_owner_id]

  filter {
    name   = "name"
    values = [var.ami_name_filter]
  }

  filter {
    name   = "state"
    values = ["available"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# User Data Script - Phase 6 Testing (S3 only, no RDS)
locals {
  user_data = <<-EOF
    #!/bin/bash
    set -e
    
    # Redirect all output to log file
    exec > >(tee -a /var/log/user-data.log) 2>&1
    
    echo "=========================================="
    echo "User Data Script Started: $(date)"
    echo "Phase 6 Testing - No RDS Configuration"
    echo "=========================================="
    
    # Application directory
    APP_DIR="/opt/csye6225"
    
    # Verify application directory exists
    if [ ! -d "$APP_DIR" ]; then
      echo "ERROR: Application directory $APP_DIR does not exist!"
      exit 1
    fi
    
    cd "$APP_DIR"
    echo "Working directory: $(pwd)"
    
    # Check if .env exists (from AMI)
    if [ -f .env ]; then
      echo "Found existing .env file from AMI"
      echo "Current .env contents (placeholder):"
      cat .env
      echo ""
    else
      echo "WARNING: No .env file found from AMI"
      exit 1
    fi
    
    # APPEND S3 configuration to existing .env file
    echo "" >> .env
    echo "# ============================================================================" >> .env
    echo "# S3 Configuration (added at runtime by Terraform)" >> .env
    echo "# ============================================================================" >> .env
    echo "S3_BUCKET_NAME=${aws_s3_bucket.product_images.bucket}" >> .env
    echo "AWS_REGION=${var.aws_region}" >> .env
    echo "ENVIRONMENT=${var.environment}" >> .env
    
    echo "=========================================="
    echo "Updated .env file (with S3, no RDS yet):"
    echo "=========================================="
    cat .env
    echo "=========================================="
    
    # Set proper permissions
    chown csye6225:csye6225 .env
    chmod 600 .env
    
    # DO NOT start webapp service yet (no database connection)
    echo ""
    echo "NOTE: webapp service is enabled but NOT started (no RDS yet)"
    echo "This is expected for Phase 6 testing"
    
    echo ""
    echo "=========================================="
    echo "User Data Script Completed: $(date)"
    echo "=========================================="
  EOF
}

# EC2 Instance
resource "aws_instance" "web_application" {
  ami                    = data.aws_ami.latest_custom_ami.id
  instance_type          = var.instance_type
  key_name               = var.ec2_key_name
  vpc_security_group_ids = [aws_security_group.application.id]
  subnet_id              = aws_subnet.public[0].id

  # Attach the instance profile
  iam_instance_profile = aws_iam_instance_profile.webapp_instance_profile.name

  # Root volume configuration
  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = var.root_volume_type
    delete_on_termination = true
  }

  # Use the local user_data
  user_data = base64encode(local.user_data)

  # Depends on S3 bucket being created
  depends_on = [
    aws_s3_bucket.product_images,
    aws_iam_instance_profile.webapp_instance_profile,
    aws_iam_role_policy_attachment.webapp_s3_policy_attachment
  ]

  tags = merge(
    var.common_tags,
    {
      Name        = "WebApp-Instance-${var.environment}"
      Environment = var.environment
      Purpose     = "Web Application Server"
    }
  )
}