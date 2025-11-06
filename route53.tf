# ========================================
# Route53 A Record (Alias to ALB)
# ========================================

resource "aws_route53_record" "webapp" {
  zone_id = var.route53_zone_id
  name    = var.subdomain != "" ? "${var.subdomain}.${var.domain_name}" : var.domain_name
  type    = "A"

  alias {
    name                   = aws_lb.application.dns_name
    zone_id                = aws_lb.application.zone_id
    evaluate_target_health = true
  }
}
