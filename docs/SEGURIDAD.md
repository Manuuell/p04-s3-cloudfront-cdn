# Reporte de Headers de Seguridad

## Objetivo

Obtener calificación **A/A+** en [securityheaders.com](https://securityheaders.com) mediante la Lambda@Edge `security-headers`.

## Headers inyectados

| Header | Valor | Justificación |
|--------|-------|---------------|
| `Strict-Transport-Security` | `max-age=63072000; includeSubDomains; preload` | Fuerza HTTPS durante 2 años; elegible para HSTS preload list |
| `X-Content-Type-Options` | `nosniff` | Evita MIME-sniffing |
| `X-Frame-Options` | `DENY` | Previene clickjacking |
| `Referrer-Policy` | `strict-origin-when-cross-origin` | Balance entre privacidad y analytics |
| `Content-Security-Policy` | `default-src 'self'; ...` | Restringe orígenes; mitiga XSS |
| `Permissions-Policy` | `camera=(), microphone=(), geolocation=()` | Deniega APIs sensibles por defecto |

## Procedimiento de verificación

1. Desplegar la infraestructura: `./scripts/deploy.sh prod`.
2. Esperar propagación DNS y distribución CloudFront (5–20 min).
3. Ejecutar `curl -I https://<dominio>/` y verificar presencia de los headers.
4. Escanear en https://securityheaders.com/?q=<dominio>.
5. Capturar pantalla y adjuntar resultado aquí.

## Resultado esperado

```
Grade: A+
Score: 100/100
Missing: ninguno
```

## Resultado obtenido

**TODO:** adjuntar captura + fecha de ejecución.

## Hallazgos / ajustes

- [ ] Revisar CSP tras añadir scripts de terceros (analytics, CDN externo).
- [ ] Evaluar `Cross-Origin-Embedder-Policy` y `Cross-Origin-Opener-Policy` si aplica.
