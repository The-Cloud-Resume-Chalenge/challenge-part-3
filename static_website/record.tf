resource "aws_route53_record" "a_record" {
  count = var.custom_domain_exists ? 1 : 0
  provider = aws.abd
  zone_id  = data.aws_route53_zone.public_zone[count.index].zone_id
  name     = var.dns
  type     = "A"

  alias {
    name                   = aws_cloudfront_distribution.product_s3_distribution.domain_name
    zone_id                = "Z2FDTNDATAQYW2" # Fixed CloudFront distribution zone ID
    evaluate_target_health = false
  }

  depends_on = [
    aws_cloudfront_distribution.product_s3_distribution
  ]
}