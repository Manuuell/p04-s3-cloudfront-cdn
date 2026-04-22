# Análisis de Costos — S3 Standard vs IA vs Glacier

> Completar con métricas reales tras las primeras semanas de operación.

## Supuestos

- Volumen estimado: **TODO** GB/mes en `s3-uploads`.
- Región: `us-east-1`.
- Requests GET/mes: **TODO**.

## Tabla comparativa (precios referenciales us-east-1, revisar tarifa vigente)

| Clase | Costo almacenamiento ($/GB-mes) | GET ($/1k req) | PUT ($/1k req) | Mínimo storage | Retrieval |
|-------|--------------------------------|----------------|----------------|----------------|-----------|
| Standard | 0.023 | 0.0004 | 0.005 | — | — |
| Standard-IA | 0.0125 | 0.001 | 0.01 | 30 días | $0.01/GB |
| Glacier Flexible | 0.0036 | 0.0004 | 0.03 | 90 días | $0.01–$0.03/GB |
| Glacier Deep Archive | 0.00099 | 0.0004 | 0.05 | 180 días | minutos–horas |

## Lifecycle actual

```
0–29 días    → Standard
30–89 días   → Standard-IA
90–364 días  → Glacier
365 días     → Eliminado
```

## Simulación (1 TB, datos escritos una vez y accedidos decrecientemente)

| Mes | Clase | Costo mensual |
|-----|-------|---------------|
| 1 | Standard | **TODO** |
| 2–3 | Standard-IA | **TODO** |
| 4–12 | Glacier | **TODO** |

**Ahorro vs mantener todo en Standard:** **TODO %**.

## Recomendaciones

- [ ] Validar que los patrones de acceso justifican IA (se paga retrieval).
- [ ] Considerar Intelligent-Tiering si el patrón es impredecible.
- [ ] Habilitar S3 Storage Lens para telemetría continua de costos.
