#!/usr/bin/env python3
# A10:2025 Manejo incorrecto de condiciones excepcionales - VERSION FIXED (stdlib).
# Transferencias: el chequeo antifraude debe aprobar antes de mover fondos.
import json, os, traceback
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs
from urllib.parse import urlparse as _urlparse, parse_qs as _parse_qs

# Saldos en memoria (auto-sembrados)
balances = {"alice": 100000, "bob": 500, "mallory": 0}


def fraud_check(amount, risk_score):
    """Servicio antifraude simulado: lanza excepcion si riskScore no es numerico
    (como una dependencia caida o que recibe datos inesperados)."""
    try:
        risk = int(risk_score)
    except ValueError:
        raise RuntimeError("FraudService: invalid riskScore '%s' at fraud-svc.internal:9443 (stack: FraudClient.parse)" % risk_score)
    return amount <= 1000 and risk < 80  # True = aprobado


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
    def _send(self, code, obj):
        body = json.dumps(obj).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, *a):
        pass

    def do_GET(self):
        # Pagina de inicio para ver el ejemplo en el navegador.
        if _urlparse(self.path).path in ("", "/"):
            return send_landing(self, landing_page('A10 Manejo Incorrecto de Condiciones Excepcionales', 'CORREGIDO', PORT, 'POST /transfer mueve fondos entre cuentas (alice, bob, mallory) tras pasar un chequeo antifraude que recibe amount y riskScore.', 'Con un riskScore no numerico (<code>abc</code>) el chequeo antifraude lanza una excepcion. Esta version falla CERRADO: deniega la transferencia (503) con un mensaje generico, sin filtrar detalles.', '<form method="post" action="/transfer"><code>POST /transfer</code><label>from <input name="from" value="alice"></label><label>to <input name="to" value="mallory"></label><label>amount <input name="amount" value="5000"></label><label>riskScore <input name="riskScore" value="abc"></label><button>Transferir 5000 con riskScore invalido</button></form>'))
        self._send(404, {"error": "not found"})

    def do_POST(self):
        if self.path != "/transfer":
            return self._send(404, {"error": "not found"})
        n = int(self.headers.get("Content-Length") or 0)
        form = {k: v[0] for k, v in parse_qs(self.rfile.read(n).decode()).items()}
        src, dst = form.get("from"), form.get("to")
        risk_score = form.get("riskScore", "0")
        try:
            amount = int(form.get("amount", ""))
        except ValueError:
            amount = 0
        if src not in balances or dst not in balances or amount <= 0:
            return self._send(400, {"error": "bad request"})
        approved = False  # FIX: denegado por defecto (deny by default)
        try:
            approved = fraud_check(amount, risk_score)
        except Exception:
            # FIX: fail-closed - detalle solo en el log del servidor; se deniega
            traceback.print_exc()
            # FIX: respuesta generica, sin detalles internos
            return self._send(503, {"executed": False, "error": "transfer could not be processed"})
        if approved is not True:
            return self._send(403, {"executed": False, "error": "denied by fraud check"})
        if balances[src] < amount:
            return self._send(400, {"executed": False, "error": "insufficient funds"})
        balances[src] -= amount
        balances[dst] += amount
        self._send(200, {"executed": True, "from": src, "to": dst, "amount": amount, "balance": balances[src]})


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8105))
    print("a10 python fixed listening on", port, flush=True)
    ThreadingHTTPServer(("127.0.0.1", port), Handler).serve_forever()
