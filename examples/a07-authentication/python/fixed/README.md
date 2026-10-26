# A07:2025 Autenticación — Python (stdlib) — FIXED

## Qué demuestra
Mismo login, pero con **bloqueo temporal por usuario**: tras 5 fallos consecutivos se rechaza con **429** (+ `Retry-After`) durante un cooldown, incluso si se envía el password correcto. **A07:2025 Fallas de autenticación** (CWE-307). El contador es en memoria y por instancia (demo); en producción: Redis compartido, límite por IP, MFA y alertas.

## Cómo correrlo
```bash
./run.sh      # python3 app.py -> http://127.0.0.1:8075
./attack.sh   # 20 intentos con passwords incorrectos + 1 correcto, cuenta procesados vs rechazados
./verify.sh   # pasa si hay bloqueo (429) y el login legítimo funciona antes y tras el cooldown
```
Requisito: Python 3.11+ (solo stdlib). Usuario semilla: `alice` / `alice-pass-123`.

## El ataque
Los primeros 5 intentos devuelven 401; los 15 restantes devuelven **429**. Con el password correcto durante el bloqueo también 429. Pasado el cooldown (`LOCKOUT_SECONDS`, 30 s por defecto; `verify.sh` usa 2 s) el usuario legítimo entra de nuevo.

## El código clave
```py
# FIX: durante el bloqueo se rechaza sin evaluar el password
if st["locked_until"] > now:
    return self._send(429, {"authenticated": False, "error": "locked"}, ...)
...
if st["failures"] >= MAX_ATTEMPTS: st["locked_until"] = now + LOCKOUT_SECONDS
```

## Referencias
- OWASP Top 10:2025 — A07 Authentication Failures · Cheat Sheet: Authentication (Account Lockout) · ASVS 5.0 V6 (Authentication)
