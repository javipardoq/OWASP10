# A10:2025 — Node.js (Express)

| | Vulnerable | Fixed |
|---|---|---|
| Puerto | 8102 | 8103 |
| Ante error del chequeo antifraude | continua (fail-open) y filtra detalle | deniega (503 generico) |

Diff clave: `approved = true` dentro del catch pasa a `approved = false` por defecto + retorno 503 generico.
Ver `diff -r vulnerable fixed`.
