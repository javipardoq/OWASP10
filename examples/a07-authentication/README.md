# A07:2025 — Fallas de autenticación (Authentication Failures)

Login de un banco de demo (usuario semilla `alice` / `alice-pass-123`) atacado por **fuerza
bruta / credential stuffing**: un bucle de passwords incorrectos. La versión vulnerable no
limita intentos; la corregida bloquea la cuenta tras 5 fallos (429 durante el cooldown).

| Lenguaje | Vulnerable | Fixed | Puerto V/F |
|---|---|---|---|
| Java (Spring Boot) | `java/vulnerable` | `java/fixed` | 8070 / 8071 |
| Node.js (Express) | `node/vulnerable` | `node/fixed` | 8072 / 8073 |
| Python (stdlib) | `python/vulnerable` | `python/fixed` | 8074 / 8075 |
| Dart/Flutter | `flutter/vulnerable` | `flutter/fixed` | n/a (tests) |

El cooldown se configura con `LOCKOUT_SECONDS` (30 por defecto; `verify.sh` usa 2). El contador
es en memoria y por instancia (demo); en producción usar un almacén compartido, límite por
IP, MFA y hash de passwords (Argon2/bcrypt). El caso móvil modela un PIN local sin límite y
un token que nunca expira, corregidos con límite de intentos y expiración.
