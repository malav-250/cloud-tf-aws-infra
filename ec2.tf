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

locals {
  user_data = <<-EOF
    #!/bin/bash
    set -e
    exec > >(tee -a /var/log/user-data.log) 2>&1
    
    echo "=========================================="
    echo "User Data Started: $(date)"
    echo "Phase 7: RDS + S3 + CloudWatch"
    echo "=========================================="
    
    APP_DIR="/opt/csye6225"
    cd "$APP_DIR"
    
    # Add RDS configuration with AUTO-GENERATED PASSWORD
    echo "" >> .env
    echo "# RDS Database Configuration" >> .env
    echo "DATABASE_HOST=${aws_db_instance.webapp_db.address}" >> .env
    echo "DATABASE_PORT=${aws_db_instance.webapp_db.port}" >> .env
    echo "DATABASE_NAME=${var.db_name}" >> .env
    echo "DATABASE_USER=${var.db_username}" >> .env
    echo "DATABASE_PASSWORD=${random_password.db_password.result}" >> .env
    echo "DATABASE_URL=postgresql://${var.db_username}:${random_password.db_password.result}@${aws_db_instance.webapp_db.address}:${aws_db_instance.webapp_db.port}/${var.db_name}" >> .env
    
    # Add S3 configuration
    echo "" >> .env
    echo "# S3 Configuration" >> .env
    echo "S3_BUCKET_NAME=${aws_s3_bucket.product_images.bucket}" >> .env
    echo "AWS_REGION=${var.aws_region}" >> .env
    echo "ENVIRONMENT=${var.environment}" >> .env
    
    chown csye6225:csye6225 .env
    chmod 600 .env
    
    # CloudWatch Agent is already running (auto-started from AMI)
    echo ""
    echo "Verifying CloudWatch Agent..."
    if systemctl is-active --quiet amazon-cloudwatch-agent; then
      echo "✓ CloudWatch Agent is running"
    else
      echo "⚠ CloudWatch Agent not running - will be handled by systemd"
    fi
    
    # Restart application
    echo ""
    echo "Restarting webapp service..."
    systemctl daemon-reload
    systemctl restart webapp.service
    sleep 2
    
    if systemctl is-active --quiet webapp.service; then
      echo "✓ Application running"
    else
      echo "⚠ Application not running yet"
    fi
    
    echo ""
    echo "User Data Completed: $(date)"
  EOF
}

resource "aws_instance" "web_application" {
  ami                    = local.ami_id
  instance_type          = var.instance_type
  key_name               = var.ec2_key_name
  vpc_security_group_ids = [aws_security_group.application.id]
  subnet_id              = aws_subnet.public[0].id

  # Attach the instance profile
  iam_instance_profile = aws_iam_instance_profile.webapp_instance_profile.name

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
  }

  # Use the local user_data
  user_data = base64encode(local.user_data)

  # CRITICAL: Ensure all resources are ready before instance starts
  depends_on = [
    aws_s3_bucket.product_images,
    aws_iam_instance_profile.webapp_instance_profile,
    aws_iam_role_policy_attachment.webapp_s3_policy_attachment,
    aws_iam_role_policy_attachment.webapp_cloudwatch_policy_attachment,
    aws_db_instance.webapp_db,
    random_password.db_password # ✅ Ensure password is generated first
  ]

  tags = merge(
    var.common_tags,
    {
      Name        = "WebApp-Instance-${var.environment}"
      Environment = var.environment
      Purpose     = "Web Application Server"
    }
  )

  # User data should run on every update
  user_data_replace_on_change = true
}