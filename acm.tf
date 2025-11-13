# acm.tf
# ============================================================================
# ACM CERTIFICATE WITH CONDITIONAL CREATION
# ============================================================================

# Create ACM certificate only if enabled (for dev account)
resource "aws_acm_certificate" "webapp" {
  count = var.enable_acm_certificate ? 1 : 0

  # Use subdomain for dev account
  domain_name       = var.subdomain != "" ? "${var.subdomain}.${var.domain_name}" : var.domain_name
  validation_method = "DNS"

  # No wildcard - just the specific subdomain
  subject_alternative_names = []

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.environment}-webapp-cert"
      Environment = var.environment
    }
  )
}

# DNS validation records (only for dev account)
resource "aws_route53_record" "cert_validation" {
  for_each = var.enable_acm_certificate ? {
    for dvo in aws_acm_certificate.webapp[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.route53_zone_id
}

# Certificate validation (only for dev account)
resource "aws_acm_certificate_validation" "webapp" {
  count = var.enable_acm_certificate ? 1 : 0

  certificate_arn         = aws_acm_certificate.webapp[0].arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]

  timeouts {
    create = "15m"  # Increased timeout
  }
}

# Output certificate ARN
output "acm_certificate_arn" {
  description = "ARN of the ACM certificate"
  value       = var.enable_acm_certificate ? aws_acm_certificate.webapp[0].arn : var.ssl_certificate_arn
}

output "acm_certificate_status" {
  description = "Status of the ACM certificate"
  value       = var.enable_acm_certificate ? aws_acm_certificate.webapp[0].status : "Imported"
}