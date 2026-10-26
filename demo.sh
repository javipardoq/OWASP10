#!/usr/bin/env bash
# demo.sh — Lanzador interactivo de los ejemplos OWASP Top 10:2025.
#
# Uso:
#   ./demo.sh                 menú interactivo (eliges categoría y lenguaje)
#   ./demo.sh a05 java        atajo directo
#
# Levanta la versión VULNERABLE y la CORREGIDA, espera a que respondan de verdad, te
# muestra las URLs, y corre el ataque contra cada una para que veas la diferencia.
# Los servidores quedan corriendo hasta que presiones Ctrl-C.
set -uo pipefail
cd "$(dirname "$0")/examples"

CATS=(
  "a01-access-control|A01 Control de Acceso Roto"
  "a02-misconfiguration|A02 Configuración Incorrecta"
  "a03-supply-chain|A03 Cadena de Suministro (SCA, no servidor)"
  "a04-crypto|A04 Fallos Criptográficos"
  "a05-injection|A05 Inyección"
  "a06-insecure-design|A06 Diseño Inseguro"
  "a07-authentication|A07 Fallos de Autenticación"
  "a08-integrity|A08 Integridad de Software y Datos"
  "a09-logging|A09 Registro y Alertas"
  "a10-exceptional-conditions|A10 Condiciones Excepcionales"
)

# ---------- chequeo de requisitos por lenguaje ----------
require_java17() {
  local v jhome
  if command -v /usr/libexec/java_home >/dev/null 2>&1; then
    jhome=$(/usr/libexec/java_home -v 17 2>/dev/null || true)
    if [ -n "$jhome" ]; then export JAVA_HOME="$jhome"; export PATH="$jhome/bin:$PATH"; fi
  fi
  if ! command -v java >/dev/null 2>&1; then
    echo "ERROR: no hay 'java' en el PATH. Se necesita JDK 17."; show_java_help; return 1
  fi
  v=$(java -version 2>&1 | head -1 | grep -oE '"[0-9]+' | tr -d '"' | head -1)
  if [ "${v:-0}" -lt 17 ] 2>/dev/null; then
    echo "ERROR: tu Java es versión $v, pero los ejemplos necesitan JDK 17+."
    show_java_help; return 1
  fi
  return 0
}
show_java_help() {
  cat <<'EOF'

  Instala JDK 17 (te va a pedir tu contraseña de macOS):
      brew install --cask temurin@17

  Después vuelve a correr ./demo.sh. Mientras tanto puedes usar node o python, que ya funcionan.
EOF
}
require_dart() {
  if ! command -v dart >/dev/null 2>&1 && ! command -v flutter >/dev/null 2>&1; then
    cat <<'EOF'
ERROR: no hay 'dart' ni 'flutter' en el PATH. Los ejemplos Flutter necesitan Dart.

  Instala Flutter (incluye Dart; te va a pedir tu contraseña de macOS):
      brew install --cask flutter

  Después vuelve a correr ./demo.sh. Mientras tanto puedes usar node o python.
EOF
    return 1
  fi
  return 0
}

langs_for() {
  local cat="$1" l
  for l in java node python flutter; do
    [ -d "$cat/$l/vulnerable" ] && echo "$l"
  done
}

choose_category() {
  echo
  echo "===== Ejemplos OWASP Top 10:2025 ====="
  local i=1 entry name
  for entry in "${CATS[@]}"; do
    name="${entry#*|}"; printf "  %2d) %s\n" "$i" "$name"; i=$((i+1))
  done
  echo
  local n; read -r -p "Elige un número (1-10): " n
  [[ "$n" =~ ^[0-9]+$ ]] && [ "$n" -ge 1 ] && [ "$n" -le 10 ] || { echo "Opción inválida."; exit 1; }
  CAT="${CATS[$((n-1))]%%|*}"
}

choose_language() {
  local cat="$1" opts=() l
  while IFS= read -r l; do opts+=("$l"); done < <(langs_for "$cat")
  if [ "${#opts[@]}" -eq 0 ]; then
    echo
    echo "Esta categoría no es una app de servidor. Mira su README y sus scripts:"
    echo "  examples/$cat/README.md"
    find "$cat" -name verify.sh | sed 's,^,  examples/,'
    exit 0
  fi
  if [ "${#opts[@]}" -eq 1 ]; then LANG_SEL="${opts[0]}"; return; fi
  echo
  echo "Lenguajes disponibles para esta categoría:"
  local i=1; for l in "${opts[@]}"; do printf "  %d) %s\n" "$i" "$l"; i=$((i+1)); done
  local n; read -r -p "Elige un lenguaje (1-${#opts[@]}): " n
  [[ "$n" =~ ^[0-9]+$ ]] && [ "$n" -ge 1 ] && [ "$n" -le "${#opts[@]}" ] || { echo "Opción inválida."; exit 1; }
  LANG_SEL="${opts[$((n-1))]}"
}

# ---------- selección ----------
if [ "$#" -ge 1 ]; then
  key="$1"; CAT=""
  for entry in "${CATS[@]}"; do
    folder="${entry%%|*}"; [[ "$folder" == "$key"* ]] && CAT="$folder" && break
  done
  [ -z "$CAT" ] && { echo "No se encontró la categoría '$key'. Prueba ./demo.sh sin argumentos."; exit 1; }
  if [ "$#" -ge 2 ]; then LANG_SEL="$2"; else choose_language "$CAT"; fi
