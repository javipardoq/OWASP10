// A05:2025 Inyeccion (SQL Injection) - VERSION VULNERABLE (Node + Express + sql.js)
//
// API de login de un banco de demo. Construye el SQL concatenando la entrada del
// usuario, por lo que es vulnerable a inyeccion SQL.
//
// Backend embebido: sql.js (SQLite compilado a WebAssembly, sin compilacion nativa).
// Se auto-siembra una BD en memoria al arrancar.

const express = require("express");
const initSqlJs = require("sql.js");

const PORT = parseInt(process.env.PORT || "8052", 10);

async function main() {
  const SQL = await initSqlJs();
  const db = new SQL.Database();
  db.run(`
    CREATE TABLE users (id INTEGER PRIMARY KEY, username TEXT, password TEXT, balance INTEGER);
    INSERT INTO users (username, password, balance) VALUES
      ('alice', 'alice-pass-123', 50000),
      ('bob',   'bob-pass-456',   1200),
      ('admin', 'DEMO-ONLY-s3cr3t', 9999999);
  `);

  const app = express();
  app.use(express.urlencoded({ extended: false }));

  // Pagina de inicio para ver el ejemplo en el navegador (los endpoints son API JSON).
  app.get("/", (req, res) => {
    res.type("html").send(landingPage({
      titulo: "A05 Inyeccion SQL",
      estado: "VULNERABLE",
      port: PORT,
      descripcion: "POST /login valida username y password contra una BD SQLite en memoria.",
      ataque:
        "Con username <code>admin' --</code> el atacante comenta la verificacion del password. " +
        "Esta version concatena la entrada en el SQL: entra como admin sin conocer la clave.",
      formulario:
        `<form method="post" action="/login"><label>username <input name="username" value="admin' --"></label>` +
        `<label>password <input name="password" value="cualquiera"></label><button>Enviar (ataque)</button></form>`,
    }));
  });

  app.post("/login", (req, res) => {
    const { username = "", password = "" } = req.body;
    // VULNERABLE: la entrada del usuario se concatena directamente en el SQL.
    // Con  username = admin' --  el atacante comenta la verificacion de password.
    const query =
      "SELECT username, balance FROM users " +
      `WHERE username = '${username}' AND password = '${password}'`;
    try {
      const stmt = db.prepare(query); // ejecuta el SQL manipulado por el atacante
      if (stmt.step()) {
        const row = stmt.getAsObject();
        stmt.free();
        return res.json({ authenticated: true, username: row.username, balance: row.balance });
      }
      stmt.free();
      return res.json({ authenticated: false });
    } catch (e) {
      return res.status(500).json({ error: String(e.message) });
    }
  });

  app.listen(PORT, "127.0.0.1", () => {
    console.log(`[VULNERABLE] A05 login escuchando en http://127.0.0.1:${PORT}`);
  });
}

main();

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
