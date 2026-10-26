# A01:2025 — Control de acceso roto (Broken Access Control)

API bancaria de demo con `GET /accounts/{id}`, vulnerable a **IDOR** (CWE-639 / CWE-862) y
corregida con **verificación de propiedad en el servidor**. Autenticación de demo con la
cabecera `X-User` (alice dueña de la cuenta 1001, bob de la 1002). Mismo ataque en todos:
alice pide `/accounts/1002` y lee el saldo de bob.

| Lenguaje | Vulnerable | Fixed | Puerto V/F |
|---|---|---|---|
| Java (Spring Boot) | `java/vulnerable` | `java/fixed` | 8010 / 8011 |
| Node.js (Express) | `node/vulnerable` | `node/fixed` | 8012 / 8013 |
| Python (stdlib) | `python/vulnerable` | `python/fixed` | 8014 / 8015 |
| Dart/Flutter | `flutter/vulnerable` | `flutter/fixed` | n/a (tests) |

El fix es siempre el mismo principio: **denegar por defecto y autorizar cada acceso a un
recurso en el servidor/capa de datos** (dueño o rol), devolviendo 403. Ocultar botones en la
UI no es un control. En Flutter se modela el guard de UI que el atacante salta llamando
directamente a la capa de datos.
