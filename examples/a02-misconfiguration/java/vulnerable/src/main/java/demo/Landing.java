package demo;

/** Pagina HTML de inicio (comun a vulnerable y fixed; solo cambian los textos). */
final class Landing {
    private Landing() {}

    static String page(String titulo, String estado, int port, String descripcion, String ataque, String cuerpo) {
        String color = "VULNERABLE".equals(estado) ? "#c0392b" : "#1e8449";
        return "<!doctype html><html lang=\"es\"><head><meta charset=\"utf-8\">\n"
            + "<meta name=\"viewport\" content=\"width=device-width,initial-scale=1\">\n"
            + "<title>" + titulo + " — " + estado + "</title>\n"
            + "<style>\n"
            + " body{font-family:-apple-system,Segoe UI,Roboto,sans-serif;max-width:720px;margin:2rem auto;padding:0 1rem;line-height:1.5;color:#222}\n"
            + " .badge{display:inline-block;background:" + color + ";color:#fff;padding:.2rem .6rem;border-radius:.3rem;font-weight:700;font-size:.85rem}\n"
            + " code{background:#f4f4f4;padding:.1rem .3rem;border-radius:.2rem;font-size:.9em}\n"
            + " li{margin:.4rem 0} a{color:#2563eb} .nota{color:#666;font-size:.9rem;margin-top:2rem}\n"
            + " form{border:1px solid #ddd;border-radius:.4rem;padding:.6rem 1rem;margin:.6rem 0} input{margin:.2rem 0;padding:.2rem}\n"
            + "</style></head><body>\n"
            + "<h1>" + titulo + "</h1>\n"
            + "<p><span class=\"badge\">" + estado + "</span> &nbsp; puerto " + port + "</p>\n"
            + "<p>" + descripcion + "</p>\n"
            + "<h3>El ataque</h3><p>" + ataque + "</p>\n"
            + "<h3>Probalo en el navegador</h3>" + cuerpo + "\n"
            + "<p class=\"nota\">Estos endpoints son una API JSON. Desde la terminal: <code>./attack.sh</code>.\n"
            + "Compara esta version con la otra (vulnerable vs. corregida) y mira la diferencia en la respuesta.</p>\n"
            + "</body></html>";
    }

    /** Lista de enlaces: pares {texto, href}. */
    static String links(String[][] items) {
        StringBuilder sb = new StringBuilder("<ul>");
        for (String[] e : items) {
            sb.append("<li><a href=\"").append(e[1]).append("\">").append(e[0]).append("</a> <code>")
              .append(e[1]).append("</code></li>");
        }
        return sb.append("</ul>").toString();
    }

    /** Formulario POST: campos {nombre, valor}. */
    static String form(String action, String[][] fields, String boton) {
        StringBuilder sb = new StringBuilder("<form method=\"post\" action=\"" + action + "\">");
        for (String[] f : fields) {
            sb.append("<div><label>").append(f[0]).append(": <input name=\"").append(f[0])
              .append("\" value=\"").append(f[1].replace("\"", "&quot;")).append("\"></label></div>");
        }
        return sb.append("<button type=\"submit\">").append(boton).append("</button></form>").toString();
    }
}
