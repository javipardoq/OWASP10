#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"; PORT="${PORT:-8071}"; export PORT
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
LOCKOUT_SECONDS="${LOCKOUT_SECONDS:-2}"; export LOCKOUT_SECONDS
./mvnw -q spring-boot:run > .verify.log 2>&1 & PID=$!
trap 'kill $PID 2>/dev/null; pkill -P $PID 2>/dev/null; free_port_inline "$PORT"' EXIT
for i in $(seq 1 240); do curl -sf -o /dev/null "http://127.0.0.1:$PORT/health" && break || sleep 0.5; done
login() { curl -s -o /dev/null -w '%{http_code}' -X POST "http://127.0.0.1:$PORT/login" --data-urlencode "username=alice" --data-urlencode "password=$1"; }
LEGIT=$(login "alice-pass-123")                       # caso legitimo antes de fallos
PROCESSED=0; REJECTED=0
for i in $(seq 1 20); do
  C=$(login "guess-$i"); if [ "$C" = "429" ]; then REJECTED=$((REJECTED+1)); else PROCESSED=$((PROCESSED+1)); fi
done
LOCKED=$(login "alice-pass-123")                      # password correcto DURANTE el bloqueo
sleep $((LOCKOUT_SECONDS + 1))
AFTER=$(login "alice-pass-123")                       # tras el cooldown vuelve a funcionar
echo "legitimo=$LEGIT procesados=$PROCESSED rechazados=$REJECTED correcto_en_bloqueo=$LOCKED tras_cooldown=$AFTER"
if [ "$LEGIT" = "200" ] && [ "$PROCESSED" = "5" ] && [ "$REJECTED" = "15" ] && [ "$LOCKED" = "429" ] && [ "$AFTER" = "200" ]; then
  echo "VERIFY PASS: bloqueo tras 5 fallos (15/20 rechazados con 429, incluso con password correcto) y login legitimo funciona antes y tras el cooldown"; exit 0
else
  echo "VERIFY FAIL: el bloqueo no se comporta como se esperaba"; exit 1
fi
