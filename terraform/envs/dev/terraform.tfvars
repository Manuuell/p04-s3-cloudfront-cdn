environment  = "dev"
project_name = "p04-cdn"
aws_region   = "us-east-1"

# Sin dominio propio → CloudFront expone https://<id>.cloudfront.net
use_custom_domain         = false
domain_name               = ""
subject_alternative_names = []

logs_retention_days             = 30
uploads_ia_transition_days      = 30
uploads_glacier_transition_days = 90
uploads_expiration_days         = 180

enable_waf = false
