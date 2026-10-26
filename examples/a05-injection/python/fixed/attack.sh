#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
PORT="${PORT:-8055}"
echo "== Mismo ataque de inyeccion SQL contra la version corregida =="
curl -s -X POST "http://127.0.0.1:${PORT}/login" \
  --data-urlencode "username=admin' --" \
  --data-urlencode "password=cualquier-cosa"
echo
echo "Ahora 'authenticated' debe ser false: la consulta parametrizada bloquea la inyeccion."
