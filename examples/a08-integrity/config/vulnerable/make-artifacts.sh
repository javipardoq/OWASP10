#!/usr/bin/env bash
# Genera localmente el artefacto legitimo y una copia manipulada (simula un mirror/CDN comprometido).
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p dist
# Contenido determinista: el hash del legitimo es siempre el mismo (ver PINNED.sha256 en fixed/)
printf '#!/usr/bin/env bash\necho "TOOL_OK: herramienta legitima v1.0"\n' > dist/tool-good.sh
printf '#!/usr/bin/env bash\necho "TAMPERED_CODE_RAN: codigo del atacante ejecutado"\n' > dist/tool-tampered.sh
