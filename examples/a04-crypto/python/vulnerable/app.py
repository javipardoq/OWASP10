#!/usr/bin/env python3
"""
A04:2025 Fallos criptograficos - VERSION VULNERABLE

Registro/login con almacenamiento de passwords usando MD5 sin sal.
Solo stdlib. Los usuarios viven en memoria (se auto-siembra vacio al arrancar).
"""
import hashlib
import hmac
import http.server
import json
import os
import socketserver
import urllib.parse
from urllib.parse import urlparse as _urlparse, parse_qs as _parse_qs

PORT = int(os.environ.get("PORT", "8044"))

# Almacen en memoria: username -> hash del password
users = {}


def hash_password(password):
    # VULNERABLE: MD5 es rapido, esta roto y NO lleva sal. Mismo password => mismo hash,
    # y se revierte con diccionarios / rainbow tables en milisegundos.
    return hashlib.md5(password.encode()).hexdigest()


def register(username, password):
    users[username] = hash_password(password)
    # El hash se devuelve solo para la demo (simula una filtracion de la BD).
    return {"username": username, "stored_hash": users[username]}


def login(username, password):
    stored = users.get(username)
    ok = stored is not None and hmac.compare_digest(stored, hash_password(password))
    return {"authenticated": ok}


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


class Handler(http.server.BaseHTTPRequestHandler):
    def log_message(self, *args):
        pass

    def _send(self, code, obj):
        body = json.dumps(obj).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        # Pagina de inicio para ver el ejemplo en el navegador.
        if _urlparse(self.path).path in ("", "/"):
            return send_landing(self, landing_page('A04 Fallos Criptograficos', 'VULNERABLE', PORT, 'POST /register guarda el password de un usuario y POST /login lo verifica. Por demo, /register devuelve el hash almacenado (simula una filtracion de la BD).', 'Registra dos usuarios con el MISMO password y compara los hashes. Esta version usa MD5 sin sal: los hashes son identicos, se revierten con diccionarios y son rapidos de atacar.', '<form method="post" action="/register"><code>POST /register</code><label>username <input name="username" value="alice"></label><label>password <input name="password" value="Password123"></label><button>Registrar alice</button></form><form method="post" action="/register"><code>POST /register</code><label>username <input name="username" value="bob"></label><label>password <input name="password" value="Password123"></label><button>Registrar bob (mismo password)</button></form><form method="post" action="/login"><code>POST /login</code><label>username <input name="username" value="alice"></label><label>password <input name="password" value="Password123"></label><button>Login</button></form>'))
        self._send(404, {"error": "not found"})

    def do_POST(self):
        length = int(self.headers.get("Content-Length", 0))
        params = urllib.parse.parse_qs(self.rfile.read(length).decode())
        username = params.get("username", [""])[0]
        password = params.get("password", [""])[0]
        if self.path == "/register":
            return self._send(200, register(username, password))
        if self.path == "/login":
            return self._send(200, login(username, password))
        self._send(404, {"error": "not found"})


if __name__ == "__main__":
    socketserver.TCPServer.allow_reuse_address = True
    with socketserver.ThreadingTCPServer(("127.0.0.1", PORT), Handler) as httpd:
        print(f"[VULNERABLE] A04 passwords con MD5 en http://127.0.0.1:{PORT}")
        httpd.serve_forever()
