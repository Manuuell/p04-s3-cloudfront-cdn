provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

# CloudFront + ACM + Lambda@Edge requieren us-east-1
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = local.common_tags
  }
}

locals {
  common_tags = {
    Project     = "P04-Almacenamiento-CDN"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = var.owner
  }

  name_prefix = "${var.project_name}-${var.environment}"
}

module "s3" {
  source = "./modules/s3"

  name_prefix                = local.name_prefix
  logs_retention_days        = var.logs_retention_days
  uploads_ia_transition      = var.uploads_ia_transition_days
  uploads_glacier_transition = var.uploads_glacier_transition_days
  uploads_expiration_days    = var.uploads_expiration_days
}

module "route53" {
  source = "./modules/route53"
  count  = var.use_custom_domain ? 1 : 0

  domain_name               = var.domain_name
  cloudfront_domain_name    = module.cloudfront.distribution_domain_name
  cloudfront_hosted_zone_id = module.cloudfront.distribution_hosted_zone_id
}

module "acm" {
  source = "./modules/acm"
  count  = var.use_custom_domain ? 1 : 0
  providers = {
    aws = aws.us_east_1
  }

  domain_name               = var.domain_name
  route53_zone_id           = module.route53[0].zone_id
  subject_alternative_names = var.subject_alternative_names
}

module "lambda_edge" {
  source = "./modules/lambda_edge"
  providers = {
    aws = aws.us_east_1
  }

  function_name = "${local.name_prefix}-security-headers"
  source_dir    = "${path.module}/../lambda/security-headers"
}

module "cloudfront" {
  source = "./modules/cloudfront"

  name_prefix                        = local.name_prefix
  assets_bucket_id                   = module.s3.assets_bucket_id
  assets_bucket_regional_domain_name = module.s3.assets_bucket_regional_domain_name
  logs_bucket_domain_name            = module.s3.logs_bucket_domain_name
  acm_certificate_arn                = var.use_custom_domain ? module.acm[0].certificate_arn : ""
  aliases                            = var.use_custom_domain ? concat([var.domain_name], var.subject_alternative_names) : []
  lambda_edge_arn                    = module.lambda_edge.qualified_arn
  enable_waf                         = var.enable_waf
}
