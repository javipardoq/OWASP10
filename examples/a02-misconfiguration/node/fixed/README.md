# A02:2025 Misconfiguration — Node.js — FIXED

## Qué demuestra
El mismo endpoint ahora devuelve un error genérico (el detalle solo va al log del servidor) y un CORS restrictivo con allow-list (CWE-209, CWE-942). Corresponde a **A02:2025 Security Misconfiguration**.

## Cómo correrlo
```bash
./run.sh      # levanta la API en http://127.0.0.1:8023
./attack.sh   # provoca el error y muestra respuesta + Access-Control-Allow-Origin
./verify.sh   # automatizado: arranca, ataca y comprueba el resultado esperado
```

## El ataque
El mismo ataque (`id=abc'`, `Origin: https://evil.example`) recibe `{"error":"internal server error"}` sin internos y sin cabecera CORS. Solo `https://app.itau-demo.example` recibe `Access-Control-Allow-Origin`, y una petición válida (`id=1`) sigue funcionando.

## El código clave
```
// FIX: error generico y CORS solo para el origen permitido
if (req.get('Origin') === ALLOWED_ORIGIN) res.set('Access-Control-Allow-Origin', ALLOWED_ORIGIN);
res.status(500).json({ error: 'internal server error' });
```

## Referencias
- OWASP Top 10:2025 — A02 Security Misconfiguration
- OWASP Cheat Sheets: Error Handling, HTTP Headers, CORS (HTML5 Security)
- OWASP ASVS 5.0 — V13 Configuración, V16 Registro y manejo de errores
