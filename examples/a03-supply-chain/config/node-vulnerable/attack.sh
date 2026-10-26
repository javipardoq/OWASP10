#!/usr/bin/env bash
set -uo pipefail
cd "$(dirname "$0")"
npm install --no-audit --no-fund >/dev/null 2>&1
echo "== Escaneo SCA del manifiesto vulnerable (npm audit) =="
npm audit || true
echo
echo "lodash 4.17.11 tiene prototype pollution (GHSA-xxjr-mmjv-4gpg). En runtime, un"
echo "objeto malicioso podria contaminar Object.prototype y alterar la logica de la app."
