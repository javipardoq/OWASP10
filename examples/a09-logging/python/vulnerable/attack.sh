#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
PORT="${PORT:-8094}"; BASE="http://127.0.0.1:$PORT"
echo "Atacante: 5 intentos de login fallidos contra 'alice' (password adivinada: DEMO-ONLY-wrong-guess)"
for i in 1 2 3 4 5; do
  echo "  intento $i -> HTTP $(curl -s -o /dev/null -w '%{http_code}' -X POST "$BASE/login" --data-urlencode "username=alice" --data-urlencode "password=DEMO-ONLY-wrong-guess")"
done
echo "Revise el log del servidor (.verify.log / stdout) para ver que quedo registrado."
