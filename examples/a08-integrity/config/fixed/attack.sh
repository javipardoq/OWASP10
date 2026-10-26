#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
./make-artifacts.sh
echo "Intentando instalar el artefacto MANIPULADO (dist/tool-tampered.sh)..."
./install.sh dist/tool-tampered.sh || echo "install.sh termino con error (codigo $?)"
