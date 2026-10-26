#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"; PORT="${PORT:-8081}"; export PORT
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
rm -f PWNED.marker
./mvnw -q spring-boot:run > .verify.log 2>&1 & PID=$!
trap 'kill $PID 2>/dev/null; pkill -P $PID 2>/dev/null; free_port_inline "$PORT"' EXIT
for i in $(seq 1 200); do curl -sf -o /dev/null "http://127.0.0.1:$PORT/pwned" && break || sleep 0.5; done
./attack.sh
RESP=$(curl -s "http://127.0.0.1:$PORT/pwned")
OK=$(curl -s -X POST "http://127.0.0.1:$PORT/load-prefs" -H 'Content-Type: application/json' -d '{"theme":"dark","language":"en"}')
echo "carga legitima: $OK"
if echo "$RESP" | grep -q '"pwned":false' && [ ! -f PWNED.marker ] && echo "$OK" | grep -q '"loaded":true'; then
  echo "VERIFY PASS: payload rechazado, sin ejecucion de codigo, y la carga JSON legitima funciona"; exit 0
else echo "VERIFY FAIL: efecto lateral presente o carga legitima rota"; exit 1; fi
