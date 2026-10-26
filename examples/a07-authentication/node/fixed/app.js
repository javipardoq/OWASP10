// A07:2025 Fallas de autenticacion (CWE-307) - VERSION CORREGIDA (Express).
// Bloqueo temporal por usuario tras N fallos consecutivos. Contador en memoria y
// por instancia (demo): en produccion usar Redis compartido + limite por IP + MFA.
const express = require('express');
const crypto = require('crypto');

const PORT = process.env.PORT || 8073;
const app = express();
app.use(express.urlencoded({ extended: false }));

const USERS = { alice: 'alice-pass-123', bob: 'bob-pass-456', admin: 'DEMO-ONLY-s3cr3t' };

// FIX: umbral y cooldown configurables (el test usa LOCKOUT_SECONDS=2).
const MAX_ATTEMPTS = 5;
const LOCKOUT_MS = Number(process.env.LOCKOUT_SECONDS || 30) * 1000;
const states = new Map(); // username -> { failures, lockedUntil }

function passwordMatches(username, password) {
  const expected = USERS[username];
  if (typeof expected !== 'string') return false;
  const a = Buffer.from(expected), b = Buffer.from(String(password));
  return a.length === b.length && crypto.timingSafeEqual(a, b);
}

// Pagina de inicio para ver el ejemplo en el navegador (los endpoints son API JSON).
app.get('/', (req, res) => {
  res.type('html').send(landingPage({
    titulo: 'A07 Fallas de Autenticacion',
    estado: 'CORREGIDO',
    port: PORT,
    descripcion: 'POST /login valida usuario y password (usuarios: alice, bob, admin).',
    ataque:
      'Fuerza bruta: probar passwords sin limite. Esta version bloquea al usuario tras 5 fallos seguidos: ' +
      'envia el form 6 veces y veras 429 (locked) con cabecera Retry-After.',
    formulario:
      '<form method="post" action="/login"><label>username <input name="username" value="admin"></label>' +
      '<label>password <input name="password" value="123456"></label><button>Probar password</button></form>',
  }));
});

app.get('/health', (req, res) => res.json({ ok: true }));

app.post('/login', (req, res) => {
  const { username, password } = req.body;
  const now = Date.now();
  let s = states.get(username);
  if (!s) { s = { failures: 0, lockedUntil: 0 }; states.set(username, s); }
  // FIX: durante el bloqueo se rechaza SIN evaluar el password (ni el correcto entra).
  if (s.lockedUntil > now) {
    res.set('Retry-After', String(Math.ceil((s.lockedUntil - now) / 1000)));
    return res.status(429).json({ authenticated: false, error: 'locked' });
  }
  if (passwordMatches(username, password)) {
    s.failures = 0; // exito: reinicia el contador
    return res.json({ authenticated: true, username });
  }
  s.failures += 1;
  if (s.failures >= MAX_ATTEMPTS) { // FIX: al llegar al umbral se bloquea la cuenta
    s.failures = 0;
    s.lockedUntil = now + LOCKOUT_MS;
  }
  res.status(401).json({ authenticated: false });
});

app.listen(PORT, '127.0.0.1', () => console.log(`A07 node fixed en http://127.0.0.1:${PORT}`));

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
