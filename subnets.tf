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