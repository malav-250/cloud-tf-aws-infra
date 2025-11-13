# Create VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  assign_generated_ipv6_cidr_block = true

  tags = {
    Name = "${var.vpc_name}-vpc"
  }
}