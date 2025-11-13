# ========================================
# Application Load Balancer Security Group
# ========================================

resource "aws_security_group" "load_balancer" {
  name        = "${var.environment}-load-balancer-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = aws_vpc.main.id


  # Allow HTTPS traffic from anywhere (IPv4)
  ingress {
    description = "HTTPS from Internet (IPv4)"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTPS traffic from anywhere (IPv6)
  ingress {
    description      = "HTTPS from Internet (IPv6)"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    ipv6_cidr_blocks = ["::/0"]
  }

  # Allow all outbound traffic (IPv4)
  egress {
    description = "All outbound traffic (IPv4)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic (IPv6)
  egress {
    description      = "All outbound traffic (IPv6)"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name        = "${var.environment}-load-balancer-sg"
    Environment = var.environment
  }
}

# ========================================
# Application Security Group
# ========================================

resource "aws_security_group" "application" {
  name        = "${var.environment}-application-sg"
  description = "Security group for web application instances"
  vpc_id      = aws_vpc.main.id

  # Application port - ONLY from Load Balancer
  # No need for IPv6 here since traffic comes from ALB security group
  ingress {
    description     = "Application port from Load Balancer"
    from_port       = var.application_port
    to_port         = var.application_port
    protocol        = "tcp"
    security_groups = [aws_security_group.load_balancer.id]
  }

  # Allow all outbound traffic (IPv4)
  egress {
    description = "All outbound traffic (IPv4)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic (IPv6)
  egress {
    description      = "All outbound traffic (IPv6)"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name        = "${var.environment}-application-sg"
    Environment = var.environment
  }
}

# ========================================
# Database Security Group
# ========================================

resource "aws_security_group" "database" {
  name        = "${var.environment}-database-sg"
  description = "Security group for RDS database"
  vpc_id      = aws_vpc.main.id

  # PostgreSQL access from application instances only
  ingress {
    description     = "PostgreSQL from Application"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.application.id]
  }

  # Allow all outbound traffic (IPv4)
  egress {
    description = "All outbound traffic (IPv4)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic (IPv6)
  egress {
    description      = "All outbound traffic (IPv6)"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name        = "${var.environment}-database-sg"
    Environment = var.environment
  }
}