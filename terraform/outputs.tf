output "cloudfront_url" {
  description = "URL de la distribución CloudFront."
  value       = "https://${module.cloudfront.distribution_domain_name}"
}

output "cloudfront_distribution_id" {
  value = module.cloudfront.distribution_id
}

output "assets_bucket" {
  value = module.s3.assets_bucket_id
}

output "uploads_bucket" {
  value = module.s3.uploads_bucket_id
}

output "logs_bucket" {
  value = module.s3.logs_bucket_id
}

output "route53_nameservers" {
  description = "Nameservers de Route53 (solo si use_custom_domain=true)."
  value       = var.use_custom_domain ? module.route53[0].nameservers : []
}

output "custom_domain" {
  value = var.use_custom_domain ? var.domain_name : "(sin dominio personalizado)"
}
