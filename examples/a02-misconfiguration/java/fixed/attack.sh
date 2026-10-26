#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
PORT="${PORT:-8021}"
echo "== Ataque: provocar un error en /profile y revisar fuga de informacion + CORS =="
echo "Enviando  GET /profile?id=abc'  (id malformado) con Origin: https://evil.example"
curl -s -i -H "Origin: https://evil.example" "http://127.0.0.1:${PORT}/profile?id=abc%27"
echo
echo
echo "Revisa: (1) si el cuerpo trae stack trace / SQL / rutas / versiones => fuga de informacion"
echo "        (2) si 'Access-Control-Allow-Origin' es '*' o refleja evil.example => CORS permisivo"
