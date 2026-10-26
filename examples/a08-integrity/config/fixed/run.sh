#!/usr/bin/env bash
# Uso: ./run.sh [artefacto]  (por defecto el legitimo)
set -euo pipefail
cd "$(dirname "$0")"
./make-artifacts.sh
./install.sh "${1:-dist/tool-good.sh}"
