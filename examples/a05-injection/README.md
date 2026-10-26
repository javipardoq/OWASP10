# A05:2025 — Inyección (Injection)

Login de un banco de demo, vulnerable a **inyección SQL** y corregido con **consultas
parametrizadas**, en los 4 lenguajes del stack. Mismo ataque en todos:
`username = admin' --` para saltarse la autenticación.

| Lenguaje | Vulnerable | Fixed | Puerto V/F |
|---|---|---|---|
| Java (Spring Boot) | `java/vulnerable` | `java/fixed` | 8050 / 8051 |
| Node.js (Express) | `node/vulnerable` | `node/fixed` | 8052 / 8053 |
| Python (stdlib) | `python/vulnerable` | `python/fixed` | 8054 / 8055 |
| Dart/Flutter | `flutter/vulnerable` | `flutter/fixed` | n/a (tests) |

El fix es siempre el mismo principio: **separar los datos del código** usando parámetros
ligados, nunca concatenar entrada del usuario en el texto SQL.
