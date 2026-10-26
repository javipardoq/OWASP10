// A01:2025 Broken Access Control (IDOR) - VERSION VULNERABLE (Node + Express)
//
// GET /accounts/:id devuelve el saldo de una cuenta bancaria. Autenticacion de demo:
// cabecera X-User (alice o bob). alice es duena de 1001, bob de 1002.
// Datos en memoria (sin BD), auto-sembrados al arrancar.

const express = require("express");

const PORT = parseInt(process.env.PORT || "8012", 10);
const KNOWN_USERS = new Set(["alice", "bob"]);
const accounts = new Map([
  [1001, { id: 1001, owner: "alice", balance: 50000 }],
  [1002, { id: 1002, owner: "bob", balance: 1200 }],
]);

const app = express();

// Pagina de inicio para ver el ejemplo en el navegador (los endpoints son API JSON).
app.get("/", (req, res) => {
  res.type("html").send(landingPage({
    titulo: "A01 Control de Acceso Roto (IDOR)",
    estado: "VULNERABLE",
    port: PORT,
    descripcion:
      "GET /accounts/{id} devuelve el saldo de una cuenta. La autenticacion usa la cabecera " +
      "X-User (alice o bob). alice es duena de la cuenta 1001, bob de la 1002.",
    ataque:
      "alice pide la cuenta 1002 (de bob). En esta version SOLO se valida que estes " +
      "autenticado, nunca que la cuenta sea tuya, asi que devuelve el saldo ajeno.",
    enlaces: [
      { texto: "Tu propia cuenta: alice -> 1001", href: `/accounts/1001?user=alice` },
      { texto: "ATAQUE: alice -> cuenta 1002 de bob", href: `/accounts/1002?user=alice` },
    ],
  }));
});

app.get("/accounts/:id", (req, res) => {
  // Autenticacion (demo): el usuario debe ser conocido -> 401 si no.
  // En el navegador no se pueden poner cabeceras facil, asi que ademas aceptamos ?user=
  const user = req.get("X-User") || req.query.user;
  if (!user || !KNOWN_USERS.has(user)) {
    return res.status(401).json({ error: "unauthenticated" });
  }
  const acc = accounts.get(parseInt(req.params.id, 10));
  if (!acc) {
    return res.status(404).json({ error: "not found" });
  }
    // VULNERABLE: solo se comprueba que el usuario esta autenticado; nunca que la cuenta sea suya (IDOR).
    // alice puede pedir /accounts/1002 y leer el saldo de bob.
    return res.json({ id: acc.id, owner: acc.owner, balance: acc.balance });
});

app.listen(PORT, "127.0.0.1", () => {
  console.log(`[VULNERABLE] A01 cuentas escuchando en http://127.0.0.1:${PORT}`);
});

// Pagina HTML de inicio, comun a vulnerable y fixed (solo cambian los textos).
function landingPage({ titulo, estado, port, descripcion, ataque, enlaces }) {
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
</style></head><body>
<h1>${titulo}</h1>
<p><span class="badge">${estado}</span> &nbsp; puerto ${port}</p>
<p>${descripcion}</p>
<h3>El ataque</h3><p>${ataque}</p>
<h3>Probalo en el navegador</h3><ul>${items}</ul>
<p class="nota">Estos endpoints son una API JSON. Desde la terminal: <code>./attack.sh</code>.
Compara esta version con la otra (vulnerable vs. corregida) y mira la diferencia en la respuesta.</p>
</body></html>`;
}
