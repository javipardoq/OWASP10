# A09:2025 — Fallas de registro y alertas de seguridad

Endpoint `POST /login`. Falla demostrada: **los logins fallidos no se registran** (sin auditoría ni alertas).
El fix emite eventos estructurados `AUTH_FAILURE` (timestamp, username, source; nunca la password) y una `ALERT`
a partir de 3 fallos.

| Lenguaje | Vulnerable | Fixed | Puerto V/F |
|---|---|---|---|
| Java (Spring Boot) | `java/vulnerable` | `java/fixed` | 8090 / 8091 |
| Python (stdlib, logging) | `python/vulnerable` | `python/fixed` | 8094 / 8095 |

Los eventos van a stdout; `verify.sh` captura el log en `.verify.log` y lo inspecciona.
