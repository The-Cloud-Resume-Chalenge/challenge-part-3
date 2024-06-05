# Assuming you want to reference an existing hosted zone
data "aws_route53_zone" "public_zone" {
  count = var.custom_domain_exists ? 1 : 0
  provider = aws.abd
  name     = "${var.dns}." # The trailing dot is important!
}



resource "aws_acm_certificate" "default" {
  count = var.custom_domain_exists ? 1 : 0
  provider                  = aws.abd
  domain_name               = var.dns
  subject_alternative_names = [format("*.%s", var.dns)]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "validation" {
  count = var.custom_domain_exists ? 1 : 0
  provider = aws.abd
  zone_id  = data.aws_route53_zone.public_zone[count.index].zone_id
  name     = tolist(aws_acm_certificate.default[count.index].domain_validation_options)[0].resource_record_name
  type     = tolist(aws_acm_certificate.default[count.index].domain_validation_options)[0].resource_record_type
  records  = [tolist(aws_acm_certificate.default[count.index].domain_validation_options)[0].resource_record_value]
  ttl      = 60
}