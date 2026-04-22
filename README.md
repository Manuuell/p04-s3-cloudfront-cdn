# P04 — Plataforma de Almacenamiento de Objetos con CDN Global en AWS

Proyecto académico de Infraestructura como Código & DevOps.

> **🌐 Sitio en vivo:** https://d14x2vaw9f2mo1.cloudfront.net
> **📊 Grade de seguridad:** A+ en [securityheaders.com](https://securityheaders.com/?q=d14x2vaw9f2mo1.cloudfront.net)

---

## 👥 Acceso del equipo (sustentación)

### Consola web AWS (solo lectura)

| Campo          | Valor                                                   |
|----------------|---------------------------------------------------------|
| Console URL    | https://578273200095.signin.aws.amazon.com/console      |
| Usuario IAM    | `p04-team`                                              |
| Región         | `us-east-1` (N. Virginia)                               |
| Permisos       | `ReadOnlyAccess` + `IAMUserChangePassword`              |
| Password       | *(compartido por WhatsApp del grupo)*                   |

### Acceso programático (CLI)

Las `AccessKeyId` y `SecretAccessKey` se comparten **únicamente por canal privado** — nunca en este repositorio.

```bash
aws configure --profile p04
# Region: us-east-1
# Output: json

export AWS_PROFILE=p04   # PowerShell: $env:AWS_PROFILE = "p04"

aws sts get-caller-identity        # verificar que entraste
aws s3 ls | grep p04                # deberías ver 4 buckets
```

---

## 🧪 Correr los tests de la Lambda localmente

**Requisitos:** Node.js 20+ y npm.

```bash
cd lambda/security-headers

npm ci
npm test
```

### Resultado esperado
```
PASS  tests/index.test.js
  security-headers Lambda@Edge
    ✓ agrega HSTS
    ✓ agrega X-Content-Type-Options: nosniff
    ✓ agrega X-Frame-Options: DENY
    ✓ agrega Content-Security-Policy con default-src self
    ✓ preserva headers existentes que no colisionan
    ✓ sobrescribe headers de seguridad existentes con valores seguros
    ✓ exporta todos los headers esperados

-----------|---------|----------|---------|---------|
File       | % Stmts | % Branch | % Funcs | % Lines |
-----------|---------|----------|---------|---------|
All files  |    100  |    100   |   100   |   100   |
 index.js  |    100  |    100   |   100   |   100   |
-----------|---------|----------|---------|---------|

Test Suites: 1 passed, 1 total
Tests:       7 passed, 7 total
Time:        ~0.5s
```

### Reporte HTML de cobertura
```bash
# Windows
start coverage\lcov-report\index.html

# Linux / macOS
open coverage/lcov-report/index.html
```

---

## Stack

- **IaC:** Terraform 1.9+
- **CI/CD:** GitHub Actions (federación OIDC, sin secretos de larga duración)
- **Cloud:** AWS — S3, CloudFront, Lambda@Edge, ACM, IAM, DynamoDB

## Arquitectura

```
Usuario ──► CloudFront (ACM us-east-1)
                   │
      ┌────────────┼──────────────────┐
      │            │                  │
 Lambda@Edge    Origin (OAC)        Logs
 (6 headers)  ┌──────────────┐
              │ s3-assets    │ hosting estático, SSE-S3, versionado
              │ s3-uploads   │ privado, lifecycle IA→Glacier→Delete
              │ s3-logs      │ CloudFront access logs (90 días)
              └──────────────┘
```

## Estructura del repositorio

- `terraform/` — módulos IaC (s3, cloudfront, lambda_edge, iam) + env `dev`
- `lambda/security-headers/` — Lambda@Edge Node.js con tests unitarios (100% coverage)
- `web/` — landing estática tipo terminal (servida desde CloudFront)
- `.github/workflows/` — pipelines `build.yml` (PR) y `publish.yml` (push→main)
- `scripts/` — `bootstrap.sh` (state remoto), utilidades de deploy
- `docs/` — SEGURIDAD, METRICAS, COSTOS, SETUP_AWS, informe LaTeX

## Cómo desplegar (desde cero)

```bash
# 1. Configurar credenciales AWS con permisos de administrador
aws configure

# 2. Crear backend remoto (bucket S3 + tabla DynamoDB de lock)
bash scripts/bootstrap.sh

# 3. Inicializar Terraform
cd terraform
terraform init

# 4. Revisar plan
terraform plan -var-file=envs/dev/terraform.tfvars

# 5. Aplicar (5–8 min por la propagación de CloudFront)
terraform apply -var-file=envs/dev/terraform.tfvars

# 6. Publicar contenido al bucket de assets
ASSETS_BUCKET=$(terraform output -raw assets_bucket_name)
cd .. && aws s3 sync web/ s3://$ASSETS_BUCKET --delete

# 7. Invalidar cache del CDN
DIST_ID=$(cd terraform && terraform output -raw cloudfront_distribution_id)
aws cloudfront create-invalidation --distribution-id $DIST_ID --paths "/*"
```

## Pipeline CI/CD

- **`build.yml`** — dispara en Pull Requests: corre tests de Lambda y `terraform fmt/validate`.
- **`publish.yml`** — dispara en push a `main`: asume rol vía OIDC, `aws s3 sync web/` e invalidación `/*` en CloudFront. Duración típica: **~25 segundos**.

## Documentación adicional

- [`docs/SETUP_AWS.md`](docs/SETUP_AWS.md) — configuración de OIDC, destroy y troubleshooting
- [`docs/SEGURIDAD.md`](docs/SEGURIDAD.md) — reporte de headers con evidencia A+
- [`docs/informe_p04.tex`](docs/informe_p04.tex) — informe académico completo
