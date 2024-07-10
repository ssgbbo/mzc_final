resource "aws_acm_certificate" "dev_cert" {
  domain_name               = var.dev_subdomain_name
  validation_method         = "DNS"
  subject_alternative_names = [var.dev_subdomain_name]

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_route53_zone" "main_zone" {
  name         = var.domain_name
  private_zone = false
}

# ACM certificate validation resource using the certificate ARN and a list of validation record FQDNs.
resource "aws_acm_certificate_validation" "dev_cert" {
  certificate_arn         = aws_acm_certificate.dev_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.dev_cert_validation : record.fqdn]
}

# AWS Route53 record resource for certificate validation with dynamic for_each loop and properties for name, records, type, zone_id, and ttl.
resource "aws_route53_record" "dev_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.dev_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  type            = each.value.type
  zone_id         = data.aws_route53_zone.main_zone.zone_id
  ttl             = 60
}

# Route53 A 레코드 정의
resource "aws_route53_record" "dev_subdomain_name" {
  zone_id = data.aws_route53_zone.main_zone.zone_id
  name    = "${var.dev_subdomain_name}"
  type    = "A"

  alias {
    name                   = aws_alb.dev_application_load_balancer.dns_name
    zone_id                = aws_alb.dev_application_load_balancer.zone_id
    evaluate_target_health = true
  }
  depends_on = [ aws_alb.dev_application_load_balancer ]
}

