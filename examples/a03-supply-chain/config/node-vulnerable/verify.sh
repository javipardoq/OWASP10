#!/usr/bin/env bash
set -uo pipefail
cd "$(dirname "$0")"
npm install --no-audit --no-fund >/dev/null 2>&1
npm audit; CODE=$?
echo "npm audit exit code: $CODE"
if [ "$CODE" -ne 0 ]; then
  echo "VERIFY PASS: el SCA detecto dependencias vulnerables (manifiesto vulnerable confirmado)"; exit 0
else
  echo "VERIFY FAIL: el SCA no detecto nada; el manifiesto deberia ser vulnerable"; exit 1
fi
