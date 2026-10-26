# A08:2025 — Fallas de integridad de software o datos

Dos casos: **deserialización insegura** (Java) y **verificación de integridad de artefactos** (config, shell).

| Caso | Vulnerable | Fixed | Puerto V/F |
|---|---|---|---|
| Java deserialización | `java/vulnerable` | `java/fixed` | 8080 / 8081 |
| Artefactos (SHA-256) | `config/vulnerable` | `config/fixed` | n/a (shell) |

Java: el ataque envía un objeto serializado cuyo `readObject()` tiene un efecto lateral inofensivo
(flag + `PWNED.marker`); el fix reemplaza la serialización nativa por JSON hacia un DTO fijo.
Config: el artefacto manipulado se ejecuta en vulnerable y se rechaza en fixed por SHA-256 fijado.
No se incluyen Node ni Flutter en esta categoría.
