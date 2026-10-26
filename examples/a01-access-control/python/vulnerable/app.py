#!/usr/bin/env python3
"""
A01:2025 Broken Access Control (IDOR) - VERSION VULNERABLE

GET /accounts/<id> devuelve el saldo de una cuenta bancaria. Autenticacion de demo:
cabecera X-User (alice o bob). alice es duena de 1001, bob de 1002.

Solo stdlib. SQLite en memoria, auto-sembrada al arrancar.
"""
import http.server
import json
import os
import re
import socketserver
import sqlite3
from urllib.parse import urlparse as _urlparse, parse_qs as _parse_qs

PORT = int(os.environ.get("PORT", "8014"))
KNOWN_USERS = {"alice", "bob"}

db = sqlite3.connect(":memory:", check_same_thread=False)
db.executescript(
    """
    CREATE TABLE accounts (id INTEGER PRIMARY KEY, owner TEXT, balance INTEGER);
    INSERT INTO accounts (id, owner, balance) VALUES
        (1001, 'alice', 50000),
        (1002, 'bob',   1200);
    """
)


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
            return send_landing(self, landing_page('A01 Control de Acceso Roto (IDOR)', 'VULNERABLE', PORT, 'GET /accounts/{id} devuelve el saldo de una cuenta. La autenticacion usa la cabecera X-User (alice o bob). alice es duena de la cuenta 1001, bob de la 1002.', 'alice pide la cuenta 1002 (de bob). En esta version SOLO se valida que estes autenticado, nunca que la cuenta sea tuya, asi que devuelve el saldo ajeno.', '<ul><li><a href="/accounts/1001?user=alice">Tu propia cuenta: alice -> 1001</a> <code>/accounts/1001?user=alice</code></li><li><a href="/accounts/1002?user=alice">ATAQUE: alice -> cuenta 1002 de bob</a> <code>/accounts/1002?user=alice</code></li></ul>'))
        m = re.fullmatch(r"/accounts/(\d+)", _urlparse(self.path).path)
        if not m:
            return self._send(404, {"error": "not found"})
        # Autenticacion (demo): el usuario debe ser conocido -> 401 si no.
        # En el navegador no se pueden poner cabeceras facil: ademas se acepta ?user= (la cabecera tiene prioridad).
        user = self.headers.get("X-User") or _parse_qs(_urlparse(self.path).query).get("user", [None])[0]
        if user not in KNOWN_USERS:
            return self._send(401, {"error": "unauthenticated"})
        acc = db.execute("SELECT id, owner, balance FROM accounts WHERE id = ?", (int(m.group(1)),)).fetchone()
        if acc is None:
            return self._send(404, {"error": "not found"})
        # VULNERABLE: solo se comprueba que el usuario esta autenticado; nunca que la cuenta sea suya (IDOR).
        # alice puede pedir /accounts/1002 y leer el saldo de bob.
        return self._send(200, {"id": acc[0], "owner": acc[1], "balance": acc[2]})


if __name__ == "__main__":
    socketserver.TCPServer.allow_reuse_address = True
    with socketserver.ThreadingTCPServer(("127.0.0.1", PORT), Handler) as httpd:
        print(f"[VULNERABLE] A01 cuentas escuchando en http://127.0.0.1:{PORT}")
        httpd.serve_forever()
