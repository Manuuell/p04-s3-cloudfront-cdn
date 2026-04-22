# Setup AWS + OIDC para GitHub Actions

## 1. Pre-requisitos locales

| Herramienta | Versión mínima | Verificar |
|-------------|----------------|-----------|
| AWS CLI | v2 | `aws --version` |
| Terraform | ≥ 1.5 | `terraform -version` |
| Node.js | ≥ 20 | `node -v` |
| Git | ≥ 2.30 | `git --version` |
| jq | (recomendado) | `jq --version` |

## 2. Cuenta AWS

### 2.1 NO uses la cuenta root

Si estás logueado como root (`arn:aws:iam::...:root`), crea un usuario IAM dedicado:

```bash
# Verifica tu identidad actual
aws sts get-caller-identity
```

Si el ARN termina en `:root`, sigue el paso 2.2.

### 2.2 Crear usuario IAM administrador para el proyecto

1. Console → IAM → Users → **Create user** → `p04-admin`
2. Attach policies directly → `AdministratorAccess` (solo para el proyecto académico; en prod real usa least-privilege)
3. Crear access key → tipo "Command Line Interface (CLI)"
4. Guarda `AWS_ACCESS_KEY_ID` y `AWS_SECRET_ACCESS_KEY`

### 2.3 Configurar perfil local

```bash
aws configure --profile p04
# AWS Access Key ID:     <key>
# AWS Secret Access Key: <secret>
# Default region:        us-east-1
# Default output:        json

# Opcional: marcar como default
export AWS_PROFILE=p04
```

Verifica:

```bash
aws sts get-caller-identity --profile p04
```

## 3. Bootstrap del backend Terraform

El backend S3 + DynamoDB debe existir ANTES del primer `terraform init`.

```bash
./scripts/bootstrap.sh dev
./scripts/bootstrap.sh prod   # cuando toque
```

Esto crea:
- Bucket `tf-state-p04-<env>` (versionado, cifrado, sin acceso público)
- Tabla DynamoDB `tf-lock-p04` (billing on-demand)

## 4. OIDC para GitHub Actions (sin secretos de larga duración)

GitHub Actions se autenticará con AWS vía **OIDC federation** en vez de access keys. Más seguro y sin rotación manual.

### 4.1 Crear el identity provider

```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

### 4.2 Crear el rol asumible por GitHub Actions

Guarda como `trust-policy.json` (reemplaza `<ACCOUNT_ID>` y `<GH_USER>/<REPO>`):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::<ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:<GH_USER>/<REPO>:*"
        }
      }
    }
  ]
}
```

Crear rol:

```bash
aws iam create-role \
  --role-name gha-p04-deploy \
  --assume-role-policy-document file://trust-policy.json

aws iam attach-role-policy \
  --role-name gha-p04-deploy \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
```

Copia el ARN que devuelve (`arn:aws:iam::<ACCOUNT_ID>:role/gha-p04-deploy`).

### 4.3 Configurar secrets en GitHub

Repo → **Settings → Secrets and variables → Actions**:

| Secret | Valor |
|--------|-------|
| `AWS_DEPLOY_ROLE_ARN` | ARN del rol creado arriba |
| `ASSETS_BUCKET` | (después del primer apply) output `assets_bucket` |
| `CLOUDFRONT_DISTRIBUTION_ID` | (después del primer apply) output `cloudfront_distribution_id` |

## 5. Dominio (opcional para primer test)

Si aún no tienes dominio real, puedes:

- **Opción A — Dominio propio:** Registrarlo en Route 53 o apuntar nameservers de un proveedor externo a Route 53.
- **Opción B — Solo CloudFront:** Eliminar `module "acm"` y `module "route53"` del primer apply y usar el dominio por defecto `*.cloudfront.net`. Añadirlos después.

Para la opción B, comenta temporalmente los módulos en `terraform/main.tf` y elimina `aliases` y `viewer_certificate` de CloudFront.

## 6. Primer deploy (dev)

```bash
# 1. Bootstrap (una vez)
./scripts/bootstrap.sh dev

# 2. Init con backend
cd terraform
terraform init -backend-config=envs/dev/backend.hcl

# 3. Plan (revisa cambios)
terraform plan -var-file=envs/dev/terraform.tfvars

# 4. Apply
terraform apply -var-file=envs/dev/terraform.tfvars

# 5. Sync contenido web
aws s3 sync ../web/ s3://$(terraform output -raw assets_bucket) --delete

# 6. Invalidar caché
aws cloudfront create-invalidation \
  --distribution-id $(terraform output -raw cloudfront_distribution_id) \
  --paths "/*"
```

## 7. Destrucción (cleanup)

Para evitar costos al terminar el proyecto:

```bash
cd terraform

# Vaciar buckets (requerido antes de destroy si tienen versionado)
aws s3 rm s3://$(terraform output -raw assets_bucket) --recursive
aws s3 rm s3://$(terraform output -raw uploads_bucket) --recursive

terraform destroy -var-file=envs/dev/terraform.tfvars
```

⚠️ Lambda@Edge puede tardar hasta 1h en poder eliminarse (AWS propaga la replicación). Si `destroy` falla por eso, espera y reintenta.

## 8. Troubleshooting

| Error | Causa | Solución |
|-------|-------|----------|
| `Error: Unable to list provider registration status` | Disco lleno | Liberar espacio en `C:` |
| `BucketAlreadyOwnedByYou` | Bucket ya creado | Ignorar (bootstrap es idempotente) |
| `Certificate is in state PENDING_VALIDATION` | Route 53 NS no propagados | Verificar que los NS del dominio apunten a Route 53 |
| Lambda@Edge falla al destroy | Réplicas aún en edge locations | Esperar 1h y reintentar |
| `Error: error creating S3 Bucket (...): BucketAlreadyExists` | Nombre global ya tomado | Cambiar `project_name` en tfvars |

## 9. Costos estimados (dev)

| Recurso | Costo mensual aprox |
|---------|---------------------|
| S3 (3 buckets, < 1GB) | < $0.05 |
| CloudFront (1000 requests/mes) | < $0.10 |
| Route 53 hosted zone | $0.50 |
| ACM certificate | Gratis |
| Lambda@Edge | < $0.01 (free tier) |
| DynamoDB (on-demand, bajo uso) | < $0.01 |
| **Total estimado** | **< $1/mes** |

> Configura un **Budget Alert** en AWS Billing para recibir email si superas $5/mes.
