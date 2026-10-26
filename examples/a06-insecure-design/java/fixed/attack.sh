#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"; PORT="${PORT:-8061}"
echo "== Mismo ataque contra la version corregida =="
curl -s -X POST "http://127.0.0.1:$PORT/transfer" --data "from=alice&to=bob&amount=-500"; echo
echo "Ahora debe rechazarse (monto debe ser positivo)."
