#!/usr/bin/env bash
set -uo pipefail
cd "$(dirname "$0")"
npm install --no-audit --no-fund >/dev/null 2>&1
npm audit; CODE=$?
echo "npm audit exit code: $CODE"
if [ "$CODE" -eq 0 ]; then
  echo "VERIFY PASS: el SCA no encontro vulnerabilidades (manifiesto corregido)"; exit 0
else
  echo "VERIFY FAIL: el manifiesto corregido todavia tiene vulnerabilidades"; exit 1
fi
