#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"; PORT="${PORT:-8074}"; export PORT
pick_free_port() {
  local p="$1"
  if command -v lsof >/dev/null 2>&1; then local pid; pid=$(lsof -nP -tiTCP:"$p" -sTCP:LISTEN 2>/dev/null || true); [ -n "$pid" ] && kill -9 $pid 2>/dev/null || true; fi
  for _ in 1 2 3; do
    if (exec 3<>"/dev/tcp/127.0.0.1/$p") 2>/dev/null; then exec 3>&- 3<&-; p=$(( (RANDOM % 2000) + 8500 )); else echo "$p"; return; fi
  done
  echo "$p"
}
PORT=$(pick_free_port "$PORT"); export PORT
python3 app.py > .verify.log 2>&1 & PID=$!; disown
trap 'kill $PID 2>/dev/null; pkill -P $PID 2>/dev/null; { wait $PID; } 2>/dev/null; true' EXIT
for i in $(seq 1 100); do curl -sf -o /dev/null "http://127.0.0.1:$PORT/health" && break || sleep 0.3; done
login() { curl -s -o /dev/null -w '%{http_code}' -X POST "http://127.0.0.1:$PORT/login" --data-urlencode "username=alice" --data-urlencode "password=$1"; }
PROCESSED=0; REJECTED=0
for i in $(seq 1 20); do
  C=$(login "guess-$i"); if [ "$C" = "429" ]; then REJECTED=$((REJECTED+1)); else PROCESSED=$((PROCESSED+1)); fi
done
FINAL=$(login "alice-pass-123")
echo "procesados=$PROCESSED rechazados=$REJECTED login_correcto_tras_rafaga=$FINAL"
if [ "$PROCESSED" = "20" ] && [ "$REJECTED" = "0" ] && [ "$FINAL" = "200" ]; then
  echo "VERIFY PASS: 20/20 intentos procesados sin bloqueo ni 429 (fuerza bruta posible, vulnerable confirmado)"; exit 0
else
  echo "VERIFY FAIL: se esperaba que todos los intentos fueran procesados"; exit 1
fi
