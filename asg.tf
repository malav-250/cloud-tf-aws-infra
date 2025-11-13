# ========================================
# Launch Template
# ========================================

resource "aws_launch_template" "application" {
  name          = "demo-webapp-lt"
  image_id      = local.ami_id
  instance_type = var.instance_type
  key_name      = var.ec2_key_name

  # IAM Instance Profile
  iam_instance_profile {
    name = aws_iam_instance_profile.webapp_instance_profile.name
  }

  # Network configuration
  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.application.id]
    delete_on_termination       = true
  }

  # User data script
  # User data script
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    s3_bucket     = aws_s3_bucket.product_images.bucket
    region        = var.aws_region
    environment   = var.environment
    sns_topic_arn = aws_sns_topic.email_verification.arn
  }))

  # Block device mapping (if you need to customize EBS)
  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size           = 25
      volume_type           = "gp3"
      delete_on_termination = true
      encrypted             = true
      kms_key_id            = aws_kms_key.ebs.arn
    }
  }

  # Metadata options for IMDSv2
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  # Tags to apply to instances
  tag_specifications {
    resource_type = "instance"

    tags = {
      Name        = "${var.environment}-webapp-instance"
      Environment = var.environment
      ManagedBy   = "AutoScaling"
    }
  }

  tag_specifications {
    resource_type = "volume"

    tags = {
      Name        = "${var.environment}-webapp-volume"
      Environment = var.environment
    }
  }

  tags = {
    Name        = "${var.environment}-webapp-lt"
    Environment = var.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ========================================
# Auto Scaling Group
# ========================================

resource "aws_autoscaling_group" "application" {
  name                = "csye6225_asg"
  vpc_zone_identifier = aws_subnet.public[*].id

  # Capacity configuration (per assignment requirements)
  min_size         = var.asg_min_size         # 3
  max_size         = var.asg_max_size         # 5
  desired_capacity = var.asg_desired_capacity # 1

  # Cooldown period
  default_cooldown = var.asg_cooldown # 60 seconds

  # Health check configuration
  health_check_type         = "ELB"
  health_check_grace_period = var.asg_health_check_grace_period # 300 seconds

  # Target group attachment
  target_group_arns = [aws_lb_target_group.application.arn]

  # Launch template
  launch_template {
    id      = aws_launch_template.application.id
    version = "$Latest"
  }

  # Tags for instances
  tag {
    key                 = "Name"
    value               = "${var.environment}-webapp-asg-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  tag {
    key                 = "ManagedBy"
    value               = "AutoScaling"
    propagate_at_launch = true
  }

  # Lifecycle
  lifecycle {
    create_before_destroy = true
    ignore_changes        = [desired_capacity]
  }

  # Wait for instances to be healthy before considering deployment successful
  wait_for_capacity_timeout = "10m"

  # CRITICAL: Ensure all required resources exist BEFORE launching instances
  depends_on = [
    aws_lb.application,
    aws_lb_target_group.application,
    aws_lb_listener.https,
    aws_db_instance.webapp_db,
    aws_secretsmanager_secret_version.db_password,  # ✅ Database secret must exist
    aws_secretsmanager_secret_version.sendgrid_api_key,  # ✅ Changed to secret_version
    aws_s3_bucket.product_images,
    aws_sns_topic.email_verification
  ]
}