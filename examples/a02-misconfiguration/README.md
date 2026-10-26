# A02:2025 — Configuración de seguridad incorrecta (Security Misconfiguration)

API de demo con `/profile?id=N`. Un `id` mal formado provoca un error del servidor.
La versión **vulnerable** devuelve stack trace, SQL, versiones y rutas (fuga de
información) y usa CORS `Access-Control-Allow-Origin: *`. La versión **fixed** devuelve un
error genérico y solo concede CORS al origen de la allow-list (`https://app.itau-demo.example`).

| Lenguaje | Vulnerable | Fixed | Puerto V/F |
|---|---|---|---|
| Java (Spring Boot) | `java/vulnerable` | `java/fixed` | 8020 / 8021 |
| Node.js (Express) | `node/vulnerable` | `node/fixed` | 8022 / 8023 |
| Python (stdlib) | `python/vulnerable` | `python/fixed` | 8024 / 8025 |
| Dart/Flutter | `flutter/vulnerable` | `flutter/fixed` | n/a (tests) |

Caso móvil (Dart): cliente HTTP que confía en cualquier certificado TLS, permite http://
y registra tokens/cuerpos, frente a validación de certificados + host permitido, solo
https y sin datos sensibles en logs.
