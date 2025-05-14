data "aws_route53_zone" "selected" {
  name         = var.domain_name
  private_zone = false
}

resource "aws_acm_certificate" "api" {
  domain_name       = "${var.api_subdomain}.${var.domain_name}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = local.tags
}

resource "aws_route53_record" "api_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.api.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  zone_id = data.aws_route53_zone.selected.zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "api" {
  certificate_arn         = aws_acm_certificate.api.arn
  validation_record_fqdns = [for record in aws_route53_record.api_cert_validation : record.fqdn]
}

resource "aws_route53_record" "api_custom_domain" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "${var.api_subdomain}.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_api_gateway_domain_name.api.regional_domain_name
    zone_id                = aws_api_gateway_domain_name.api.regional_zone_id
    evaluate_target_health = false
  }

  depends_on = [aws_api_gateway_domain_name.api]
} 