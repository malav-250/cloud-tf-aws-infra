# Data source to get available AZs in the region
data "aws_availability_zones" "available" {
  state = "available"

  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

# Local values for computed configurations
locals {
  # Determine which AZs to use
  all_available_azs = data.aws_availability_zones.available.names

  # If specific AZs provided, use those; otherwise use first N available AZs
  selected_azs = length(var.availability_zones) > 0 ? var.availability_zones : slice(
    local.all_available_azs,
    0,
    min(var.az_count, length(local.all_available_azs))
  )

  # Number of selected AZs
  az_count = length(local.selected_azs)

  # Create mappings for subnet to AZ distribution
  # This cycles through AZs if subnet count > AZ count
  public_subnet_az_mapping = {
    for i in range(var.public_subnet_count) : i => local.selected_azs[i % local.az_count]
  }

  private_subnet_az_mapping = {
    for i in range(var.private_subnet_count) : i => local.selected_azs[i % local.az_count]
  }

  # Count subnets per AZ for better visibility
  public_subnets_per_az = {
    for az in local.selected_azs : az => length([
      for idx, mapped_az in local.public_subnet_az_mapping : idx if mapped_az == az
    ])
  }

  private_subnets_per_az = {
    for az in local.selected_azs : az => length([
      for idx, mapped_az in local.private_subnet_az_mapping : idx if mapped_az == az
    ])
  }
}

# Create VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = {
    Name = "${var.vpc_name}-vpc"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.vpc_name}-igw"
  }
}

# Create Public Subnets (dynamically calculated CIDRs)
resource "aws_subnet" "public" {
  count = var.public_subnet_count

  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, var.subnet_cidr_newbits, count.index)
  availability_zone       = local.public_subnet_az_mapping[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.vpc_name}-public-subnet-${count.index + 1}"
    Type = "Public"
    AZ   = local.public_subnet_az_mapping[count.index]
  }
}

# Create Private Subnets (dynamically calculated CIDRs with offset)
resource "aws_subnet" "private" {
  count = var.private_subnet_count

  vpc_id = aws_vpc.main.id
  # Offset by 100 to ensure clear separation from public subnets
  cidr_block        = cidrsubnet(var.vpc_cidr, var.subnet_cidr_newbits, count.index + 100)
  availability_zone = local.private_subnet_az_mapping[count.index]

  tags = {
    Name = "${var.vpc_name}-private-subnet-${count.index + 1}"
    Type = "Private"
    AZ   = local.private_subnet_az_mapping[count.index]
  }
}

# Create Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.vpc_name}-public-rt"
  }
}

# Create Private Route Table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.vpc_name}-private-rt"
  }
}

# Create route to Internet Gateway in Public Route Table
resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

# Associate Public Subnets with Public Route Table
resource "aws_route_table_association" "public" {
  count          = var.public_subnet_count
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Associate Private Subnets with Private Route Table
resource "aws_route_table_association" "private" {
  count          = var.private_subnet_count
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}