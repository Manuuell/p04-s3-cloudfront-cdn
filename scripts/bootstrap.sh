#!/usr/bin/env bash
# Bootstrap del backend de Terraform: crea el bucket S3 para el tfstate
# y la tabla DynamoDB para locking. Ejecutar UNA VEZ antes del primer `terraform init`.
#
# Uso:
#   ./scripts/bootstrap.sh <env>
#   ./scripts/bootstrap.sh dev
#
# Variables opcionales:
#   AWS_REGION    (default: us-east-1)
#   BUCKET_NAME   (default: tf-state-p04-<env>)
#   TABLE_NAME    (default: tf-lock-p04)

set -euo pipefail

ENV="${1:-dev}"
REGION="${AWS_REGION:-us-east-1}"
BUCKET="${BUCKET_NAME:-tf-state-p04-$ENV}"
TABLE="${TABLE_NAME:-tf-lock-p04}"

echo "==> Bootstrap backend Terraform"
echo "    Env:    $ENV"
echo "    Region: $REGION"
echo "    Bucket: $BUCKET"
echo "    Table:  $TABLE"
echo

# ---------- Bucket ----------
if aws s3api head-bucket --bucket "$BUCKET" 2>/dev/null; then
  echo "✔ Bucket $BUCKET ya existe"
else
  echo "==> Creando bucket $BUCKET"
  if [[ "$REGION" == "us-east-1" ]]; then
    aws s3api create-bucket --bucket "$BUCKET" --region "$REGION"
  else
    aws s3api create-bucket --bucket "$BUCKET" --region "$REGION" \
      --create-bucket-configuration "LocationConstraint=$REGION"
  fi

  echo "==> Habilitando versionado"
  aws s3api put-bucket-versioning --bucket "$BUCKET" \
    --versioning-configuration Status=Enabled

  echo "==> Habilitando cifrado SSE-S3"
  aws s3api put-bucket-encryption --bucket "$BUCKET" \
    --server-side-encryption-configuration '{
      "Rules": [{
        "ApplyServerSideEncryptionByDefault": { "SSEAlgorithm": "AES256" }
      }]
    }'

  echo "==> Bloqueando acceso público"
  aws s3api put-public-access-block --bucket "$BUCKET" \
    --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
fi

# ---------- DynamoDB ----------
if aws dynamodb describe-table --table-name "$TABLE" --region "$REGION" >/dev/null 2>&1; then
  echo "✔ Tabla $TABLE ya existe"
else
  echo "==> Creando tabla DynamoDB $TABLE"
  aws dynamodb create-table \
    --table-name "$TABLE" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region "$REGION" >/dev/null

  echo "==> Esperando a que la tabla esté ACTIVE..."
  aws dynamodb wait table-exists --table-name "$TABLE" --region "$REGION"
fi

echo
echo "✅ Bootstrap completado."
echo
echo "Siguiente paso:"
echo "  cd terraform"
echo "  terraform init -backend-config=envs/$ENV/backend.hcl"
