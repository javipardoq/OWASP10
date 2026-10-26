#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"; PORT="${PORT:-8020}"; export PORT
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
for i in $(seq 1 300); do curl -sf -o /dev/null "http://127.0.0.1:$PORT/profile?id=1" && break || sleep 0.5; done
RESP=$(curl -s -i -H "Origin: https://evil.example" "http://127.0.0.1:$PORT/profile?id=abc%27" || true)
echo "$RESP"
LEAK=no; CORS=no
echo "$RESP" | grep -qiE 'Traceback|stackTrace|Exception|\.java:|\.js:|\.py|SELECT ' && LEAK=si
echo "$RESP" | grep -qiE '^access-control-allow-origin: \*' && CORS=si
if [ "$LEAK" = si ] || [ "$CORS" = si ]; then
  echo "VERIFY PASS: vulnerable confirmado (fuga de internos=$LEAK, CORS '*'=$CORS)"; exit 0
else
  echo "VERIFY FAIL: no se detecto fuga ni CORS permisivo"; exit 1
fi
