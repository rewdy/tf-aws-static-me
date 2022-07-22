terraform {
  required_version = ">=0.12"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Merge tags to use elsewhere
locals {
  tags = merge(var.tags, {
    ManagedBy = "terraform"
    Changed   = formatdate("YYYY-MM-DD hh:mm ZZZ", timestamp())
  })
}

# Provider
provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}

## Route 53
# Provides details about the zone
data "aws_route53_zone" "main" {
  name         = var.domain_hosted_zone
  private_zone = false
}

## ACM
# Create certificate if one not specified in vars
resource "aws_acm_certificate" "website" {
  count             = var.create_certificate == true ? 1 : 0
  provider          = aws.us-east-1 # all certs go in us-east-1
  domain_name       = var.domain_name
  validation_method = "DNS"

  tags = local.tags

  lifecycle {
    ignore_changes = [tags["Changed"]]
  }
}

# Validates the ACM cert by creating a Route53 record 
# NOTE: this works because `validation_method` is `DNS` above
resource "aws_route53_record" "cert_validation" {
  count = var.create_certificate == true ? 1 : 0
  for_each = {
    for dvo in aws_acm_certificate.website[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
  name            = each.value.name
  type            = each.value.type
  zone_id         = data.aws_route53_zone.main.zone_id
  records         = [each.value.record]
  allow_overwrite = true
  ttl             = "60"
}

# Triggers the ACM wildcard certificate validation event
resource "aws_acm_certificate_validation" "website_cert" {
  count                   = var.create_certificate == true ? 1 : 0
  provider                = aws.us-east-1
  certificate_arn         = aws_acm_certificate.website[0].arn
  validation_record_fqdns = [for k, v in aws_route53_record.cert_validation : v.fqdn]
}

# Get the ARN of the issued certificate
data "aws_acm_certificate" "website" {
  provider = aws.us-east-1

  depends_on = var.create_certificate == true ? [
    aws_acm_certificate.wildcard_website,
    aws_route53_record.wildcard_validation,
    aws_acm_certificate_validation.wildcard_cert,
  ] : null

  domain      = var.domain_name
  statuses    = ["ISSUED"]
  most_recent = true
}

## S3
# Bucket for website files
resource "aws_s3_bucket" "website_files" {
  bucket = "${var.domain_name}-files"
  acl    = "public-read"

  force_destroy = true

  cors_rule {
    allowed_headers = ["Authorization", "Content-Length"]
    allowed_methods = ["GET", "POST"]
    allowed_origins = ["https://${var.domain_name}"]
    max_age_seconds = 3000
  }

  website {
    index_document = "index.html"
    error_document = var.support_spa ? "" : "404.html"
  }

  tags = local.tags

  lifecycle {
    ignore_changes = [tags["Changed"]]
  }
}

## Cloudfront
# Creates cloudfront distro to serve the static site
resource "aws_cloudfront_distribution" "website_cdn" {
  enabled     = true
  price_class = var.cloudfront_price_class

  origin {
    origin_id   = "origin-bucket-${aws_s3_bucket.website_files.id}"
    domain_name = aws_s3_bucket.website_files.website_endpoint

    custom_origin_config {
      origin_protocol_policy = "http-only"
      # The protocol policy that you want CloudFront to use when fetching objects from the origin server (a.k.a S3 in our situation). HTTP Only is the default setting when the origin is an Amazon S3 static website hosting endpoint, because Amazon S3 doesn’t support HTTPS connections for static website hosting endpoints.
      http_port            = 80
      https_port           = 443
      origin_ssl_protocols = ["TLSv1.2", "TLSv1.1", "TLSv1"]
    }
  }

  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "origin-bucket-${aws_s3_bucket.website_files.id}"
    min_ttl          = "0"
    default_ttl      = "300"
    max_ttl          = "1200"

    viewer_protocol_policy = "redirect-to-https" # Redirects any HTTP request to HTTPS
    compress               = true

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = data.aws_acm_certificate.website.arn
    ssl_support_method  = "sni-only"
  }

  custom_error_response {
    error_caching_min_ttl = 300
    error_code            = 404
    response_page_path    = var.support_spa ? "/index.html" : "/404.html"
    response_code         = var.support_spa ? 200 : 404
  }

  tags = tags

  lifecycle {
    ignore_changes = [
      tags["Changed"],
      viewer_certificate,
    ]
  }
}

## Route 53
# DNS record
resource "aws_route53_record" "website_cdn_root_record" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.website_cdn.domain_name
    zone_id                = aws_cloudfront_distribution.website_cdn.hosted_zone_id
    evaluate_target_health = false
  }
}

## IAM
# Creates policy to allow public access to the S3 bucket
resource "aws_s3_bucket_policy" "update_website_root_bucket_policy" {
  bucket = aws_s3_bucket.website_files.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "PolicyForWebsiteEndpointsPublicContent",
  "Statement": [
    {
      "Sid": "PublicRead",
      "Effect": "Allow",
      "Principal": "*",
      "Action": [
        "s3:GetObject"
      ],
      "Resource": [
        "${aws_s3_bucket.website_files.arn}/*",
        "${aws_s3_bucket.website_files.arn}"
      ]
    }
  ]
}
POLICY
}