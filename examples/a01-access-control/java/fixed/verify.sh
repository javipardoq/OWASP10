#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"; PORT="${PORT:-8011}"; export PORT
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
for i in $(seq 1 200); do curl -s -o /dev/null -H "X-User: alice" "http://127.0.0.1:$PORT/accounts/1001" && break || sleep 0.5; done
RESP=$(curl -s -w "\nHTTP %{http_code}" -H "X-User: alice" "http://127.0.0.1:$PORT/accounts/1002")
echo "respuesta: $RESP"
OWN=$(curl -s -w "\nHTTP %{http_code}" -H "X-User: alice" "http://127.0.0.1:$PORT/accounts/1001")
echo "propia: $OWN"
echo "$RESP" | grep -q "HTTP 403" && ! echo "$RESP" | grep -q "1200" && echo "$OWN" | grep -q "HTTP 200" && echo "$OWN" | grep -q "\"owner\":\"alice\"" && { echo "VERIFY PASS: acceso ajeno bloqueado (403) y cuenta propia accesible"; exit 0; } || { echo "VERIFY FAIL: el control de acceso no se comporta como se espera"; exit 1; }