else
  choose_category; choose_language "$CAT"
fi

VULN_DIR="$CAT/$LANG_SEL/vulnerable"
FIXED_DIR="$CAT/$LANG_SEL/fixed"
[ -d "$VULN_DIR" ] && [ -d "$FIXED_DIR" ] || { echo "No existe $VULN_DIR o $FIXED_DIR"; exit 1; }

# ---------- requisitos ----------
case "$LANG_SEL" in
  java)    require_java17 || exit 1 ;;
  flutter) require_dart   || exit 1 ;;
  node)    command -v node >/dev/null || { echo "ERROR: falta Node.js. Instala con: brew install node"; exit 1; } ;;
  python)  command -v python3 >/dev/null || { echo "ERROR: falta Python 3."; exit 1; } ;;
esac

# ---------- Flutter: no es servidor, corre tests ----------
if [ "$LANG_SEL" = "flutter" ]; then
  echo
  echo "== $CAT ($LANG_SEL) — paquete Dart, se demuestra con tests =="
  echo; echo ">>> VULNERABLE (el ataque tiene éxito):"; ( cd "$VULN_DIR" && ./run.sh )
  echo; echo ">>> CORREGIDO (el ataque se bloquea):";  ( cd "$FIXED_DIR" && ./run.sh )
  exit 0
fi

# ---------- averiguar el puerto de cada variante ----------
port_of() { grep -oE 'PORT:-[0-9]+' "$1/attack.sh" 2>/dev/null | head -1 | grep -oE '[0-9]+'; }
VPORT=$(port_of "$VULN_DIR"); FPORT=$(port_of "$FIXED_DIR")
VPORT="${VPORT:-8000}"; FPORT="${FPORT:-8001}"

# ---------- levantar ambos servidores ----------
PIDS=()
cleanup() {
  echo; echo "Deteniendo servidores..."
  for p in "${PIDS[@]:-}"; do [ -n "${p:-}" ] && kill "$p" 2>/dev/null; done
  pkill -P $$ 2>/dev/null || true
  for port in "$VPORT" "$FPORT"; do
    pid=$(lsof -nP -tiTCP:"$port" -sTCP:LISTEN 2>/dev/null || true); [ -n "$pid" ] && kill -9 $pid 2>/dev/null || true
  done
}
trap cleanup EXIT INT TERM

echo
echo "== $CAT ($LANG_SEL) =="
[ "$LANG_SEL" = "java" ] && echo "(Java compila en el primer arranque; puede tardar ~30-60 s)"
echo "Arrancando VULNERABLE (puerto $VPORT) y CORREGIDO (puerto $FPORT)..."

( cd "$VULN_DIR" && PORT="$VPORT" ./run.sh > /tmp/owasp-demo-vuln.log 2>&1 ) & PIDS+=("$!")
( cd "$FIXED_DIR" && PORT="$FPORT" ./run.sh > /tmp/owasp-demo-fixed.log 2>&1 ) & PIDS+=("$!")

wait_up() {  # $1=port $2=log  -> 0 si responde, 1 si el proceso murió o timeout
  local port="$1" log="$2" i
  for i in $(seq 1 120); do
    if (exec 3<>"/dev/tcp/127.0.0.1/$port") 2>/dev/null; then exec 3>&- 3<&-; return 0; fi
    # ¿el build falló?
    grep -qiE "APPLICATION FAILED|BUILD FAILURE|\[ERROR\]|Traceback|Error:" "$log" 2>/dev/null && return 2
    sleep 1
  done
  return 1
}

echo "Esperando a que respondan..."
wait_up "$VPORT" /tmp/owasp-demo-vuln.log; RV=$?
wait_up "$FPORT" /tmp/owasp-demo-fixed.log; RF=$?

if [ "$RV" -ne 0 ] || [ "$RF" -ne 0 ]; then
  echo
  echo "ERROR: alguno de los servidores no arrancó. Últimas líneas del log:"
  echo "--- VULNERABLE (/tmp/owasp-demo-vuln.log) ---"; tail -6 /tmp/owasp-demo-vuln.log
  echo "--- CORREGIDO  (/tmp/owasp-demo-fixed.log) ---"; tail -6 /tmp/owasp-demo-fixed.log
  exit 1
fi

echo
echo "============================================================"
echo " Ambos servidores RESPONDIENDO:"
echo "   VULNERABLE -> http://127.0.0.1:$VPORT      (examples/$VULN_DIR)"
echo "   CORREGIDO  -> http://127.0.0.1:$FPORT      (examples/$FIXED_DIR)"
echo "============================================================"
echo
echo ">>> ATAQUE contra la versión VULNERABLE:"
( cd "$VULN_DIR" && PORT="$VPORT" ./attack.sh )
echo
echo ">>> MISMO ATAQUE contra la versión CORREGIDA:"
( cd "$FIXED_DIR" && PORT="$FPORT" ./attack.sh )
echo
echo "------------------------------------------------------------"
echo "Para repetir el ataque a mano, en otra terminal:"
echo "   (cd examples/$VULN_DIR && PORT=$VPORT ./attack.sh)"
echo "   (cd examples/$FIXED_DIR && PORT=$FPORT ./attack.sh)"
echo "Detalle del caso: examples/$CAT/README.md"
echo "------------------------------------------------------------"
echo
echo ">> Servidores corriendo. Presiona Ctrl-C para detenerlos. <<"
wait
