// A02:2025 Security Misconfiguration - version VULNERABLE (Node/Express 5).
// API con /profile?id=N. Un id mal formado provoca un error del servidor.
const express = require('express');

const PORT = process.env.PORT || 8022;
const ALLOWED_ORIGIN = 'https://app.itau-demo.example'; // origen unico permitido (demo)
const USERS = { 1: { id: 1, name: 'alice', email: 'alice@example.com' }, 2: { id: 2, name: 'bob', email: 'bob@example.com' } };

const app = express();

app.use((req, res, next) => {
  // VULNERABLE: cualquier origen puede leer las respuestas
  res.set('Access-Control-Allow-Origin', '*');
  res.set('X-Powered-By', 'Express 5.3.0'); // VULNERABLE: revela el framework
  next();
});

function loadProfile(rawId) {
  // Falla con un id no numerico (provoca el error del servidor)
  if (!/^\d+$/.test(rawId)) throw new Error(`SQL error: SELECT id, name, email FROM users WHERE id = ${rawId}`);
  return USERS[Number(rawId)];
}

// Pagina de inicio para ver el ejemplo en el navegador (los endpoints son API JSON).
app.get('/', (req, res) => {
  res.type('html').send(landingPage({
    titulo: 'A02 Mala Configuracion de Seguridad',
    estado: 'VULNERABLE',
    port: PORT,
    descripcion: 'GET /profile?id=N devuelve el perfil de un usuario (ids 1 y 2). CORS abierto y cabecera X-Powered-By activa.',
    ataque: 'Un id mal formado (abc) provoca un error. Esta version responde 500 filtrando mensaje SQL, stack trace, version de Node y ruta del servidor.',
    enlaces: [
      { texto: 'Perfil valido (OK)', href: '/profile?id=1' },
      { texto: 'Id invalido: provoca el error y filtra el stack trace', href: '/profile?id=abc' },
    ],
  }));
});

app.get('/profile', (req, res) => {
  const row = loadProfile(String(req.query.id ?? ''));
  if (!row) return res.status(404).json({ error: 'not found' });
  res.json(row);
});

// Manejador global de errores (Express 5 captura excepciones sincronas)
app.use((err, req, res, next) => {
  // VULNERABLE: stack trace, SQL, rutas de archivo y versiones al cliente
  res.status(500).json({ error: err.message, stackTrace: err.stack, node: process.version, cwd: process.cwd() });
});

app.listen(PORT, '127.0.0.1', () => console.log(`escuchando en http://127.0.0.1:${PORT}`));

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
