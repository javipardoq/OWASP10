#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
PORT="${PORT:-8041}"; export PORT
pick_free_port() {
  local p="$1"
  if command -v lsof >/dev/null 2>&1; then local pid; pid=$(lsof -nP -tiTCP:"$p" -sTCP:LISTEN 2>/dev/null || true); [ -n "$pid" ] && kill -9 $pid 2>/dev/null || true; fi
  for _ in 1 2 3; do
    if (exec 3<>"/dev/tcp/127.0.0.1/$p") 2>/dev/null; then exec 3>&- 3<&-; p=$(( (RANDOM % 2000) + 8500 )); else echo "$p"; return; fi
  done
  echo "$p"
}
PORT=$(pick_free_port "$PORT"); export PORT
./mvnw -q spring-boot:run > .verify.log 2>&1 & PID=$!
trap 'kill $PID 2>/dev/null; pkill -P $PID 2>/dev/null; free_port_inline "$PORT"' EXIT
for i in $(seq 1 240); do curl -sf -o /dev/null -X POST "http://127.0.0.1:$PORT/login" --data "username=x&password=y" && break || sleep 0.5; done
OUT=$(./attack.sh)
echo "$OUT"
# Caso legitimo: el login con el password correcto debe seguir funcionando, y el incorrecto no.
U="legit-$(date +%s)$$"
curl -s -o /dev/null -X POST "http://127.0.0.1:$PORT/register" --data-urlencode "username=$U" --data-urlencode "password=correcto-Horse-Battery-9"
OK=$(curl -s -X POST "http://127.0.0.1:$PORT/login" --data-urlencode "username=$U" --data-urlencode "password=correcto-Horse-Battery-9")
BAD=$(curl -s -X POST "http://127.0.0.1:$PORT/login" --data-urlencode "username=$U" --data-urlencode "password=incorrecto")
echo "login correcto:   $OK"
echo "login incorrecto: $BAD"
if echo "$OUT" | grep -q '^SAME=no' && echo "$OUT" | grep -q '^CRACKED=none' \
   && echo "$OK" | grep -Eq '"authenticated": ?true' && echo "$BAD" | grep -Eq '"authenticated": ?false'; then
  echo "VERIFY PASS: hashes con sal distintos, diccionario falla y el login legitimo funciona"; exit 0
else
  echo "VERIFY FAIL: el fix no cumple (sal / diccionario / login legitimo)"; exit 1
fi
