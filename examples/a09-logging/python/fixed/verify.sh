#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"; PORT="${PORT:-8095}"; export PORT
pick_free_port() {
  local p="$1"
  if command -v lsof >/dev/null 2>&1; then local pid; pid=$(lsof -nP -tiTCP:"$p" -sTCP:LISTEN 2>/dev/null || true); [ -n "$pid" ] && kill -9 $pid 2>/dev/null || true; fi
  for _ in 1 2 3; do
    if (exec 3<>"/dev/tcp/127.0.0.1/$p") 2>/dev/null; then exec 3>&- 3<&-; p=$(( (RANDOM % 2000) + 8500 )); else echo "$p"; return; fi
  done
  echo "$p"
}
PORT=$(pick_free_port "$PORT"); export PORT
python3 -u app.py > .verify.log 2>&1 & PID=$!
trap 'kill $PID 2>/dev/null || true' EXIT
for i in $(seq 1 200); do curl -s -o /dev/null "http://127.0.0.1:$PORT/" && break || sleep 0.5; done
./attack.sh
sleep 0.5
N=$(grep -c -E "\"event\": *\"AUTH_FAILURE\"" .verify.log || true); A=$(grep -c -E "\"event\": *\"ALERT\"" .verify.log || true)
OK=$(curl -s -o /dev/null -w "%{http_code}" -X POST "http://127.0.0.1:$PORT/login" --data-urlencode "username=alice" --data-urlencode "password=DEMO-ONLY-s3cret")
echo "AUTH_FAILURE=$N ALERT=$A login_legitimo=HTTP $OK"
if [ "$N" -ge 5 ] && [ "$A" -ge 1 ] && ! grep -q "DEMO-ONLY-wrong-guess\|DEMO-ONLY-s3cret" .verify.log && [ "$OK" = 200 ]; then
  echo "VERIFY PASS: fallos registrados de forma estructurada sin password, ALERT emitida y login legitimo funciona"; exit 0
else echo "VERIFY FAIL: log incompleto, password filtrada o login legitimo roto"; exit 1; fi
