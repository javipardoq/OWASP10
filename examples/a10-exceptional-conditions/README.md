# A10:2025 — Manejo incorrecto de condiciones excepcionales (Mishandling of Exceptional Conditions)

Categoría NUEVA en 2025. Endpoint `POST /transfer` que debe pasar por un chequeo antifraude antes de mover fondos.
La versión vulnerable hace **fail-open** (si el chequeo lanza, transfiere igual) y filtra detalle interno; la
corregida hace **fail-closed** (deniega, error genérico). Ataque: `amount=50000&riskScore=abc` hace que el chequeo lance.

| Lenguaje | Vulnerable | Fixed | Puerto V/F |
|---|---|---|---|
| Java (Spring Boot) | `java/vulnerable` | `java/fixed` | 8100 / 8101 |
| Node.js (Express) | `node/vulnerable` | `node/fixed` | 8102 / 8103 |
| Python (stdlib) | `python/vulnerable` | `python/fixed` | 8104 / 8105 |
| Dart/Flutter | `flutter/vulnerable` | `flutter/fixed` | n/a (tests) |

Principio del fix: denegar por defecto, capturar explícitamente, registrar el detalle solo en el servidor y devolver errores genéricos.
