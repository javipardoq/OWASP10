#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
command -v dart >/dev/null || { echo "Necesitas Dart SDK 3.x (o Flutter). Ver README."; exit 1; }
dart pub get >/dev/null
echo "Ejecutando la demo (acceso legitimo y ataque)..."
dart test
