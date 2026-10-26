#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"; PORT="${PORT:-8103}"; export PORT
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
# Ataque: mismo que en vulnerable; debe quedar DENEGADO y con error generico
RESP=$(curl -s -w ' HTTP=%{http_code}' -X POST "$URL" --data-urlencode "from=alice" --data-urlencode "to=mallory" --data-urlencode "amount=50000" --data-urlencode "riskScore=abc")
echo "ataque: $RESP"
# Caso legitimo: transferencia pequena con chequeo valido
OKR=$(curl -s -X POST "$URL" --data-urlencode "from=alice" --data-urlencode "to=bob" --data-urlencode "amount=100" --data-urlencode "riskScore=10")
echo "legitimo: $OKR"
if echo "$RESP" | grep -Eq '"executed": ?true'; then echo "VERIFY FAIL: la transferencia se ejecuto con el chequeo roto (fail-open)"; exit 1; fi
if echo "$RESP" | grep -Eqi 'fraud-svc|riskScore|exception|stack|FraudClient'; then echo "VERIFY FAIL: se filtro detalle interno"; exit 1; fi
if echo "$OKR" | grep -Eq '"executed": ?true'; then
  echo "VERIFY PASS: fail-closed (transferencia denegada), error generico y transferencia legitima funciona"; exit 0
else
  echo "VERIFY FAIL: la transferencia legitima no funciono"; exit 1
fi
