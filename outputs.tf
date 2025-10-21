# VPC outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "vpc_arn" {
  description = "ARN of the VPC"
  value       = aws_vpc.main.arn
}

# Internet Gateway
output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

# Availability Zone information
output "available_azs_in_region" {
  description = "All available AZs in the selected region"
  value       = data.aws_availability_zones.available.names
}

output "available_az_count" {
  description = "Number of available AZs in the region"
  value       = length(data.aws_availability_zones.available.names)
}

output "selected_azs" {
  description = "Availability zones selected for use"
  value       = local.selected_azs
}

output "selected_az_count" {
  description = "Number of AZs being used"
  value       = local.az_count
}

output "azs_used" {
  description = "Unique availability zones used for subnets"
  value       = distinct(concat(values(local.public_subnet_az_mapping), values(local.private_subnet_az_mapping)))
}

# Public subnet outputs
output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "public_subnet_cidrs" {
  description = "CIDR blocks of public subnets"
  value       = aws_subnet.public[*].cidr_block
}

output "public_subnet_azs" {
  description = "Availability zones of public subnets"
  value       = aws_subnet.public[*].availability_zone
}

output "public_subnet_details" {
  description = "Detailed information about public subnets"
  value = [
    for i, subnet in aws_subnet.public : {
      id                = subnet.id
      cidr              = subnet.cidr_block
      availability_zone = subnet.availability_zone
      name              = subnet.tags["Name"]
    }
  ]
}

output "public_subnets_per_az" {
  description = "Count of public subnets per availability zone"
  value       = local.public_subnets_per_az
}

# Private subnet outputs
output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = aws_subnet.private[*].id
}

output "private_subnet_cidrs" {
  description = "CIDR blocks of private subnets"
  value       = aws_subnet.private[*].cidr_block
}

output "private_subnet_azs" {
  description = "Availability zones of private subnets"
  value       = aws_subnet.private[*].availability_zone
}

output "private_subnet_details" {
  description = "Detailed information about private subnets"
  value = [
    for i, subnet in aws_subnet.private : {
      id                = subnet.id
      cidr              = subnet.cidr_block
      availability_zone = subnet.availability_zone
      name              = subnet.tags["Name"]
    }
  ]
}

output "private_subnets_per_az" {
  description = "Count of private subnets per availability zone"
  value       = local.private_subnets_per_az
}

# Route table outputs
output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public.id
}

output "private_route_table_id" {
  description = "ID of the private route table"
  value       = aws_route_table.private.id
}

# Summary output
output "infrastructure_summary" {
  description = "Summary of created infrastructure"
  value = {
    region              = var.aws_region
    vpc_id              = aws_vpc.main.id
    vpc_cidr            = aws_vpc.main.cidr_block
    environment         = var.environment
    available_azs       = length(data.aws_availability_zones.available.names)
    selected_azs        = local.az_count
    public_subnets      = var.public_subnet_count
    private_subnets     = var.private_subnet_count
    internet_gateway_id = aws_internet_gateway.main.id
  }
}

# Security Group Outputs
output "application_security_group_id" {
  description = "ID of the application security group"
  value       = aws_security_group.application.id
}

output "application_security_group_name" {
  description = "Name of the application security group"
  value       = aws_security_group.application.name
}

# AMI Outputs
output "ami_id_used" {
  description = "AMI ID used for the EC2 instance"
  value       = var.custom_ami_id != "" ? var.custom_ami_id : data.aws_ami.latest_custom_ami.id
}

output "ami_name" {
  description = "Name of the AMI used"
  value       = var.custom_ami_id != "" ? "Custom AMI specified" : data.aws_ami.latest_custom_ami.name
}

output "ami_creation_date" {
  description = "Creation date of the AMI"
  value       = var.custom_ami_id != "" ? "N/A" : data.aws_ami.latest_custom_ami.creation_date
}

# EC2 Instance Outputs
output "ec2_instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.web_application.id
}

output "ec2_instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.web_application.public_ip
}

output "ec2_instance_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.web_application.public_dns
}

output "ec2_instance_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.web_application.private_ip
}

output "ec2_instance_availability_zone" {
  description = "Availability zone of the EC2 instance"
  value       = aws_instance.web_application.availability_zone
}

# Application Access Information
output "application_endpoints" {
  description = "Application access endpoints"
  value = {
    health_check = "http://${aws_instance.web_application.public_ip}:${var.application_port}/healthz"
    base_url     = "http://${aws_instance.web_application.public_ip}:${var.application_port}"
    ssh_command  = "ssh -i <your-key.pem> admin@${aws_instance.web_application.public_ip}"
  }
}

# Complete Infrastructure Summary (Updated)
output "complete_infrastructure_summary" {
  description = "Complete summary of infrastructure"
  value = {
    # Network
    vpc_id             = aws_vpc.main.id
    vpc_cidr           = aws_vpc.main.cidr_block
    public_subnets     = length(aws_subnet.public)
    private_subnets    = length(aws_subnet.private)
    availability_zones = local.az_count

    # Security
    security_group_id = aws_security_group.application.id

    # Compute
    instance_id   = aws_instance.web_application.id
    instance_type = var.instance_type
    ami_id        = var.custom_ami_id != "" ? var.custom_ami_id : data.aws_ami.latest_custom_ami.id
    public_ip     = aws_instance.web_application.public_ip

    # Application
    application_port = var.application_port
    environment      = var.environment
    region           = var.aws_region
  }
}

# S3 Outputs
output "s3_bucket_name" {
  description = "S3 bucket name for product images"
  value       = aws_s3_bucket.product_images.bucket
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.product_images.arn
}

output "s3_bucket_region" {
  description = "S3 bucket region"
  value       = aws_s3_bucket.product_images.region
}

output "iam_role_arn" {
  description = "ARN of the IAM role for EC2 instances"
  value       = aws_iam_role.webapp_ec2_role.arn
}

output "iam_instance_profile_name" {
  description = "Name of the IAM instance profile"
  value       = aws_iam_instance_profile.webapp_instance_profile.name
}

output "s3_policy_arn" {
  description = "ARN of the S3 access policy"
  value       = aws_iam_policy.webapp_s3_policy.arn
}
