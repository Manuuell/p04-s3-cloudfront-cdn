# Arquitectura

## Diagrama

```
Usuario ──► Route 53 (DNS) ──► CloudFront (global edge locations)
                                  │
                 ┌────────────────┼─────────────────┐
                 │                │                 │
          Lambda@Edge         Origin (OAC)      Cert ACM
          (security          ┌──────────────┐   (us-east-1)
           headers)          │ s3-assets    │   validado por DNS
                             │   SSE-S3     │
                             │   versionado │
                             │              │
                             │ s3-uploads   │ privado, CORS
                             │   lifecycle  │ 30d→IA, 90d→Glacier, 365d→Delete
                             │              │
                             │ s3-logs      │ CloudFront access logs (90d retention)
                             └──────────────┘
```

## Decisiones clave

| Decisión | Motivo |
|----------|--------|
| OAC en lugar de OAI | OAC es el mecanismo recomendado por AWS y soporta SSE-KMS |
| ACM obligatorio en us-east-1 | Requisito de CloudFront |
| Lambda@Edge en viewer-response | Permite modificar headers de respuesta hacia el cliente |
| Cache policy diferenciada | `index.html` nunca se cachea; assets con TTL 86400s para maximizar hit rate |
| Block Public Access global | Defensa en profundidad: solo CloudFront (via OAC) puede leer assets |
| WAF managed rules | Baseline de protección con AWSManagedRulesCommonRuleSet |

## Flujo de request

1. Cliente resuelve `cdn.ejemplo.com` → Route 53 → alias A/AAAA a CloudFront.
2. CloudFront valida TLS (ACM) y aplica WAF.
3. Cache MISS → request firmada con OAC al bucket S3 `assets`.
4. Respuesta pasa por Lambda@Edge (viewer-response) → se inyectan headers de seguridad.
5. CloudFront cachea la respuesta y la entrega al cliente.

## Estados de los recursos

- **S3 assets:** inmutable via CloudFront; escritura solo vía pipeline `publish` (s3 sync).
- **S3 uploads:** escritura vía presigned URLs (no cubierto por CloudFront en este proyecto).
- **S3 logs:** escritura exclusiva por CloudFront (permiso via ACL/bucket policy).
