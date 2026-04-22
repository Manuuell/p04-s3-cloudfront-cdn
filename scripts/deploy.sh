#!/usr/bin/env bash
# Uso: ./scripts/deploy.sh <env>
# Ejemplo: ./scripts/deploy.sh dev
set -euo pipefail

ENV="${1:-dev}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if [[ ! -d "$ROOT/terraform/envs/$ENV" ]]; then
  echo "Error: entorno '$ENV' no existe en terraform/envs/" >&2
  exit 1
fi

echo "==> Terraform init ($ENV)"
terraform -chdir="$ROOT/terraform" init -backend-config="envs/$ENV/backend.hcl" -reconfigure

echo "==> Terraform apply ($ENV)"
terraform -chdir="$ROOT/terraform" apply -auto-approve -var-file="envs/$ENV/terraform.tfvars"

ASSETS_BUCKET=$(terraform -chdir="$ROOT/terraform" output -raw assets_bucket)
DIST_ID=$(terraform -chdir="$ROOT/terraform" output -raw cloudfront_distribution_id)

echo "==> Sync web/ -> s3://$ASSETS_BUCKET"
aws s3 sync "$ROOT/web/" "s3://$ASSETS_BUCKET" --delete

echo "==> Invalidando CloudFront ($DIST_ID)"
aws cloudfront create-invalidation --distribution-id "$DIST_ID" --paths "/*" >/dev/null

echo "==> Despliegue completado."
