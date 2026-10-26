"""A07:2025 Fallas de autenticacion (CWE-307) - VERSION VULNERABLE (stdlib).

Login SIN limite de intentos: fuerza bruta / credential stuffing ilimitado.
"""
import hmac
import json
import os
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs
from urllib.parse import urlparse as _urlparse, parse_qs as _parse_qs

PORT = int(os.environ.get("PORT", "8074"))

# Usuarios de demo en memoria
USERS = {"alice": "alice-pass-123", "bob": "bob-pass-456", "admin": "DEMO-ONLY-s3cr3t"}


def password_matches(username, password):
    expected = USERS.get(username)
    return expected is not None and hmac.compare_digest(expected.encode(), password.encode())


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
    def _send(self, status, body, headers=None):
        data = json.dumps(body).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        for k, v in (headers or {}).items():
            self.send_header(k, v)
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        # Pagina de inicio para ver el ejemplo en el navegador.
        if _urlparse(self.path).path in ("", "/"):
            return send_landing(self, landing_page('A07 Fallas de Autenticacion (fuerza bruta)', 'VULNERABLE', PORT, 'POST /login valida username y password de usuarios de demo (alice, bob, admin).', 'Un atacante prueba passwords sin parar. Esta version NO tiene contador de fallos, bloqueo ni rate limit: puedes enviar el form mil veces y siempre se evalua.', '<form method="post" action="/login"><code>POST /login</code><label>username <input name="username" value="alice"></label><label>password <input name="password" value="incorrecto"></label><button>Probar un password (repetilo muchas veces)</button></form>'))
        self._send(200, {"ok": True}) if self.path == "/health" else self._send(404, {"error": "not found"})

    def do_POST(self):
        if self.path != "/login":
            return self._send(404, {"error": "not found"})
        length = int(self.headers.get("Content-Length", 0))
        form = parse_qs(self.rfile.read(length).decode())
        username = form.get("username", [""])[0]
        password = form.get("password", [""])[0]
        # VULNERABLE: no hay contador de fallos, bloqueo ni rate limit. Cada intento se
        # procesa igual, asi que un atacante puede probar miles de passwords.
        if password_matches(username, password):
            return self._send(200, {"authenticated": True, "username": username})
        self._send(401, {"authenticated": False})

    def log_message(self, *args):
        pass


if __name__ == "__main__":
    print(f"A07 python vulnerable en http://127.0.0.1:{PORT}", flush=True)
    ThreadingHTTPServer(("127.0.0.1", PORT), Handler).serve_forever()
