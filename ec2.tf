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

# User Data Script
locals {
  user_data = <<-EOF
    #!/bin/bash
    set -e
    
    # Redirect all output to log file
    exec > >(tee -a /var/log/user-data.log) 2>&1
    
    echo "=========================================="
    echo "User Data Script Started: $(date)"
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
      echo "Current .env contents:"
      cat .env
      echo ""
    else
      echo "WARNING: No .env file found from AMI"
    fi
    
    # APPEND S3 configuration to existing .env file
    echo "" >> .env
    echo "# S3 Configuration (added at runtime by Terraform)" >> .env
    echo "S3_BUCKET_NAME=${aws_s3_bucket.product_images.bucket}" >> .env
    echo "AWS_REGION=${var.aws_region}" >> .env
    echo "ENVIRONMENT=${var.environment}" >> .env
    
    echo "=========================================="
    echo "Updated .env file:"
    echo "=========================================="
    cat .env
    echo "=========================================="
    
    # Set proper permissions
    chown csye6225:csye6225 .env
    chmod 600 .env
    
    # Restart application to pick up new environment variables
    echo ""
    echo "Restarting webapp service..."
    systemctl daemon-reload
    systemctl restart webapp.service
    
    # Wait for service to start
    sleep 5
    
    # Check service status
    echo ""
    if systemctl is-active --quiet webapp.service; then
      echo "✅ webapp.service is running"
      systemctl status webapp.service --no-pager -l
    else
      echo "❌ webapp.service failed to start"
      echo "Service logs:"
      journalctl -u webapp.service --no-pager -n 50
      exit 1
    fi
    
    echo ""
    echo "=========================================="
    echo "User Data Script Completed: $(date)"
    echo "=========================================="
  EOF
}

# EC2 Instance
resource "aws_instance" "web_application" {
  ami                    = var.custom_ami_id != "" ? var.custom_ami_id : data.aws_ami.latest_custom_ami.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.application.id]
  key_name               = var.ec2_key_name

  # Attach IAM instance profile for S3 access
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  # Disable termination protection
  disable_api_termination = false

  # Instance metadata options (IMDSv2)
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  # Root volume configuration
  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = var.root_volume_type
    delete_on_termination = true
    encrypted             = true
  }

  # User data to configure runtime environment
  user_data = base64encode(local.user_data)

  # Replace instance when user data changes
  user_data_replace_on_change = true

  tags = merge(
    var.common_tags,
    {
      Name = "${var.vpc_name}-webapp-instance"
    }
  )

  # Ensure proper resource dependencies
  depends_on = [
    aws_internet_gateway.main,
    aws_route_table_association.public,
    aws_s3_bucket.product_images,
    aws_iam_instance_profile.ec2_profile
  ]
}