// A10:2025 Manejo incorrecto de condiciones excepcionales - VERSION FIXED (Express).
// Transferencias: el chequeo antifraude debe aprobar antes de mover fondos.
const express = require('express');
const app = express();
app.use(express.urlencoded({ extended: false }));

// Saldos en memoria (auto-sembrados)
const balances = { alice: 100000, bob: 500, mallory: 0 };

// Servicio "antifraude" (simulado). Lanza excepcion si riskScore no es numerico,
// igual que lo haria una dependencia caida o que recibe datos inesperados.
function fraudCheck(amount, riskScore) {
  const risk = Number(riskScore);
  if (!Number.isInteger(risk)) throw new Error(`FraudService: invalid riskScore '${riskScore}' at fraud-svc.internal:9443 (stack: FraudClient.parse)`);
  return amount <= 1000 && risk < 80; // true = aprobado
}

// Pagina de inicio para ver el ejemplo en el navegador (los endpoints son API JSON).
app.get('/', (req, res) => {
  res.type('html').send(landingPage({
    titulo: 'A10 Condiciones Excepcionales',
    estado: 'CORREGIDO',
    port: process.env.PORT || 8103,
    descripcion: 'POST /transfer mueve fondos solo si el chequeo antifraude aprueba. Un monto alto (5000) normalmente se deniega con 403.',
    ataque:
      'Enviar riskScore no numerico (abc) hace fallar el chequeo. Esta version falla cerrada (fail-closed): ' +
      'responde 503 generico, no mueve fondos y no revela detalles internos.',
    formulario: formTransfer(),
  }));
});

app.post('/transfer', (req, res) => {
  const { from, to, riskScore = '0' } = req.body;
  const amount = Number(req.body.amount);
  if (!(from in balances) || !(to in balances) || !(amount > 0)) return res.status(400).json({ error: 'bad request' });
  let approved = false; // FIX: denegado por defecto (deny by default)
  try {
    approved = fraudCheck(amount, riskScore);
  } catch (e) {
    // FIX: fail-closed - se registra el detalle SOLO en el log del servidor y se deniega
    console.error('fraud check failed:', e.message);
    // FIX: respuesta generica, sin detalles internos
    return res.status(503).json({ executed: false, error: 'transfer could not be processed' });
  }
  if (approved !== true) return res.status(403).json({ executed: false, error: 'denied by fraud check' });
  if (balances[from] < amount) return res.status(400).json({ executed: false, error: 'insufficient funds' });
  balances[from] -= amount; balances[to] += amount;
  res.json({ executed: true, from, to, amount, balance: balances[from] });
});

// FIX: manejador global - nunca filtrar stack traces ni mensajes internos
app.use((err, req, res, next) => res.status(500).json({ error: 'internal error' }));

app.listen(process.env.PORT || 8103, '127.0.0.1', () => console.log('a10 node fixed listening'));

// Pagina HTML de inicio, comun a vulnerable y fixed (solo cambian los textos).
function landingPage({ titulo, estado, port, descripcion, ataque, enlaces = [], formulario = "" }) {
  const color = estado === "VULNERABLE" ? "#c0392b" : "#1e8449";
  const items = enlaces
    .map((e) => `<li><a href="${e.href}">${e.texto}</a> <code>${e.href}</code></li>`)
    .join("\n");
  return `<!doctype html><html lang="es"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>${titulo} — ${estado}</title>
<style>
 body{font-family:-apple-system,Segoe UI,Roboto,sans-serif;max-width:720px;margin:2rem auto;padding:0 1rem;line-height:1.5;color:#222}
 .badge{display:inline-block;background:${color};color:#fff;padding:.2rem .6rem;border-radius:.3rem;font-weight:700;font-size:.85rem}
 code{background:#f4f4f4;padding:.1rem .3rem;border-radius:.2rem;font-size:.9em}
 li{margin:.4rem 0} a{color:#2563eb} .nota{color:#666;font-size:.9rem;margin-top:2rem}
 form{border:1px solid #ddd;border-radius:.4rem;padding:.8rem;margin:.8rem 0}
 label{display:block;margin:.3rem 0} input{padding:.2rem .4rem;margin-left:.4rem}
 button{margin-top:.5rem;padding:.3rem .8rem}
</style></head><body>
<h1>${titulo}</h1>
<p><span class="badge">${estado}</span> &nbsp; puerto ${port}</p>
<p>${descripcion}</p>
<h3>El ataque</h3><p>${ataque}</p>
<h3>Probalo en el navegador</h3>${formulario}<ul>${items}</ul>
<p class="nota">Estos endpoints son una API JSON. Desde la terminal: <code>./attack.sh</code>.
Compara esta version con la otra (vulnerable vs. corregida) y mira la diferencia en la respuesta.</p>
</body></html>`;
}

// Formulario de la pagina de inicio: transferencia grande con riskScore que rompe el chequeo.
function formTransfer() {
  return `<form method="post" action="/transfer"><label>from <input name="from" value="alice"></label>` +
    `<label>to <input name="to" value="mallory"></label><label>amount <input name="amount" value="5000"></label>` +
    `<label>riskScore <input name="riskScore" value="abc"></label><button>Transferir (ataque)</button></form>`;
}
