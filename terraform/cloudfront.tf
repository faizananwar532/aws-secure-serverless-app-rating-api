resource "aws_cloudfront_distribution" "api_distribution" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CloudFront distribution for API Gateway"

  logging_config {
    bucket          = aws_s3_bucket.logs.bucket_domain_name
    include_cookies = true
    prefix          = "cloudfront-logs/"
  }

  origin {
    domain_name = replace(aws_apigatewayv2_api.http_api.api_endpoint, "https://", "")
    origin_id   = "api-gateway-origin"
    custom_origin_config {
      http_port              = 443
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }

    custom_header {
      name  = "X-Origin-Token"
      value = var.cloudfront_origin_token
    }
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "POST", "PUT", "PATCH", "DELETE"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    target_origin_id       = "api-gateway-origin"
    viewer_protocol_policy = "redirect-to-https"

    cache_policy_id          = data.aws_cloudfront_cache_policy.caching_disabled.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewer_except_host_header.id
  }


  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn            = "arn:aws:acm:us-east-1:992382560483:certificate/6edc2b01-2517-4c56-8610-25f1e909dec3"
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = "TLSv1.2_2021"
  }

  web_acl_id = aws_wafv2_web_acl.cloudfront_acl.arn

  aliases = ["api.cloudsredevops.com"]
}

resource "aws_route53_record" "cloudfront" {
  name    = "api.cloudsredevops.com"
  type    = "A"
  zone_id = var.route53zoneid
  alias {
    name                   = aws_cloudfront_distribution.api_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.api_distribution.hosted_zone_id
    evaluate_target_health = true
  }
}

resource "aws_s3_bucket" "logs" {
  bucket = "cloud-sre-devops-secrets-v2"
}

resource "aws_s3_bucket_ownership_controls" "logs" {
  bucket = aws_s3_bucket.logs.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "logs" {
  depends_on = [aws_s3_bucket_ownership_controls.logs]
  bucket = aws_s3_bucket.logs.id
  acl    = "log-delivery-write"
}

resource "aws_s3_bucket_versioning" "logs" {
  bucket = aws_s3_bucket.logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id
  rule {
    id     = "cleanup"
    status = "Enabled"
    filter {
      prefix = "cloudfront-logs/"
    }
    expiration {
      days = 90
    }
  }
}


data "aws_cloudfront_cache_policy" "caching_disabled" {
  name = "Managed-CachingDisabled"
}

data "aws_cloudfront_origin_request_policy" "all_viewer_except_host_header" {
  name = "Managed-AllViewerExceptHostHeader"
}
