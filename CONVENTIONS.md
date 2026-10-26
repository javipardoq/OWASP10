# Convenciones de los ejemplos (contrato para todos los autores)

Este documento define cómo se construye **cada** ejemplo. Todos los ejemplos deben
cumplirlo para que la matriz sea uniforme, se pueda verificar automáticamente y se
pueda publicar.

## 1. Estructura de cada caso

```
examples/<aNN-categoria>/<lenguaje>/{vulnerable,fixed}/
  README.md      # en español (ver sección 6)
  run.sh         # levanta la app en primer plano en localhost:$PORT
  attack.sh      # ejecuta el ataque contra localhost:$PORT e imprime el resultado
  verify.sh      # automatizado: levanta, ataca, comprueba el resultado esperado, apaga
  <código fuente y manifiesto con dependencias fijadas>
```

`vulnerable/` y `fixed/` deben ser **lo más parecidos posible**: misma app, mismos
endpoints, mismos datos semilla. La única diferencia debe ser el control de seguridad,
para que un `diff -r vulnerable fixed` muestre exactamente el fix.

## 2. Contrato de los scripts

- Todos los scripts son `bash`, empiezan con `#!/usr/bin/env bash` y `set -euo pipefail`,
  son ejecutables (`chmod +x`) y hacen `cd "$(dirname "$0")"` al inicio.
- `run.sh`: instala dependencias si faltan (solo dentro de la carpeta) y levanta la app.
  La app **se auto-siembra** (crea su BD en memoria y datos de prueba al arrancar).
- `attack.sh`: usa `curl` (o el runtime del lenguaje) contra `http://127.0.0.1:$PORT`.
  Imprime en español qué intenta y qué obtuvo.
- `verify.sh`: arranca la app en segundo plano, espera a que responda (máx. 120 s),
  ejecuta el ataque, comprueba el resultado y **siempre** mata el proceso (`trap`).
  - En `vulnerable/`: sale con código 0 **si el ataque tiene éxito**.
  - En `fixed/`: sale con código 0 **si el ataque es bloqueado** y la funcionalidad
    legítima sigue funcionando (comprobar también un caso válido).
  - Imprime al final exactamente una línea: `VERIFY PASS: <descripción>` o
    `VERIFY FAIL: <descripción>`.
- Para ejemplos que no son servidores (p. ej. Dart puro), `run.sh` ejecuta la demo,
  `attack.sh` ejecuta el ataque como script, y `verify.sh` ejecuta los tests con el mismo
  criterio de éxito/fallo.

## 3. Puertos (únicos para poder correr todo en paralelo)

```
PORT = 8000 + NN*10 + L*2 + V
NN = número de categoría (01..10)
L  = java 0, node 1, python 2, flutter 3
V  = vulnerable 0, fixed 1
```
Ejemplos: A05 python vulnerable = 8054, A05 python fixed = 8055, A10 java fixed = 8101.
El puerto se puede sobrescribir con la variable de entorno `PORT`.

## 4. Stack y versiones fijadas

| Lenguaje | Versiones | Backend embebido |
|---|---|---|
| Java | JDK 17+, **Spring Boot 4.1.1**, Maven Wrapper (`mvnw`, tipo only-script) | H2 en memoria |
| Node | Node 18+, **express 5.3.0**, **sql.js 1.15.1** (WASM, sin compilación nativa), `package-lock.json` versionado | SQLite en memoria vía sql.js |
| Python | Python 3.11+, **solo stdlib** salvo que sea imprescindible (`http.server`, `sqlite3`, `hashlib`, `hmac`, `secrets`…) | `sqlite3` en memoria |
| Dart/Flutter | Dart 3.x, paquete Dart puro con `pubspec.lock` versionado | En memoria |

Reglas:
- Java: generar el wrapper con `mvn -N wrapper:wrapper -Dtype=only-script`. `run.sh`
  usa `./mvnw -q spring-boot:run`. Si el JDK local es < 17 y Docker está disponible,
  `run.sh` puede hacer fallback a `docker run eclipse-temurin:17`; si no, debe imprimir
  un mensaje claro pidiendo JDK 17+.
- Node: dependencias exactas (sin `^`/`~`). Usar `npm ci` si existe lockfile.
- Python: si una dependencia es imprescindible, `requirements.txt` con `==` y `run.sh`
  crea un venv **dentro de la carpeta** (`.venv`).
- Dart/Flutter: no hay SDK de Flutter garantizado. Los ejemplos de la columna Flutter son
  **paquetes Dart puros** (la capa de lógica/datos de una app Flutter) verificables con
  `dart test` / `dart run`. El README explica cómo se usa ese código dentro de una app
  Flutter real (widget, `flutter_secure_storage`, `sqflite`, etc.). Priorizar el riesgo
  **móvil** real de cada categoría en lugar de copiar la demo de backend.

## 5. Calidad del código

- Identificadores en inglés; **comentarios en español**.
- Marcar el punto exacto de la vulnerabilidad con `// VULNERABLE:` (o `# VULNERABLE:`)
  y el fix con `// FIX:` explicando en una línea por qué.
- Ejemplos **mínimos**: un archivo principal cuando sea posible. Nada de capas que no
  aporten a la lección.
- El código `fixed/` debe ser **realmente correcto** según las recomendaciones actuales
  de OWASP (Cheat Sheet Series / ASVS 5.0). No usar fixes parciales (p. ej. listas negras
  de caracteres en lugar de consultas parametrizadas).
- Secretos/credenciales: falsos y marcados (`DEMO-ONLY-...`).
- Nada escribe fuera de la carpeta del ejemplo (salvo cachés estándar del toolchain:
  `~/.m2`, `~/.npm`, `~/.pub-cache`).
- `.gitignore` local si se generan artefactos (`target/`, `node_modules/`, `.venv/`,
  `.dart_tool/`).

## 6. README.md de cada caso (español)

Secciones, en este orden y breves:
1. **Qué demuestra** — 2–3 frases, categoría OWASP 2025 y CWE principal.
2. **Cómo correrlo** — `./run.sh`, `./attack.sh`, `./verify.sh`.
3. **El ataque** — qué envía el atacante y qué obtiene (o por qué ahora falla).
4. **El código clave** — fragmento corto de la línea vulnerable o del fix.
5. **Referencias** — enlaces a OWASP Top 10:2025, Cheat Sheet correspondiente y ASVS 5.0.

Además, cada carpeta `<lenguaje>/` tiene un `README.md` corto que compara ambas versiones
y muestra el `diff` clave.
