# A02:2025 Misconfiguration — Node.js — VULNERABLE

## Qué demuestra
El endpoint `/profile` devuelve en el error el stack trace, la consulta SQL, versiones y rutas (CWE-209 / CWE-200) y responde con CORS `*` (CWE-942). Corresponde a **A02:2025 Security Misconfiguration**.

## Cómo correrlo
```bash
./run.sh      # levanta la API en http://127.0.0.1:8022
./attack.sh   # provoca el error y muestra respuesta + Access-Control-Allow-Origin
./verify.sh   # automatizado: arranca, ataca y comprueba el resultado esperado
```

## El ataque
El atacante envía `GET /profile?id=abc'` con `Origin: https://evil.example`. La respuesta 500 incluye el stack trace, la consulta y la versión del runtime/framework, y la cabecera `Access-Control-Allow-Origin: *` permite que cualquier web lea la respuesta.

## El código clave
```
// VULNERABLE: stack trace y CORS abierto
res.set('Access-Control-Allow-Origin', '*');
res.status(500).json({ error: err.message, stackTrace: err.stack });
```

## Referencias
- OWASP Top 10:2025 — A02 Security Misconfiguration
- OWASP Cheat Sheets: Error Handling, HTTP Headers, CORS (HTML5 Security)
- OWASP ASVS 5.0 — V13 Configuración, V16 Registro y manejo de errores
