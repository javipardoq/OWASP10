#!/usr/bin/env bash
# Simula "descargar e instalar": copia el artefacto a install/ y lo ejecuta.
set -euo pipefail
cd "$(dirname "$0")"
ARTIFACT="${1:?uso: install.sh <artefacto>}"
mkdir -p install
# VULNERABLE: se usa el artefacto sin verificar su integridad (ni hash ni firma);
# equivale a `curl ... | bash`.
cp "$ARTIFACT" install/tool.sh
chmod +x install/tool.sh
./install/tool.sh
