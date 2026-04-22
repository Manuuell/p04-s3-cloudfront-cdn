# Métricas de CloudFront

## KPIs a reportar

| Métrica | Fuente | Objetivo |
|---------|--------|----------|
| Cache hit rate | CloudFront Statistics / `CacheHitRate` en CloudWatch | > 85% |
| Latencia p50 global | CloudWatch RUM o Synthetics | < 100 ms |
| Latencia p95 global | CloudWatch | < 300 ms |
| 4xx error rate | CloudWatch `4xxErrorRate` | < 1% |
| 5xx error rate | CloudWatch `5xxErrorRate` | < 0.1% |
| Bytes servidos | CloudWatch `BytesDownloaded` | — |
| Requests totales | CloudWatch `Requests` | — |

## Extracción

### Opción 1: AWS CLI

```bash
aws cloudfront get-distribution-config --id <dist-id>

aws cloudwatch get-metric-statistics \
  --namespace AWS/CloudFront \
  --metric-name Requests \
  --dimensions Name=DistributionId,Value=<dist-id> Name=Region,Value=Global \
  --start-time $(date -u -d '7 days ago' +%FT%TZ) \
  --end-time $(date -u +%FT%TZ) \
  --period 86400 \
  --statistics Sum
```

### Opción 2: CloudFront Reports

- Console → CloudFront → Reports & analytics → Cache statistics / Popular objects.

### Opción 3: Log analysis

- Logs en `s3-logs/cloudfront/` (formato estándar).
- Cargar a Athena con la [DDL oficial](https://docs.aws.amazon.com/athena/latest/ug/cloudfront-logs.html).

## Latencia por región — muestras

> Ejecutar desde distintas regiones (usar https://www.cloudping.info o Lambdas periódicas).

| Región | p50 (ms) | p95 (ms) | Fecha |
|--------|----------|----------|-------|
| us-east-1 | TODO | TODO | TODO |
| eu-west-1 | TODO | TODO | TODO |
| sa-east-1 | TODO | TODO | TODO |
| ap-southeast-1 | TODO | TODO | TODO |

## Cache hit rate — evolución

| Semana | Hit rate | Observaciones |
|--------|----------|---------------|
| 1 | TODO | Cold cache |
| 2 | TODO | — |
| 3 | TODO | — |

## Acciones derivadas

- [ ] Ajustar TTL si hit rate < 80%.
- [ ] Revisar `Origin Shield` si la región tiene picos de latencia origen→edge.
- [ ] Configurar alarmas CloudWatch para `5xxErrorRate > 0.1%`.
