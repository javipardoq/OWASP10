#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
PORT="${PORT:-8042}"
BASE="http://127.0.0.1:${PORT}"
SUFFIX="$(date +%s)$$"
echo "== Ataque: hashes de password sin sal / reversibles por diccionario =="
echo "Registrando dos usuarios distintos con el MISMO password (password123)..."
jget() { python3 -c 'import json,sys; print(json.load(sys.stdin)["stored_hash"])'; }
HASH_A=$(curl -s -X POST "$BASE/register" --data-urlencode "username=victima-a-$SUFFIX" --data-urlencode "password=password123" | jget)
HASH_B=$(curl -s -X POST "$BASE/register" --data-urlencode "username=victima-b-$SUFFIX" --data-urlencode "password=password123" | jget)
echo "hash almacenado A: $HASH_A"
echo "hash almacenado B: $HASH_B"
if [ "$HASH_A" = "$HASH_B" ]; then
  echo "SAME=yes  (sin sal: mismo password => mismo hash)"
else
  echo "SAME=no   (con sal: mismo password => hashes distintos)"
fi
echo "Intentando revertir el hash con un mini diccionario 'rainbow' (MD5/SHA-1 de passwords comunes)..."
CRACK=$(python3 - "$HASH_A" <<'PY'
import hashlib, sys
target = sys.argv[1]
words = ["123456", "qwerty", "letmein", "admin", "welcome", "password", "password123", "iloveyou", "abc123"]
for w in words:
    for algo in ("md5", "sha1"):
        if hashlib.new(algo, w.encode()).hexdigest() == target:
            print(f"{w} ({algo})")
            raise SystemExit
print("none")
PY
)
if [ "$CRACK" = "none" ]; then
  echo "CRACKED=none  (el diccionario no revierte el hash)"
else
  echo "CRACKED=$CRACK  (password recuperado del hash)"
fi
