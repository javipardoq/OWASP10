#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"; PORT="${PORT:-8071}"
echo "== Ataque: fuerza bruta contra /login de alice (20 passwords incorrectos + 1 correcto) =="
PROCESSED=0; REJECTED=0
for i in $(seq 1 20); do
  CODE=$(curl -s -o /dev/null -w '%{http_code}' -X POST "http://127.0.0.1:${PORT}/login" --data-urlencode "username=alice" --data-urlencode "password=guess-$i")
  if [ "$CODE" = "429" ]; then REJECTED=$((REJECTED+1)); else PROCESSED=$((PROCESSED+1)); fi
done
echo "Intentos procesados (401): $PROCESSED | rechazados (429): $REJECTED"
FINAL=$(curl -s -o /dev/null -w '%{http_code}' -X POST "http://127.0.0.1:${PORT}/login" --data-urlencode "username=alice" --data-urlencode "password=alice-pass-123")
echo "Intento con el password correcto tras la rafaga: HTTP $FINAL"
echo "Vulnerable: todos se procesan (sin limite). Fixed: tras 5 fallos llegan 429."
