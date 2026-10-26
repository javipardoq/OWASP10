#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
trap 'rm -rf dist install' EXIT
OUT=$(./attack.sh 2>&1); echo "$OUT"
echo "$OUT" | grep -q TAMPERED_CODE_RAN \
  && { echo "VERIFY PASS: el artefacto manipulado fue aceptado y ejecutado (vulnerable confirmado)"; exit 0; } \
  || { echo "VERIFY FAIL: el artefacto manipulado no se ejecuto"; exit 1; }
