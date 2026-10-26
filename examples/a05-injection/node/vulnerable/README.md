# A05:2025 Inyeccion — Node.js (Express) — VULNERABLE

## Qué demuestra
Inyeccion SQL (CWE-89) en el login. SQL armado por concatenación con `db.prepare(query)`
de sql.js. **A05:2025 Inyección**.

## Cómo correrlo
```bash
./run.sh      # npm install (primera vez) + node app.js -> http://127.0.0.1:8052
./attack.sh   # inyección de bypass
./verify.sh   # pasa si el ataque funciona
```
Requisito: Node.js 18+.

## El código clave
```js
// VULNERABLE: entrada concatenada en el SQL
const query = `SELECT username, balance FROM users WHERE username = '${username}' AND password = '${password}'`;
```

## Referencias
- OWASP Top 10:2025 — A05 Injection · Cheat Sheet: SQL Injection Prevention · ASVS 5.0 V5
