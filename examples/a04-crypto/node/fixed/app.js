// A04:2025 Fallos criptograficos - VERSION CORREGIDA (Node + Express)
//
// Registro/login con PBKDF2-HMAC-SHA256, sal aleatoria por password y 600000 iteraciones
// (stdlib crypto, sin dependencias nativas). Los usuarios viven en memoria.

const express = require("express");
const crypto = require("crypto");
const { promisify } = require("util");

const pbkdf2 = promisify(crypto.pbkdf2);
const PORT = parseInt(process.env.PORT || "8043", 10);
const ITERATIONS = 600000; // FIX: factor de trabajo recomendado por OWASP para PBKDF2-HMAC-SHA256

// Almacen en memoria: username -> hash del password
const users = new Map();

async function hashPassword(password) {
  // FIX: sal aleatoria unica por password + KDF lento (PBKDF2). Mismo password => hash distinto.
  const salt = crypto.randomBytes(16);
  const dk = await pbkdf2(password, salt, ITERATIONS, 32, "sha256");
  return `pbkdf2_sha256$${ITERATIONS}$${salt.toString("hex")}$${dk.toString("hex")}`;
}

async function verifyPassword(password, stored) {
  const [, iters, saltHex, dkHex] = stored.split("$");
  const dk = await pbkdf2(password, Buffer.from(saltHex, "hex"), parseInt(iters, 10), 32, "sha256");
  return crypto.timingSafeEqual(dk, Buffer.from(dkHex, "hex")); // tiempo constante
}

const app = express();
app.use(express.urlencoded({ extended: false }));

// Pagina de inicio para ver el ejemplo en el navegador (los endpoints son API JSON).
app.get("/", (req, res) => {
  res.type("html").send(landingPage({
    titulo: "A04 Fallos Criptograficos",
    estado: "CORREGIDO",
    port: PORT,
    descripcion: "POST /register guarda el password y devuelve el hash almacenado (simula una filtracion de BD). POST /login valida credenciales.",
    ataque:
      "Registra dos usuarios con el MISMO password y compara los hashes. Aqui se usa PBKDF2 con sal " +
      "aleatoria y 600000 iteraciones: los hashes son distintos y costosos de atacar.",
    formulario: formRegistro(),
  }));
});

app.post("/register", async (req, res) => {
  const { username = "", password = "" } = req.body;
  users.set(username, await hashPassword(password));
  // El hash se devuelve solo para la demo (simula una filtracion de la BD).
  res.json({ username, stored_hash: users.get(username) });
});

app.post("/login", async (req, res) => {
  const { username = "", password = "" } = req.body;
  const stored = users.get(username);
  res.json({ authenticated: stored !== undefined && (await verifyPassword(password, stored)) });
});

app.listen(PORT, "127.0.0.1", () => {
  console.log(`[FIXED] A04 passwords con PBKDF2 en http://127.0.0.1:${PORT}`);
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
