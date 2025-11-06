# outputs.tf - Terraform Outputs

# ============================================================================
# VPC OUTPUTS
# ============================================================================
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

# ============================================================================
# SUBNET OUTPUTS
# ============================================================================
output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = aws_subnet.private[*].id
}

# ============================================================================
# SECURITY GROUP OUTPUTS
# ============================================================================
output "application_security_group_id" {
  description = "ID of the application security group"
  value       = aws_security_group.application.id
}

output "rds_security_group_id" {
  description = "ID of the RDS security group"
  value       = aws_security_group.rds.id
}

# ============================================================================
# EC2 OUTPUTS
# ============================================================================
# output "ec2_instance_id" {
#   description = "ID of the EC2 instance"
#   value       = aws_instance.web_application.id
# }

# output "ec2_public_ip" {
#   description = "Public IP address of the EC2 instance"
#   value       = aws_instance.web_application.public_ip
# }

# output "ec2_private_ip" {
#   description = "Private IP address of the EC2 instance"
#   value       = aws_instance.web_application.private_ip
# }

# output "ami_id" {
#   description = "AMI ID used for the EC2 instance"
#   value       = aws_instance.web_application.ami
# }

# ============================================================================
# RDS OUTPUTS
# ============================================================================
output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.webapp_db.endpoint
}

output "rds_address" {
  description = "RDS instance address (hostname)"
  value       = aws_db_instance.webapp_db.address
}

output "rds_port" {
  description = "RDS instance port"
  value       = aws_db_instance.webapp_db.port
}

output "rds_database_name" {
  description = "RDS database name"
  value       = aws_db_instance.webapp_db.db_name
}

output "rds_username" {
  description = "RDS master username"
  value       = aws_db_instance.webapp_db.username
  sensitive   = true
}

# ============================================================================
# S3 OUTPUTS
# ============================================================================
output "s3_bucket_name" {
  description = "Name of the S3 bucket for product images"
  value       = aws_s3_bucket.product_images.bucket
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.product_images.arn
}

output "s3_bucket_region" {
  description = "Region of the S3 bucket"
  value       = aws_s3_bucket.product_images.region
}

# ============================================================================
# IAM OUTPUTS
# ============================================================================
output "iam_role_name" {
  description = "Name of the IAM role for EC2"
  value       = aws_iam_role.webapp_ec2_role.name
}

output "iam_role_arn" {
  description = "ARN of the IAM role for EC2"
  value       = aws_iam_role.webapp_ec2_role.arn
}

output "instance_profile_name" {
  description = "Name of the instance profile"
  value       = aws_iam_instance_profile.webapp_instance_profile.name
}

# ============================================================================
# APPLICATION ENDPOINTS
# ============================================================================
# output "application_url" {
#   description = "URL to access the application"
#   value       = "http://${aws_instance.web_application.public_ip}:${var.application_port}"
# }

# output "health_check_url" {
#   description = "Health check endpoint URL"
#   value       = "http://${aws_instance.web_application.public_ip}:${var.application_port}/healthz"
# }

# ============================================================================
# DEPLOYMENT SUMMARY
# ============================================================================
# output "deployment_summary" {
#   description = "Summary of deployed infrastructure"
#   value = {
#     environment     = var.environment
#     region          = var.aws_region
#     vpc_id          = aws_vpc.main.id
#     ec2_instance_id = aws_instance.web_application.id
#     ec2_public_ip   = aws_instance.web_application.public_ip
#     rds_endpoint    = aws_db_instance.webapp_db.endpoint
#     s3_bucket_name  = aws_s3_bucket.product_images.bucket
#     application_url = "http://${aws_instance.web_application.public_ip}:${var.application_port}"
#   }
# }

# ============================================================================
# QUICK START GUIDE
# ============================================================================
# output "quick_start" {
#   description = "Quick start commands and URLs"
#   value       = <<-EOT
#     ========================================
#     DEPLOYMENT COMPLETE - QUICK START GUIDE
#     ========================================

