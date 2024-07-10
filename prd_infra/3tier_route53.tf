resource "aws_acm_certificate" "cert" {
  domain_name               = var.domain_name
  validation_method         = "DNS"
  subject_alternative_names = [var.domain_name, "www.${var.domain_name}", "book.${var.domain_name}"]

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_route53_zone" "zone" {
  name         = var.domain_name 
  private_zone = false
}

# ACM certificate validation resource using the certificate ARN and a list of validation record FQDNs.
resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

# AWS Route53 record resource for certificate validation with dynamic for_each loop and properties for name, records, type, zone_id, and ttl.
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  type            = each.value.type
  zone_id         = data.aws_route53_zone.zone.zone_id
  ttl             = 60
}

# Route53 A 레코드 정의
resource "aws_route53_record" "minzs-domain" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = "${var.domain_name }"
  type    = "A"

  alias {
    name                   = aws_alb.application_load_balancer.dns_name
    zone_id                = aws_alb.application_load_balancer.zone_id
    evaluate_target_health = true
  }
  depends_on = [ aws_alb.application_load_balancer ]
  # depends_on = [ aws_cloudfront_distribution.prd-lsb-cdn-distribution ]
}

resource "aws_route53_record" "www-minzs-domain" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = "www.${var.domain_name }"
  type    = "A"

  alias {
    name                   = aws_alb.application_load_balancer.dns_name
    zone_id                = aws_alb.application_load_balancer.zone_id
    evaluate_target_health = true
  }
  depends_on = [ aws_alb.application_load_balancer ]
  # depends_on = [ aws_cloudfront_distribution.prd-lsb-cdn-distribution ]
}

resource "aws_route53_record" "book_domain" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = "book.${var.domain_name }"
  type    = "A"

  alias {
    name                   = aws_alb.application_load_balancer.dns_name
    zone_id                = aws_alb.application_load_balancer.zone_id
    evaluate_target_health = true
  }
  depends_on = [ aws_alb.application_load_balancer ]
  # depends_on = [ aws_cloudfront_distribution.prd-lsb-cdn-distribution ]
}
