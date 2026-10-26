// A07:2025 Fallas de autenticacion (CWE-307) - VERSION VULNERABLE (Express).
// Login SIN limite de intentos: fuerza bruta / credential stuffing ilimitado.
const express = require('express');
const crypto = require('crypto');

const PORT = process.env.PORT || 8072;
const app = express();
app.use(express.urlencoded({ extended: false }));

// Usuarios de demo en memoria
const USERS = { alice: 'alice-pass-123', bob: 'bob-pass-456', admin: 'DEMO-ONLY-s3cr3t' };

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
    estado: 'VULNERABLE',
    port: PORT,
    descripcion: 'POST /login valida usuario y password (usuarios: alice, bob, admin).',
    ataque:
      'Fuerza bruta: probar passwords sin limite. Esta version no tiene contador de fallos ni bloqueo, ' +
      'asi que podes enviar el form tantas veces como quieras (siempre 401, nunca 429).',
    formulario:
      '<form method="post" action="/login"><label>username <input name="username" value="admin"></label>' +
      '<label>password <input name="password" value="123456"></label><button>Probar password</button></form>',
  }));
});

app.get('/health', (req, res) => res.json({ ok: true }));

app.post('/login', (req, res) => {
  const { username, password } = req.body;
  // VULNERABLE: no hay contador de fallos, bloqueo ni rate limit. Cada intento se
  // procesa igual, asi que un atacante puede probar miles de passwords.
  if (passwordMatches(username, password)) return res.json({ authenticated: true, username });
  res.status(401).json({ authenticated: false });
});

app.listen(PORT, '127.0.0.1', () => console.log(`A07 node vulnerable en http://127.0.0.1:${PORT}`));

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
