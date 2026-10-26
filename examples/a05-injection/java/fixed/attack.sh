#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"; PORT="${PORT:-8051}"
echo "== Mismo ataque contra la version corregida =="
curl -s -X POST "http://127.0.0.1:${PORT}/login" --data-urlencode "username=admin' --" --data-urlencode "password=x"; echo
echo "Ahora 'authenticated' debe ser false."
