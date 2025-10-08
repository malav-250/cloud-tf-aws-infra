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