# ============================================================================
# DNS & SSL CERTIFICATES
# ============================================================================

# Data source for existing hosted zone
data "aws_route53_zone" "existing" {
  count = var.create_route53_zone ? 0 : 1
  name  = var.route53_zone_name
}

# Create new hosted zone (conditional)
resource "aws_route53_zone" "main" {
  count = var.create_route53_zone ? 1 : 0
  name  = var.route53_zone_name
}

# Local to get the correct zone_id
locals {
  zone_id = var.create_route53_zone ? aws_route53_zone.main[0].zone_id : data.aws_route53_zone.existing[0].zone_id
}

# SSL Certificate
resource "aws_acm_certificate" "shopbot" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# Certificate validation DNS records
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.shopbot.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }


  allow_overwrite = true
  name            = each.value.name
  type            = each.value.type
  records         = [each.value.record]
  ttl             = 60
  zone_id         = local.zone_id
}

# Certificate validation
resource "aws_acm_certificate_validation" "shopbot" {
  certificate_arn         = aws_acm_certificate.shopbot.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

# DNS record pointing to load balancer
resource "aws_route53_record" "shopbot" {
  zone_id = local.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_lb.shopbot.dns_name
    zone_id                = aws_lb.shopbot.zone_id
    evaluate_target_health = true
  }
}
