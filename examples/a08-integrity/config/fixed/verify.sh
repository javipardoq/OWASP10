#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
trap 'rm -rf dist install' EXIT
BAD=$(./attack.sh 2>&1 || true); echo "$BAD"
GOOD=$(./run.sh 2>&1 || true); echo "legitimo: $GOOD"
if ! echo "$BAD" | grep -q TAMPERED_CODE_RAN && echo "$BAD" | grep -q RECHAZADO && echo "$GOOD" | grep -q TOOL_OK; then
  echo "VERIFY PASS: artefacto manipulado rechazado y artefacto legitimo aceptado"; exit 0
else echo "VERIFY FAIL: manipulado aceptado o legitimo rechazado"; exit 1; fi
