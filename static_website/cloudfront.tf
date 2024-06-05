resource "aws_cloudfront_distribution" "product_s3_distribution" {
  provider = aws.abd
  origin {
    domain_name = aws_s3_bucket.majid.bucket_regional_domain_name
    origin_id   = "${aws_s3_bucket.majid.id}-origin"
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CloudFront distribution for staging"
  default_root_object = var.index_document # Setting cv.html as the root object

  aliases = var.custom_domain_exists ? [var.dns] : []

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "${aws_s3_bucket.majid.id}-origin" # This needs to match the origin_id

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https" # Redirect HTTP to HTTPS
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

viewer_certificate {
    acm_certificate_arn = element(concat(aws_acm_certificate.default.*.arn, tolist([""])), 0)
    cloudfront_default_certificate = var.custom_domain_exists ? null : true
    ssl_support_method  = "sni-only"
}

  # 'depends_on' might not be necessary, but you can keep it if you encounter issues with dependencies.
  depends_on = [aws_acm_certificate.default]
}