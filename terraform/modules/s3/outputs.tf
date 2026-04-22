output "assets_bucket_id" {
  value = aws_s3_bucket.assets.id
}

output "assets_bucket_arn" {
  value = aws_s3_bucket.assets.arn
}

output "assets_bucket_regional_domain_name" {
  value = aws_s3_bucket.assets.bucket_regional_domain_name
}

output "uploads_bucket_id" {
  value = aws_s3_bucket.uploads.id
}

output "logs_bucket_id" {
  value = aws_s3_bucket.logs.id
}

output "logs_bucket_domain_name" {
  value = aws_s3_bucket.logs.bucket_domain_name
}
