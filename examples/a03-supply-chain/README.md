# A03:2025 — Fallos en la Cadena de Suministro de Software

Categoría **nueva** en 2025 (amplía "Componentes Vulnerables y Desactualizados"). El
riesgo no es solo usar una librería con un CVE, sino todo lo que entra a tu build:
dependencias transitivas, artefactos sin firmar, registros comprometidos.

Esta categoría se demuestra con **config y pipeline**, no con 4 apps, porque el control
vive en el proceso de build, no en el código de la app.

## Qué hay acá

| Carpeta | Qué muestra |
|---|---|
| `config/node-vulnerable/` | `package.json` con `lodash 4.17.11` (prototype pollution, GHSA-xxjr-mmjv-4gpg) y `minimist 1.2.0`. El SCA lo detecta. |
| `config/node-fixed/` | Mismas librerías actualizadas (`lodash 4.18.1`, `minimist 1.2.8`). El SCA pasa limpio. |
| `pipeline/Jenkinsfile` | Pipeline Groovy que corre SCA (`npm audit --audit-level=high` + OWASP Dependency-Check) y **falla el build** si hay vulnerabilidades. |

## Cómo correrlo

```bash
cd config/node-vulnerable && ./verify.sh   # el SCA falla -> dependencia vulnerable detectada
cd ../node-fixed && ./verify.sh            # el SCA pasa -> dependencias limpias
cd ../node-vulnerable && ./attack.sh       # muestra el reporte de npm audit
```
Requisito: Node.js 18+ y acceso a la red (para consultar la base de advisories).

## El control correcto

1. **SCA en el CI** que falla el build ante vulnerabilidades (alta/crítica).
2. **Lockfiles versionados** y versiones fijas (sin `^`/`~`) para builds reproducibles.
3. **Verificar integridad/firmas** de los artefactos (npm provenance, Sigstore/cosign).
4. **Registro/proxy interno** (Artifactory/Nexus) en vez del público directo.
5. Para Java/Gradle/Maven: **OWASP Dependency-Check** con umbral de CVSS.

## Referencias
- OWASP Top 10:2025 — A03 Software Supply Chain Failures
- OWASP Dependency-Check · OWASP CycloneDX (SBOM) · SLSA framework
