// A04:2025 Fallos criptograficos - VERSION VULNERABLE (Node + Express)
//
// Registro/login con passwords almacenados como MD5 sin sal.
// Los usuarios viven en memoria (se auto-siembra vacio al arrancar).

const express = require("express");
const crypto = require("crypto");

const PORT = parseInt(process.env.PORT || "8042", 10);

// Almacen en memoria: username -> hash del password
const users = new Map();

// VULNERABLE: MD5 es rapido, esta roto y NO lleva sal. Mismo password => mismo hash,
// y se revierte con diccionarios / rainbow tables en milisegundos.
function hashPassword(password) {
  return crypto.createHash("md5").update(password).digest("hex");
}

function verifyPassword(password, stored) {
  const a = Buffer.from(hashPassword(password));
  const b = Buffer.from(stored);
  return a.length === b.length && crypto.timingSafeEqual(a, b);
}

const app = express();
app.use(express.urlencoded({ extended: false }));

// Pagina de inicio para ver el ejemplo en el navegador (los endpoints son API JSON).
app.get("/", (req, res) => {
  res.type("html").send(landingPage({
    titulo: "A04 Fallos Criptograficos",
    estado: "VULNERABLE",
    port: PORT,
    descripcion: "POST /register guarda el password y devuelve el hash almacenado (simula una filtracion de BD). POST /login valida credenciales.",
    ataque:
      "Registra dos usuarios con el MISMO password y compara los hashes. Aqui se usa MD5 sin sal: " +
      "los hashes son identicos y se revierten con diccionarios en milisegundos.",
    formulario: formRegistro(),
  }));
});

app.post("/register", async (req, res) => {
  const { username = "", password = "" } = req.body;
  users.set(username, hashPassword(password));
  // El hash se devuelve solo para la demo (simula una filtracion de la BD).
  res.json({ username, stored_hash: users.get(username) });
});

app.post("/login", async (req, res) => {
  const { username = "", password = "" } = req.body;
  const stored = users.get(username);
  res.json({ authenticated: stored !== undefined && verifyPassword(password, stored) });
});

app.listen(PORT, "127.0.0.1", () => {
  console.log(`[VULNERABLE] A04 passwords con MD5 en http://127.0.0.1:${PORT}`);
});

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

// Formularios de la pagina de inicio: dos registros con el mismo password y un login.
function formRegistro() {
  const reg = (u) =>
    `<form method="post" action="/register"><label>username <input name="username" value="${u}"></label>` +
    `<label>password <input name="password" value="Password123"></label><button>Registrar ${u}</button></form>`;
  return reg("alice") + reg("bob") +
    `<form method="post" action="/login"><label>username <input name="username" value="alice"></label>` +
    `<label>password <input name="password" value="Password123"></label><button>Login</button></form>`;
}
