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

# User Data Script - Phase 7 (with RDS)
locals {
  user_data = <<-EOF
    #!/bin/bash
    set -e
    
    # Redirect all output to log file
    exec > >(tee -a /var/log/user-data.log) 2>&1
    
    echo "=========================================="
    echo "User Data Script Started: $(date)"
    echo "Phase 7: RDS + S3 Configuration"
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
    
    echo "" >> .env
    echo "# ============================================================================" >> .env
    echo "# RDS Database Configuration (added at runtime by Terraform)" >> .env
    echo "# ============================================================================" >> .env
    echo "DATABASE_HOST=${aws_db_instance.webapp_db.address}" >> .env
    echo "DATABASE_PORT=${aws_db_instance.webapp_db.port}" >> .env
    echo "DATABASE_NAME=${var.db_name}" >> .env
    echo "DATABASE_USER=${var.db_username}" >> .env
    echo "DATABASE_PASSWORD=${var.db_password}" >> .env
    echo "DATABASE_URL=postgresql://${var.db_username}:${var.db_password}@${aws_db_instance.webapp_db.address}:${aws_db_instance.webapp_db.port}/${var.db_name}" >> .env
    echo "" >> .env
    
    echo "# ============================================================================" >> .env
    echo "# S3 Configuration (added at runtime by Terraform)" >> .env
    echo "# ============================================================================" >> .env
    echo "S3_BUCKET_NAME=${aws_s3_bucket.product_images.bucket}" >> .env
    echo "AWS_REGION=${var.aws_region}" >> .env
    echo "ENVIRONMENT=${var.environment}" >> .env
    
    echo "=========================================="
    echo "Updated .env file:"
    echo "=========================================="
    # Show .env but mask password
    cat .env | sed 's/PASSWORD=.*/PASSWORD=***MASKED***/'
    echo "=========================================="
    
    # Set proper permissions
    chown csye6225:csye6225 .env
    chmod 600 .env
    
    # Test database connectivity before starting service
    echo ""
    echo "Testing database connectivity..."
    
    # Wait for RDS to be ready (it might still be initializing)
    max_attempts=30
    attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
      if timeout 5 bash -c "cat < /dev/null > /dev/tcp/${aws_db_instance.webapp_db.address}/${aws_db_instance.webapp_db.port}"; then
        echo "Database port is reachable"
        break
      else
        attempt=$((attempt + 1))
        echo "Waiting for database... (attempt $attempt/$max_attempts)"
        sleep 10
      fi
    done
    
    if [ $attempt -eq $max_attempts ]; then
      echo "WARNING: Could not connect to database after $max_attempts attempts"
      echo "Service may fail to start. Check RDS status."
    fi
    
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
      echo "webapp.service is running"
      systemctl status webapp.service --no-pager -l
    else
      echo "webapp.service failed to start"
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

  # CRITICAL: Ensure RDS and S3 are created first
  depends_on = [
    aws_s3_bucket.product_images,
    aws_iam_instance_profile.webapp_instance_profile,
    aws_iam_role_policy_attachment.webapp_s3_policy_attachment,
    aws_db_instance.webapp_db
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