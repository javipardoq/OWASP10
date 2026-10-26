#!/usr/bin/env bash
# Verifica TODA la matriz: busca cada verify.sh y lo ejecuta, reportando PASS/FAIL.
# Uso: ./test-all.sh            (verifica todo)
#      ./test-all.sh a05        (solo las categorias que matcheen 'a05')
set -uo pipefail
cd "$(dirname "$0")/examples"

FILTER="${1:-}"
PASS=0; FAIL=0; FAILED_LIST=()

# Orden estable
while IFS= read -r v; do
  dir=$(dirname "$v")
  rel=${dir#./}
  if [ -n "$FILTER" ] && [[ "$rel" != *"$FILTER"* ]]; then continue; fi
  printf "%-60s " "$rel"
  OUT=$(cd "$dir" && bash verify.sh 2>&1)
  LINE=$(echo "$OUT" | grep -E "VERIFY (PASS|FAIL|SKIP)" | tail -1)
  if echo "$LINE" | grep -q "VERIFY PASS"; then
    echo "PASS"; PASS=$((PASS+1))
  elif echo "$LINE" | grep -q "VERIFY SKIP"; then
    echo "SKIP ($LINE)"
  else
    echo "FAIL"; FAIL=$((FAIL+1)); FAILED_LIST+=("$rel")
  fi
done < <(find . -name verify.sh | sort)

echo
echo "=================================================="
echo "RESULTADO: $PASS PASS, $FAIL FAIL"
if [ "$FAIL" -gt 0 ]; then
  echo "Fallaron:"; printf '  - %s\n' "${FAILED_LIST[@]}"
  exit 1
fi
echo "Toda la matriz verificada."
