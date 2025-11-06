# ========================================
# Application Load Balancer
# ========================================

resource "aws_lb" "application" {
  name               = var.alb_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.load_balancer.id]

  # Use public subnets across multiple AZs for high availability
  subnets = aws_subnet.public[*].id

  enable_deletion_protection = false
  enable_http2               = true

  tags = {
    Name        = var.alb_name
    Environment = var.environment
  }
}

# ========================================
# Target Group
# ========================================

resource "aws_lb_target_group" "application" {
  name     = "${var.environment}-app-tg"
  port     = var.application_port
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  # Health check configuration
  health_check {
    enabled             = true
    path                = var.health_check_path
    protocol            = "HTTP"
    port                = "traffic-port"
    interval            = var.health_check_interval
    timeout             = var.health_check_timeout
    healthy_threshold   = var.healthy_threshold
    unhealthy_threshold = var.unhealthy_threshold
    matcher             = "200"
  }

  # Deregistration delay
  deregistration_delay = 30

  # Stickiness (not required for stateless apps, but useful for testing)
  stickiness {
    type            = "lb_cookie"
    enabled         = false
    cookie_duration = 86400
  }

  tags = {
    Name        = "${var.environment}-app-tg"
    Environment = var.environment
  }
}

# ========================================
# HTTP Listener (Port 80)
# ========================================

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.application.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.application.arn
  }

  tags = {
    Name        = "${var.environment}-http-listener"
    Environment = var.environment
  }
}

# ========================================
# HTTPS Listener (Port 443) - Optional
# ========================================
# Uncomment and configure if you add SSL certificate

# resource "aws_lb_listener" "https" {
#   load_balancer_arn = aws_lb.application.arn
#   port              = 443
#   protocol          = "HTTPS"
#   ssl_policy        = "ELBSecurityPolicy-2016-08"
#   certificate_arn   = var.ssl_certificate_arn
#
#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.application.arn
#   }
#
#   tags = {
#     Name        = "${var.environment}-https-listener"
#     Environment = var.environment
#   }
# }