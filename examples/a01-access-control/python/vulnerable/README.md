# A01:2025 Control de acceso roto — Python (stdlib) — VULNERABLE

## Qué demuestra
IDOR / referencia directa a objeto sin autorización (CWE-639, CWE-862) en `GET /accounts/{id}`.
Cualquier usuario autenticado lee cualquier cuenta. **A01:2025 Broken Access Control**.

## Cómo correrlo
```bash
./run.sh      # http://127.0.0.1:8014
./attack.sh   # alice pide /accounts/1002 (cuenta de bob)
./verify.sh   # automatizado
```
Requisito: Python 3.11+ (solo stdlib).

## El ataque
`curl -H "X-User: alice" /accounts/1002`. Resultado: HTTP 200 con el saldo de bob (1200). Solo se valida que el usuario esté autenticado.

## El código clave
```python
# VULNERABLE: no se comprueba que la cuenta pertenezca al usuario (IDOR)
return self._send(200, {"id": acc[0], "owner": acc[1], "balance": acc[2]})
```

## Referencias
- OWASP Top 10:2025 — A01 Broken Access Control · Cheat Sheet: Authorization / IDOR Prevention · ASVS 5.0 V8
