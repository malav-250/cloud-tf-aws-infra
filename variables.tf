# Region configuration
variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "vpc_name" {
  description = "Name prefix for VPC and related resources"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, demo, prod)"
  type        = string
  default     = "dev"
}

# VPC CIDR block
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block"
  }
}

# Availability Zone configuration
variable "availability_zones" {
  description = "List of specific availability zones to use (leave empty to use all available)"
  type        = list(string)
  default     = []
}

variable "az_count" {
  description = "Number of availability zones to use (only used if availability_zones is empty)"
  type        = number
  default     = 3

  validation {
    condition     = var.az_count >= 1 && var.az_count <= 10
    error_message = "AZ count must be between 1 and 10"
  }
}

# Subnet configuration
variable "public_subnet_count" {
  description = "Number of public subnets to create"
  type        = number
  default     = 3

  validation {
    condition     = var.public_subnet_count >= 1 && var.public_subnet_count <= 20
    error_message = "Public subnet count must be between 1 and 20"
  }
}

variable "private_subnet_count" {
  description = "Number of private subnets to create"
  type        = number
  default     = 3

  validation {
    condition     = var.private_subnet_count >= 1 && var.private_subnet_count <= 20
    error_message = "Private subnet count must be between 1 and 20"
  }
}

# Subnet CIDR sizing
variable "subnet_cidr_newbits" {
  description = "Number of bits to add to VPC CIDR for subnets (8 = /24 subnets from /16 VPC)"
  type        = number
  default     = 8

  validation {
    condition     = var.subnet_cidr_newbits >= 4 && var.subnet_cidr_newbits <= 16
    error_message = "Subnet newbits must be between 4 and 16"
  }
}

# Enable/disable DNS settings
variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Enable DNS support in the VPC"
  type        = bool
  default     = true
}