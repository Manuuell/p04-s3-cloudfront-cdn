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

## Plan de trabajo (8 semanas)

| Semana | Fase | Entregable |
|--------|------|------------|
| 1–3 | S3 + Permisos | Buckets configurados (assets, uploads, logs) con cifrado, versionado y lifecycle |
| 4–6 | CloudFront + TLS | CDN con HTTPS activo, OAC, ACM, Route 53, Lambda@Edge |
| 7–8 | Pipeline + Pruebas | GitHub Actions publicando + invalidación + métricas |

## Entregables

- Código Terraform completo
- Lambda@Edge con pruebas unitarias
- Pipeline GitHub Actions (build → deploy → publish)
- Informe de costos (Standard vs IA vs Glacier) — `docs/COSTOS.md`
- Reporte de headers de seguridad — `docs/SEGURIDAD.md`
- Métricas de CloudFront — `docs/METRICAS.md`

## Criterios de evaluación

| Criterio | Peso |
|----------|------|
| S3 Buckets (políticas, cifrado, versionado) | 20% |
| CloudFront (OAC, TLS, dominio) | 25% |
| Lifecycle policies | 15% |
| Lambda@Edge (headers de seguridad) | 20% |
| Pipeline de publicación | 15% |
| Análisis de costos y documentación | 5% |
