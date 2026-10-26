# A09 — java — VULNERABLE

## Qué demuestra
Falla elegida: los logins fallidos NO dejan ningún registro ni alerta (CWE-778). A09:2025 Fallas de registro y alertas de seguridad.

## Cómo correrlo
```bash
./run.sh      # levanta el servidor
./attack.sh   # ataque de demo
./verify.sh   # PASS si 5 fallos no producen ningún evento AUTH_FAILURE
```

## El ataque
5 logins fallidos contra `alice`: fuerza bruta invisible para el equipo de seguridad.

## El código clave
```
// VULNERABLE: el fallo de autenticación no se registra ni alerta
return 401;
```

## Referencias
- OWASP Top 10:2025 — A09 Security Logging & Alerting Failures · Cheat Sheet: Logging · ASVS 5.0 V16
