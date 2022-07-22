output "website_cdn_root_id" {
  description = "Main CloudFront Distribution ID"
  value       = aws_cloudfront_distribution.website_cdn.id
}

output "website_files_s3_bucket" {
  description = "The website root bucket where resources are uploaded"
  value       = aws_s3_bucket.website_files.bucket
}
