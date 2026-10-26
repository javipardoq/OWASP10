# A07:2025 Autenticación — Python (stdlib) — VULNERABLE

## Qué demuestra
Fuerza bruta / credential stuffing (CWE-307, tambien CWE-521) en el login. No hay limite de intentos ni bloqueo de cuenta: un atacante puede probar passwords sin restriccion. **A07:2025 Fallas de autenticación**.

## Cómo correrlo
```bash
./run.sh      # python3 app.py -> http://127.0.0.1:8074
./attack.sh   # 20 intentos con passwords incorrectos + 1 correcto, cuenta procesados vs rechazados
./verify.sh   # pasa si todos los intentos se procesan (sin 429)
```
Requisito: Python 3.11+ (solo stdlib). Usuario semilla: `alice` / `alice-pass-123`.

## El ataque
Un bucle de 20 passwords incorrectos contra `alice` (y luego el correcto) recibe siempre 401/200: **todos los intentos se procesan** y nunca aparece un 429.

## El código clave
```py
# VULNERABLE: no hay contador de fallos, bloqueo ni rate limit
if password_matches(username, password):
    return self._send(200, {"authenticated": True, "username": username})
self._send(401, {"authenticated": False})
```

## Referencias
- OWASP Top 10:2025 — A07 Authentication Failures · Cheat Sheet: Authentication (Account Lockout) · ASVS 5.0 V6 (Authentication)
