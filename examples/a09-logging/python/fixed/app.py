#!/usr/bin/env python3
"""A09:2025 Fallas de registro y alertas - VERSION CORREGIDA (solo stdlib).

Cada fallo de login emite un evento de seguridad estructurado (sin secretos) y, al superar
el umbral de fallos, una ALERTA.
"""
import json
import logging
import os
import sys
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import parse_qs
from urllib.parse import urlparse as _urlparse, parse_qs as _parse_qs

ALERT_THRESHOLD = 3
USER = "alice"
PASSWORD = "DEMO-ONLY-s3cret"  # credencial falsa de demo

failures = {}  # username -> fallos consecutivos

# Logger de seguridad dedicado: una linea JSON por evento a stdout (en produccion, al SIEM)
security_log = logging.getLogger("security")
security_log.setLevel(logging.INFO)
_h = logging.StreamHandler(sys.stdout)
_h.setFormatter(logging.Formatter("SECURITY_EVENT %(message)s"))
security_log.addHandler(_h)
security_log.propagate = False


def sanitize(value):
    # Evita inyeccion de logs (CWE-117): solo caracteres seguros
    return "".join(c if c.isalnum() or c in "@._:-" else "_" for c in value)


def security_event(event, username, source, **extra):
    security_log.info(json.dumps({
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "event": event, "username": sanitize(username), "source": sanitize(source), **extra}))


# Pagina HTML de inicio, comun a vulnerable y fixed (solo cambian los textos).
def landing_page(titulo, estado, port, descripcion, ataque, contenido):
    color = "#c0392b" if estado == "VULNERABLE" else "#1e8449"
    return """<!doctype html><html lang="es"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>@TITULO@ — @ESTADO@</title>
<style>
 body{font-family:-apple-system,Segoe UI,Roboto,sans-serif;max-width:720px;margin:2rem auto;padding:0 1rem;line-height:1.5;color:#222}
 .badge{display:inline-block;background:@COLOR@;color:#fff;padding:.2rem .6rem;border-radius:.3rem;font-weight:700;font-size:.85rem}
 code{background:#f4f4f4;padding:.1rem .3rem;border-radius:.2rem;font-size:.9em}
 li{margin:.4rem 0} a{color:#2563eb} .nota{color:#666;font-size:.9rem;margin-top:2rem}
 form{border:1px solid #ddd;border-radius:.4rem;padding:.6rem 1rem;margin:.8rem 0} label{display:block;margin:.3rem 0}
 input{font:inherit;padding:.2rem .4rem} button{font:inherit;padding:.3rem .8rem;margin-top:.4rem}
</style></head><body>
<h1>@TITULO@</h1>
<p><span class="badge">@ESTADO@</span> &nbsp; puerto @PORT@</p>
<p>@DESC@</p>
<h3>El ataque</h3><p>@ATAQUE@</p>
<h3>Probalo en el navegador</h3>@CONTENIDO@
<p class="nota">Estos endpoints son una API JSON. Desde la terminal: <code>./attack.sh</code>.
Compara esta version con la otra (vulnerable vs. corregida) y mira la diferencia en la respuesta.</p>
</body></html>""".replace("@TITULO@", titulo).replace("@ESTADO@", estado).replace(
        "@COLOR@", color).replace("@PORT@", str(port)).replace("@DESC@", descripcion).replace(
        "@ATAQUE@", ataque).replace("@CONTENIDO@", contenido)


def send_landing(handler, html):
    # Responde la pagina de inicio en HTML (GET /).
    body = html.encode("utf-8")
    handler.send_response(200)
    handler.send_header("Content-Type", "text/html; charset=utf-8")
    handler.send_header("Content-Length", str(len(body)))
    handler.end_headers()
    handler.wfile.write(body)


class Handler(BaseHTTPRequestHandler):
    def log_message(self, *args):
        pass  # sin access log por defecto de http.server

    def _send(self, code, body):
        data = json.dumps(body).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        # Pagina de inicio para ver el ejemplo en el navegador.
        if _urlparse(self.path).path in ("", "/"):
            return send_landing(self, landing_page('A09 Fallas de Registro y Alertas', 'CORREGIDO', PORT, 'POST /login valida las credenciales de alice. Lo que importa es lo que el servidor REGISTRA en su salida.', 'Envia varios logins fallidos. Esta version emite un evento AUTH_FAILURE por cada fallo (sin secretos) y una ALERT al llegar a 3 fallos; miralo en la consola del servidor.', '<form method="post" action="/login"><code>POST /login</code><label>username <input name="username" value="alice"></label><label>password <input name="password" value="incorrecto"></label><button>Login fallido (repetilo 3 veces)</button></form>'))
        self._send(404, {"error": "not found"})

    def do_POST(self):
        if self.path != "/login":
            return self._send(404, {"error": "not found"})
        length = int(self.headers.get("Content-Length", 0))
        form = parse_qs(self.rfile.read(length).decode())
        username = form.get("username", [""])[0]
        password = form.get("password", [""])[0]
        source = self.headers.get("X-Forwarded-For", self.client_address[0])
        if username == USER and password == PASSWORD:
            failures.pop(username, None)
            security_event("AUTH_SUCCESS", username, source)
            return self._send(200, {"authenticated": True})
        # FIX: se registra el fallo (nunca la password) y se cuenta para alertar
        security_event("AUTH_FAILURE", username, source)
        failures[username] = failures.get(username, 0) + 1
        if failures[username] >= ALERT_THRESHOLD:
            # FIX: senal de alerta tras N fallos consecutivos (posible fuerza bruta)
            security_event("ALERT", username, source, reason="BRUTE_FORCE_SUSPECTED", failures=failures[username])
        return self._send(401, {"authenticated": False})


if __name__ == "__main__":
    port = int(os.environ.get("PORT", "8095"))
    HTTPServer(("127.0.0.1", port), Handler).serve_forever()
