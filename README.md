# P04 — Plataforma de Almacenamiento de Objetos con CDN Global en AWS

Proyecto académico de Infraestructura como Código & DevOps.

## Stack

- **IaC:** Terraform
- **CI/CD:** GitHub Actions
- **Cloud:** AWS — S3, CloudFront, Lambda@Edge, ACM, Route 53, S3 Glacier, WAF

## Arquitectura

```
Usuario ──► Route 53 ──► CloudFront (ACM us-east-1, WAF)
                             │
              ┌──────────────┼──────────────┐
              │              │              │
         Lambda@Edge      Origin (OAC)   Logs
         (headers)      ┌──────────────┐
                        │ s3-assets    │ hosting estático, SSE-S3, versionado
                        │ s3-uploads   │ privado, CORS, lifecycle IA→Glacier
                        │ s3-logs      │ CloudFront access logs
                        └──────────────┘
```

## Estructura del repositorio

- `terraform/` — módulos IaC (s3, cloudfront, acm, route53, lambda_edge) + envs `dev/prod`
- `lambda/security-headers/` — Lambda@Edge Node.js con tests unitarios
- `web/` — contenido estático de ejemplo
- `.github/workflows/` — pipelines de build, deploy-infra y publish
- `scripts/` — utilidades locales (deploy, invalidación)
- `docs/` — arquitectura, costos, seguridad, métricas

## Cómo desplegar

```bash
# 1. Configurar credenciales AWS
aws configure

# 2. Inicializar Terraform
cd terraform
terraform init -backend-config=envs/dev/backend.hcl

# 3. Aplicar
terraform apply -var-file=envs/dev/terraform.tfvars

# 4. Publicar contenido
./scripts/deploy.sh dev
```
