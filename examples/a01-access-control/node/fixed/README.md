# A01:2025 Control de acceso roto — Node.js (Express) — FIXED

## Qué demuestra
IDOR / referencia directa a objeto sin autorización (CWE-639, CWE-862) en `GET /accounts/{id}`.
El servidor verifica la propiedad y responde 403 si no es el dueño. **A01:2025 Broken Access Control**.

## Cómo correrlo
```bash
./run.sh      # http://127.0.0.1:8013
./attack.sh   # alice pide /accounts/1002 (cuenta de bob)
./verify.sh   # automatizado
```
Requisito: Node 18+ (npm install automático).

## El ataque
`curl -H "X-User: alice" /accounts/1002`. Resultado: HTTP 403 (forbidden); la cuenta propia (1001) sigue accesible.

## El código clave
```js
// FIX: el recurso debe pertenecer al usuario autenticado
if (acc.owner !== user) { return res.status(403).json({ error: "forbidden" }); }
```

## Referencias
- OWASP Top 10:2025 — A01 Broken Access Control · Cheat Sheet: Authorization / IDOR Prevention · ASVS 5.0 V8
