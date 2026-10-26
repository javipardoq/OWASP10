#!/usr/bin/env python3
"""A02:2025 Security Misconfiguration - version FIXED (Python stdlib).

API con /profile?id=N. Un id mal formado provoca un error del servidor.
"""
import json
import os
import sqlite3
import sys
import traceback
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import urlparse, parse_qs
from urllib.parse import urlparse as _urlparse, parse_qs as _parse_qs

PORT = int(os.environ.get("PORT", "8025"))
ALLOWED_ORIGIN = "https://app.itau-demo.example"  # origen unico permitido (demo)

db = sqlite3.connect(":memory:", check_same_thread=False)
db.execute("CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT, email TEXT)")
db.execute("INSERT INTO users VALUES (1, 'alice', 'alice@example.com')")
db.execute("INSERT INTO users VALUES (2, 'bob', 'bob@example.com')")


def load_profile(raw_id):
    # Falla con un id no numerico (provoca el error del servidor)
    return db.execute("SELECT id, name, email FROM users WHERE id = " + str(int(raw_id))).fetchone()


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
    def cors(self):
        # FIX: solo el origen de la allow-list; el resto no recibe cabecera CORS
        self.send_header("Vary", "Origin")
        if self.headers.get("Origin") == ALLOWED_ORIGIN:
            self.send_header("Access-Control-Allow-Origin", ALLOWED_ORIGIN)
        self.send_header("X-Content-Type-Options", "nosniff")

    def send_json(self, status, body):
        data = json.dumps(body).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.cors()
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        # Pagina de inicio para ver el ejemplo en el navegador.
        if _urlparse(self.path).path in ("", "/"):
            return send_landing(self, landing_page('A02 Configuracion de Seguridad Incorrecta', 'CORREGIDO', PORT, 'GET /profile?id=N devuelve el perfil de un usuario. Un id mal formado provoca un error del servidor.', 'Un id no numerico dispara una excepcion. Esta version devuelve solo un mensaje generico (el detalle queda en el log del servidor) y restringe CORS a una allow-list.', '<ul><li><a href="/profile?id=1">Perfil valido: id=1 (ok)</a> <code>/profile?id=1</code></li><li><a href="/profile?id=abc">ATAQUE: id=abc (dispara el error)</a> <code>/profile?id=abc</code></li></ul>'))
        url = urlparse(self.path)
        if url.path != "/profile":
            return self.send_json(404, {"error": "not found"})
        raw_id = parse_qs(url.query).get("id", [""])[0]
        try:
            row = load_profile(raw_id)
            if row is None:
                return self.send_json(404, {"error": "not found"})
            self.send_json(200, {"id": row[0], "name": row[1], "email": row[2]})
        except Exception as exc:
            # FIX: el detalle queda en el log del servidor; el cliente recibe un mensaje generico
            traceback.print_exc()
            self.send_json(500, {"error": "internal server error"})

    def log_message(self, fmt, *args):
        pass


if __name__ == "__main__":
    print(f"escuchando en http://127.0.0.1:{PORT}", flush=True)
    HTTPServer(("127.0.0.1", PORT), Handler).serve_forever()
