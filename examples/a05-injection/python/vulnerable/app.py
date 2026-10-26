#!/usr/bin/env python3
"""
A05:2025 Inyeccion (SQL Injection) - VERSION VULNERABLE

API de login de un banco de demostracion. Construye la consulta SQL concatenando
directamente la entrada del usuario, por lo que es vulnerable a inyeccion SQL.

Solo stdlib. Se auto-siembra una base SQLite en memoria al arrancar.
"""
import http.server
import json
import socketserver
import sqlite3
import os
import urllib.parse
from urllib.parse import urlparse as _urlparse, parse_qs as _parse_qs

PORT = int(os.environ.get("PORT", "8054"))

# BD SQLite en memoria, compartida entre hilos (check_same_thread=False solo para la demo).
db = sqlite3.connect(":memory:", check_same_thread=False)
db.executescript(
    """
    CREATE TABLE users (id INTEGER PRIMARY KEY, username TEXT, password TEXT, balance INTEGER);
    INSERT INTO users (username, password, balance) VALUES
        ('alice', 'alice-pass-123', 50000),
        ('bob',   'bob-pass-456',   1200),
        ('admin', 'DEMO-ONLY-s3cr3t', 9999999);
    """
)


def login(username, password):
    # VULNERABLE: la entrada del usuario se concatena directamente en el SQL.
    # Un atacante puede inyectar  ' OR '1'='1  y saltarse la autenticacion.
    query = (
        "SELECT username, balance FROM users "
        f"WHERE username = '{username}' AND password = '{password}'"
    )
    cur = db.execute(query)  # ejecuta el SQL manipulado por el atacante
    row = cur.fetchone()
    if row:
        return {"authenticated": True, "username": row[0], "balance": row[1]}
    return {"authenticated": False}


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
            return send_landing(self, landing_page('A05 Inyeccion (SQL Injection)', 'VULNERABLE', PORT, 'POST /login valida username y password contra una base SQLite. El usuario admin existe, pero su password es desconocido.', "Con username <code>admin&#39; --</code> la consulta concatenada queda <code>... WHERE username = 'admin' --' AND password = ...</code>: el resto se comenta y se entra como admin sin password.", '<form method="post" action="/login"><code>POST /login</code><label>username <input name="username" value="admin&#39; --"></label><label>password <input name="password" value="cualquiera"></label><button>Intentar login con la inyeccion</button></form>'))
        self._send(404, {"error": "not found"})

    def do_POST(self):
        if self.path != "/login":
            return self._send(404, {"error": "not found"})
        length = int(self.headers.get("Content-Length", 0))
        raw = self.rfile.read(length).decode()
        params = urllib.parse.parse_qs(raw)
        username = params.get("username", [""])[0]
        password = params.get("password", [""])[0]
        try:
            self._send(200, login(username, password))
        except Exception as e:  # noqa: BLE001 - demo
            self._send(500, {"error": str(e)})


if __name__ == "__main__":
    socketserver.TCPServer.allow_reuse_address = True
    with socketserver.ThreadingTCPServer(("127.0.0.1", PORT), Handler) as httpd:
        print(f"[VULNERABLE] A05 login escuchando en http://127.0.0.1:{PORT}")
        httpd.serve_forever()
