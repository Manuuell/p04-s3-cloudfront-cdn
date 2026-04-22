############################################
# Bucket ASSETS — hosting estático via CloudFront (OAC)
############################################
resource "aws_s3_bucket" "assets" {
  bucket = "${var.name_prefix}-assets"
}

resource "aws_s3_bucket_versioning" "assets" {
  bucket = aws_s3_bucket.assets.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "assets" {
  bucket = aws_s3_bucket.assets.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "assets" {
  bucket                  = aws_s3_bucket.assets.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Política que permite lectura solo desde CloudFront OAC (la distribution ID se inyecta via variable si se necesita aquí)
# TODO: adjuntar aws_s3_bucket_policy referenciando aws:SourceArn de la distribución.

############################################
# Bucket UPLOADS — archivos de usuarios
############################################
resource "aws_s3_bucket" "uploads" {
  bucket = "${var.name_prefix}-uploads"
}

resource "aws_s3_bucket_public_access_block" "uploads" {
  bucket                  = aws_s3_bucket.uploads.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "uploads" {
  bucket = aws_s3_bucket.uploads.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_cors_configuration" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  cors_rule {
    allowed_methods = ["GET", "PUT", "POST"]
    allowed_origins = ["*"] # TODO: restringir a dominios conocidos en prod
    allowed_headers = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  rule {
    id     = "uploads-lifecycle"
    status = "Enabled"

    filter {}

    transition {
      days          = var.uploads_ia_transition
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = var.uploads_glacier_transition
      storage_class = "GLACIER"
    }

    expiration {
      days = var.uploads_expiration_days
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

############################################
# Bucket LOGS — logs de CloudFront
############################################
resource "aws_s3_bucket" "logs" {
  bucket        = "${var.name_prefix}-logs"
  force_destroy = true
}

resource "aws_s3_bucket_ownership_controls" "logs" {
  bucket = aws_s3_bucket.logs.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket                  = aws_s3_bucket.logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "logs-expiration"
    status = "Enabled"
    filter {}

    expiration {
      days = var.logs_retention_days
    }
  }
}
