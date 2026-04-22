#!/usr/bin/env bash
# Invalida el caché de CloudFront.
# Uso: ./scripts/invalidate.sh <distribution-id> [paths...]
set -euo pipefail

DIST_ID="${1:?distribution-id requerido}"
shift || true
PATHS=("${@:-/*}")

aws cloudfront create-invalidation \
  --distribution-id "$DIST_ID" \
  --paths "${PATHS[@]}"
