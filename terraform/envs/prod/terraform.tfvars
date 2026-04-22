environment  = "prod"
project_name = "p04-cdn"
aws_region   = "us-east-1"

domain_name               = "cdn.ejemplo.com"
subject_alternative_names = ["www.cdn.ejemplo.com"]

logs_retention_days             = 90
uploads_ia_transition_days      = 30
uploads_glacier_transition_days = 90
uploads_expiration_days         = 365

enable_waf = true
