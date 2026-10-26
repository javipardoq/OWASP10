# A09 — python — FIXED

## Qué demuestra
Evento estructurado AUTH_FAILURE sin secretos y ALERT tras 3 fallos. A09:2025 Fallas de registro y alertas de seguridad.

## Cómo correrlo
```bash
./run.sh      # levanta el servidor
./attack.sh   # ataque de demo
./verify.sh   # PASS si hay AUTH_FAILURE sin password, ALERT y el login legítimo funciona
```

## El ataque
Los mismos 5 fallos generan 5 AUTH_FAILURE (timestamp, username, source) y ALERT desde el 3.º; la password nunca se registra y los campos se sanean (CWE-117).

## El código clave
```
// FIX: registrar el fallo (sin password) y alertar al superar el umbral
securityLog("AUTH_FAILURE", username, source);
```

## Referencias
- OWASP Top 10:2025 — A09 · Cheat Sheet: Logging · ASVS 5.0 V16