#     🌐 APPLICATION ACCESS:
#        URL: http://${aws_instance.web_application.public_ip}:${var.application_port}
#        Health Check: http://${aws_instance.web_application.public_ip}:${var.application_port}/healthz

#     🔐 SSH ACCESS:
#        ssh -i ~/.ssh/${var.ec2_key_name}.pem ubuntu@${aws_instance.web_application.public_ip}

#     📊 DATABASE INFO:
#        Endpoint: ${aws_db_instance.webapp_db.endpoint}
#        Database: ${aws_db_instance.webapp_db.db_name}
#        Username: ${aws_db_instance.webapp_db.username}
#        Password: Auto-generated (stored in Terraform state)

#     📦 S3 BUCKET:
#        Name: ${aws_s3_bucket.product_images.bucket}
#        Region: ${var.aws_region}

#     🔍 VERIFY DEPLOYMENT:
#        # Test health check
#        curl http://${aws_instance.web_application.public_ip}:${var.application_port}/healthz

#        # Check application logs
#        ssh -i ~/.ssh/${var.ec2_key_name}.pem ubuntu@${aws_instance.web_application.public_ip}
#        sudo journalctl -u webapp.service -f

#     📝 DATABASE PASSWORD:
#        # Retrieve from Terraform state (sensitive)
#        terraform output -raw db_password_note

#     ========================================
#   EOT
# }

# ============================================================================
# PASSWORD NOTE (NOT THE ACTUAL PASSWORD)
# ============================================================================
output "db_password_note" {
  description = "Note about database password"
  value       = "Database password is auto-generated and stored in .env file on EC2 instance at /opt/csye6225/.env (accessible only by csye6225 user). Password is also in Terraform state."
}

# ============================================================================
# TESTING COMMANDS
# ============================================================================
# output "testing_commands" {
#   description = "Common testing commands"
#   value       = <<-EOT
#     # Create a test user
#     curl -X POST http://${aws_instance.web_application.public_ip}:${var.application_port}/v1/user \
#       -H "Content-Type: application/json" \
#       -d '{
#         "first_name": "Test",
#         "last_name": "User",
#         "username": "test@example.com",
#         "password": "Test@1234"
#       }'

#     # Get user info (authentication required)
#     curl -X GET http://${aws_instance.web_application.public_ip}:${var.application_port}/v1/user/self \
#       -u "test@example.com:Test@1234"

#     # Create a product
#     curl -X POST http://${aws_instance.web_application.public_ip}:${var.application_port}/v1/product \
#       -u "test@example.com:Test@1234" \
#       -H "Content-Type: application/json" \
#       -d '{
#         "name": "Test Product",
#         "description": "A test product",
#         "sku": "TEST-001",
#         "manufacturer": "Test Corp",
#         "quantity": 100
#       }'
#   EOT
# }

# ============================================================================
# CLOUDWATCH LOGS
# ============================================================================
output "cloudwatch_info" {
  description = "CloudWatch logging information"
  value = {
    log_group_pattern = "csye6225-webapp-*"
    metrics_namespace = "CSYE6225-Webapp"
    region            = var.aws_region
  }
}


# ========================================
# Application Load Balancer Outputs
# ========================================

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.application.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = aws_lb.application.zone_id
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.application.arn
}

# ========================================
# Auto Scaling Group Outputs
# ========================================

output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.application.name
}

output "asg_arn" {
  description = "ARN of the Auto Scaling Group"
  value       = aws_autoscaling_group.application.arn
}

# ========================================
# DNS Outputs
# ========================================

output "webapp_url" {
  description = "URL to access the web application"
  value       = "http://${aws_route53_record.webapp.fqdn}"
}

output "webapp_domain" {
  description = "Domain name for the web application"
  value       = aws_route53_record.webapp.fqdn
}

# ========================================
# Target Group Outputs
# ========================================

output "target_group_arn" {
  description = "ARN of the target group"
  value       = aws_lb_target_group.application.arn
}