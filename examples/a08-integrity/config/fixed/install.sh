#!/usr/bin/env bash
# Simula "descargar e instalar": verifica SHA-256 contra un hash fijado antes de usar.
set -euo pipefail
cd "$(dirname "$0")"
ARTIFACT="${1:?uso: install.sh <artefacto>}"
mkdir -p install
sha256() { if command -v sha256sum >/dev/null; then sha256sum "$1" | cut -d' ' -f1; else shasum -a 256 "$1" | cut -d' ' -f1; fi; }
# FIX: el hash esperado viene fijado (pinned) en el repo, de un canal distinto al artefacto
EXPECTED="$(cut -d' ' -f1 PINNED.sha256)"
ACTUAL="$(sha256 "$ARTIFACT")"
if [ "$ACTUAL" != "$EXPECTED" ]; then
  # FIX: ante diferencia se rechaza (fail-closed) y no se ejecuta nada
  echo "RECHAZADO: SHA-256 no coincide (esperado $EXPECTED, obtenido $ACTUAL)" >&2
  exit 1
fi
cp "$ARTIFACT" install/tool.sh
chmod +x install/tool.sh
./install/tool.sh
