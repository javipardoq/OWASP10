// A05:2025 Inyeccion (SQL Injection) - VERSION CORREGIDA (Node + Express + sql.js)
//
// Misma API de login, pero con consultas parametrizadas. La entrada del usuario viaja
// como parametro ligado (bind), separada del texto SQL, asi la inyeccion deja de funcionar.

const express = require("express");
const initSqlJs = require("sql.js");

const PORT = parseInt(process.env.PORT || "8053", 10);

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
      estado: "CORREGIDO",
      port: PORT,
      descripcion: "POST /login valida username y password contra una BD SQLite en memoria.",
      ataque:
        "Con username <code>admin' --</code> el atacante intenta comentar la verificacion del password. " +
        "Esta version usa consultas parametrizadas: la entrada es un dato, no codigo, y el login falla.",
      formulario:
        `<form method="post" action="/login"><label>username <input name="username" value="admin' --"></label>` +
        `<label>password <input name="password" value="cualquiera"></label><button>Enviar (ataque)</button></form>`,
    }));
  });

  app.post("/login", (req, res) => {
    const { username = "", password = "" } = req.body;
    try {
      // FIX: consulta parametrizada. Los '?' son marcadores; sql.js liga los valores
      // por separado del texto SQL, por lo que el contenido nunca se interpreta como codigo.
      const stmt = db.prepare(
        "SELECT username, balance FROM users WHERE username = ? AND password = ?"
      );
      stmt.bind([username, password]);
      if (stmt.step()) {
        const row = stmt.getAsObject();
        stmt.free();
        return res.json({ authenticated: true, username: row.username, balance: row.balance });
      }
      stmt.free();
      return res.json({ authenticated: false });
    } catch (e) {
      // FIX: no se exponen detalles internos del error al cliente.
      return res.status(500).json({ error: "internal error" });
    }
  });

  app.listen(PORT, "127.0.0.1", () => {
    console.log(`[FIXED] A05 login escuchando en http://127.0.0.1:${PORT}`);
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
