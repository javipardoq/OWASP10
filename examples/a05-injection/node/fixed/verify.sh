#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"; PORT="${PORT:-8053}"; export PORT
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
node app.js & PID=$!
trap 'kill $PID 2>/dev/null || true' EXIT
for i in $(seq 1 80); do curl -sf -o /dev/null -X POST "http://127.0.0.1:$PORT/login" --data "username=x&password=y" && break || sleep 0.3; done
ATTACK=$(curl -s -X POST "http://127.0.0.1:$PORT/login" --data-urlencode "username=admin' --" --data-urlencode "password=x")
LEGIT=$(curl -s -X POST "http://127.0.0.1:$PORT/login" --data-urlencode "username=alice" --data-urlencode "password=alice-pass-123")
echo "ataque: $ATTACK"; echo "legitimo: $LEGIT"
{ echo "$ATTACK" | grep -q '"authenticated":false' && echo "$LEGIT" | grep -q '"authenticated":true'; } && { echo "VERIFY PASS: inyeccion bloqueada y login legitimo ok"; exit 0; } || { echo "VERIFY FAIL"; exit 1; }
