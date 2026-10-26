#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
command -v dart >/dev/null || { echo "VERIFY SKIP: Dart SDK no encontrado"; exit 0; }
dart pub get >/dev/null 2>&1
if dart test 2>&1 | tail -3 | grep -q "All tests passed"; then
  echo "VERIFY PASS: el comportamiento (ataque/bloqueo) es el esperado"; exit 0
else
  echo "VERIFY FAIL: los tests no pasaron"; exit 1
fi
