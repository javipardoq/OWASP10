# A05:2025 Inyeccion — Node.js (Express) — CORREGIDO

## Qué demuestra
Login con **consulta parametrizada** (`stmt.bind([username, password])`). La inyección
deja de funcionar. **A05:2025 Inyección**.

## Cómo correrlo
```bash
./run.sh      # http://127.0.0.1:8053
./attack.sh   # el mismo ataque, ahora falla
./verify.sh   # pasa si se bloquea y el login legítimo funciona
```
Requisito: Node.js 18+.

## El código clave
```js
// FIX: marcadores ? y valores ligados aparte
const stmt = db.prepare("SELECT username, balance FROM users WHERE username = ? AND password = ?");
stmt.bind([username, password]);
```

## Referencias
- OWASP Top 10:2025 — A05 Injection · Cheat Sheet: SQL Injection Prevention · ASVS 5.0 V5
