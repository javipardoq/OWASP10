# OWASP Top 10:2025 — Ejemplos ejecutables por lenguaje

Suite de ejemplos **ejecutables** para aprender OWASP Top 10 en desarrollo seguro. Para
cada categoría de OWASP y cada lenguaje hay dos versiones de cada caso:

- **`vulnerable/`** — el control NO está implementado. Incluye un script de ataque que
  demuestra la explotación.
- **`fixed/`** — el control SÍ está implementado. El mismo ataque ahora falla.

La idea es ver, lado a lado, **la diferencia exacta de código** que cierra cada riesgo.

> Edición: **OWASP Top 10:2025** (presentada en noviembre de 2025, finalizada en enero
> de 2026). Es la última lista oficial publicada; no existe una edición 2026 para
> aplicaciones web. Ver el mapeo 2021→2025 más abajo.

## Lenguajes cubiertos

| Lenguaje | Backend embebido usado en los ejemplos |
|---|---|
| Java (Spring Boot) | H2 en memoria, Tomcat embebido |
| TypeScript / Node.js | SQLite en memoria (sql.js, WASM, sin compilación nativa) |
| Python | SQLite de la stdlib |
| Dart / Flutter | Harness local (`flutter test` / `dart run`) |

Lenguajes de soporte (config/pipeline): Groovy (Jenkins/Gradle), YAML/JSON (CloudFormation).

## Cómo correr los ejemplos

### 1. El lanzador `demo.sh` (lo más fácil)

```bash
./demo.sh                 # menú interactivo: eliges categoría (1-10) y lenguaje
./demo.sh a05 java        # atajo directo: categoría + lenguaje
./demo.sh a01 node
```

Qué hace:
- Levanta la versión **vulnerable** y la **corregida** a la vez, cada una en su puerto.
- Espera a que ambas respondan y te muestra las **URLs** (ej. `http://127.0.0.1:8050`).
- Corre el ataque contra las dos para que veas la diferencia: **funciona** en la
  vulnerable y **falla** en la corregida.
- Deja los servidores corriendo y abre las URLs en el navegador: cada app tiene una
  página de inicio que explica el caso y tiene enlaces/formularios para probar el ataque.
- `Ctrl-C` detiene ambos servidores.

Para los ejemplos **Flutter** no hay servidor: `demo.sh` corre los tests de Dart de ambas
versiones y muestra el resultado.

### 2. Verificar que todo funciona

```bash
./test-all.sh             # corre todos los ejemplos y reporta PASS/FAIL
./test-all.sh a05         # solo una categoría
```
Cada ejemplo se levanta, se ataca y se comprueba el resultado esperado automáticamente.

### 3. Correr un ejemplo a mano

Cada carpeta `vulnerable/` y `fixed/` es **autocontenida**: no necesita bases de datos
externas, nube ni infraestructura compartida. Se levanta con un comando.

```bash
cd examples/a05-injection/python/vulnerable
./run.sh        # levanta la app en localhost
./attack.sh     # ejecuta el ataque; en vulnerable/ tiene éxito, en fixed/ falla

cd ../fixed
./run.sh        # misma app, ahora con el control implementado
./attack.sh     # el mismo ataque ahora es bloqueado
```

Cada carpeta incluye su propio `README.md` con: qué controla, cómo se explota la versión
vulnerable, qué cambia el fix y cómo correrlo.

## Estructura

```
examples/<categoria>/<lenguaje>/{vulnerable,fixed}/   ejemplos ejecutables
demo.sh                     Lanzador interactivo de los ejemplos
test-all.sh                 Verificador de todos los ejemplos
CONVENTIONS.md              Contrato que cumple cada ejemplo
```

Cada categoría tiene su propio `README.md` dentro de `examples/<categoria>/`.

## Requisitos (solo el lenguaje que quieras correr)

- **Java:** JDK 17+ (los ejemplos usan el Maven Wrapper `mvnw`, no hace falta instalar Maven).
- **Node:** Node.js 18+.
- **Python:** Python 3.11+ (casi todo con la stdlib).
- **Flutter / Dart:** Flutter 3.x o Dart 3.x.

## Mapeo OWASP 2021 → 2025

| 2025 | Cambio respecto a 2021 |
|---|---|
| A01 Control de Acceso Roto | Sin cambio en el puesto; **ahora incluye SSRF** |
| A02 Configuración Incorrecta de Seguridad | Subió (antes A05) |
| A03 Fallos en la Cadena de Suministro de Software | **Nuevo**; amplía "Componentes Vulnerables y Desactualizados" |
| A04 Fallos Criptográficos | Bajó respecto a 2021 |
| A05 Inyección | Bajó respecto a 2021 |
| A06 Diseño Inseguro | Se mantiene |
| A07 Fallos de Autenticación | Se mantiene (renombrado) |
| A08 Fallos de Integridad del Software y los Datos | Se mantiene |
| A09 Fallos en Registro y Alertas de Seguridad | Se mantiene (renombrado, incluye alertas) |
| A10 Manejo Incorrecto de Condiciones Excepcionales | **Nuevo** |

## Aviso

El código bajo `vulnerable/` es **inseguro a propósito**, con fines didácticos. No lo
uses en producción. Las credenciales y secretos en los ejemplos son falsos y están
claramente marcados como tales.

Licencia: ver [LICENSE](LICENSE).
