############################################
# Origin Access Control (OAC)
############################################
resource "aws_cloudfront_origin_access_control" "assets" {
  name                              = "${var.name_prefix}-oac"
  description                       = "OAC para bucket de assets"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

############################################
# Cache Policies
############################################
data "aws_cloudfront_cache_policy" "caching_optimized" {
  name = "Managed-CachingOptimized"
}

data "aws_cloudfront_cache_policy" "caching_disabled" {
  name = "Managed-CachingDisabled"
}

data "aws_cloudfront_origin_request_policy" "cors_s3" {
  name = "Managed-CORS-S3Origin"
}

data "aws_cloudfront_response_headers_policy" "security_headers" {
  name = "Managed-SecurityHeadersPolicy"
}

############################################
# WAF Web ACL (opcional)
############################################
resource "aws_wafv2_web_acl" "cdn" {
  count       = var.enable_waf ? 1 : 0
  provider    = aws
  name        = "${var.name_prefix}-waf"
  description = "WAF managed rules para CloudFront"
  scope       = "CLOUDFRONT"

  default_action {
    allow {}
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "commonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.name_prefix}-waf"
    sampled_requests_enabled   = true
  }
}

############################################
# CloudFront Distribution
############################################
resource "aws_cloudfront_distribution" "cdn" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${var.name_prefix} distribution"
  default_root_object = "index.html"
  price_class         = "PriceClass_All"
  aliases             = var.aliases
  web_acl_id          = var.enable_waf ? aws_wafv2_web_acl.cdn[0].arn : null

  origin {
    domain_name              = var.assets_bucket_regional_domain_name
    origin_id                = "s3-assets-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.assets.id
  }

  default_cache_behavior {
    target_origin_id         = "s3-assets-origin"
    viewer_protocol_policy   = "redirect-to-https"
    allowed_methods          = ["GET", "HEAD", "OPTIONS"]
    cached_methods           = ["GET", "HEAD"]
    compress                 = true
    cache_policy_id          = data.aws_cloudfront_cache_policy.caching_optimized.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.cors_s3.id

    lambda_function_association {
      event_type   = "viewer-response"
      lambda_arn   = var.lambda_edge_arn
      include_body = false
    }
  }

  ordered_cache_behavior {
    path_pattern           = "index.html"
    target_origin_id       = "s3-assets-origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    cache_policy_id        = data.aws_cloudfront_cache_policy.caching_disabled.id

    lambda_function_association {
      event_type   = "viewer-response"
      lambda_arn   = var.lambda_edge_arn
      include_body = false
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = var.acm_certificate_arn == "" ? true : null
    acm_certificate_arn            = var.acm_certificate_arn != "" ? var.acm_certificate_arn : null
    ssl_support_method             = var.acm_certificate_arn != "" ? "sni-only" : null
    minimum_protocol_version       = var.acm_certificate_arn != "" ? "TLSv1.2_2021" : null
  }

  logging_config {
    bucket          = var.logs_bucket_domain_name
    include_cookies = false
    prefix          = "cloudfront/"
  }

  custom_error_response {
    error_code         = 404
    response_code      = 404
    response_page_path = "/error.html"
  }
}

############################################
# Política del bucket assets (OAC)
############################################
data "aws_iam_policy_document" "assets_oac" {
  statement {
    sid    = "AllowCloudFrontOAC"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::${var.assets_bucket_id}/*"]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.cdn.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "assets" {
  bucket = var.assets_bucket_id
  policy = data.aws_iam_policy_document.assets_oac.json
}
