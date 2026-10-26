# A04:2025 — Fallos criptográficos (Cryptographic Failures)

Almacenamiento de passwords. La versión vulnerable guarda **MD5 sin sal**: dos usuarios con el
mismo password tienen el mismo hash y un mini diccionario "rainbow" lo revierte. La versión
corregida usa un hash de password con **sal por password y factor de trabajo**.

| Lenguaje | Vulnerable | Fixed | Puerto V/F | Fix |
|---|---|---|---|---|
| Java (Spring Boot) | `java/vulnerable` | `java/fixed` | 8040 / 8041 | BCrypt cost 12 (`spring-security-crypto`) |
| Node.js (Express) | `node/vulnerable` | `node/fixed` | 8042 / 8043 | PBKDF2-HMAC-SHA256 600000 it. (`crypto` stdlib) |
| Python (stdlib) | `python/vulnerable` | `python/fixed` | 8044 / 8045 | PBKDF2-HMAC-SHA256 600000 it. (`hashlib`) |
| Dart/Flutter | `flutter/vulnerable` | `flutter/fixed` | n/a (tests) | PBKDF2 en Dart puro (`crypto` 3.0.7) |

`attack.sh` registra dos usuarios con el mismo password, imprime ambos hashes e intenta la
reversión por diccionario. `verify.sh` (vulnerable) pasa si los hashes son idénticos o el
diccionario revierte; (fixed) pasa si los hashes difieren, el diccionario falla y el login legítimo funciona.
