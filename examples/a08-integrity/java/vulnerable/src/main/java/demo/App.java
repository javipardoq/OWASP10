package demo;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.*;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.ObjectInputStream;
import java.io.Serializable;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Map;

/**
 * A08:2025 Fallas de integridad de software o datos - VERSION VULNERABLE.
 *
 * POST /load-prefs recibe preferencias de usuario serializadas. GET /pwned indica si
 * se ejecuto codigo durante la deserializacion (efecto inofensivo: flag + PWNED.marker).
 */
@SpringBootApplication
@RestController
public class App {

    // Flag en memoria que prueba la ejecucion de codigo (solo para la demo)
    static volatile boolean pwned = false;

    /** Preferencias legitimas del usuario. */
    public static class Prefs implements Serializable {
        private static final long serialVersionUID = 1L;
        public String theme = "light";
        public String language = "es";
    }

    /**
     * Clase "gadget" de demo: su readObject() tiene un efecto secundario. En un ataque
     * real seria una cadena de gadgets de una libreria (Commons Collections, etc.) con RCE.
     */
    public static class EvilPrefs implements Serializable {
        private static final long serialVersionUID = 1L;

        private void readObject(ObjectInputStream in) throws IOException, ClassNotFoundException {
            in.defaultReadObject();
            pwned = true; // efecto inofensivo: flag + archivo marcador dentro de la carpeta
            Files.writeString(Path.of("PWNED.marker"), "codigo ejecutado durante readObject()\n");
        }
    }

    // Pagina de inicio para ver el ejemplo en el navegador (los endpoints son API JSON).
    @GetMapping(value = "/", produces = "text/html;charset=UTF-8")
    public String landingPage(jakarta.servlet.http.HttpServletRequest req) {
        return Landing.page("A08 Fallas de Integridad de Software y Datos", "VULNERABLE", req.getLocalPort(),
            "POST /load-prefs recibe preferencias serializadas (application/octet-stream). GET /pwned indica si se ejecuto codigo del atacante.",
            "Un objeto Java serializado malicioso es deserializado sin validar y ejecuta codigo (se activa el flag /pwned). La version corregida restringe lo que se puede deserializar.",
            Landing.links(new String[][]{{"Estado: /pwned","/pwned"}}) + "<p>El payload es binario: no se puede enviar desde un formulario. Ejecuta <code>./attack.sh</code> y luego recarga <code>/pwned</code>.</p>");
    }

    public static void main(String[] args) {
        SpringApplication.run(App.class, args);
    }

    @PostMapping("/load-prefs")
    public Map<String, Object> loadPrefs(@RequestBody byte[] body) {
        // VULNERABLE: readObject() sobre bytes controlados por el atacante; instancia
        // CUALQUIER clase serializable del classpath y ejecuta su readObject().
        try (ObjectInputStream in = new ObjectInputStream(new ByteArrayInputStream(body))) {
            Object obj = in.readObject();
            Prefs prefs = (Prefs) obj; // el cast llega tarde: el codigo ya se ejecuto
            return Map.of("loaded", true, "theme", prefs.theme, "language", prefs.language);
        } catch (Exception e) {
            return Map.of("loaded", false, "error", e.getClass().getSimpleName());
        }
    }

    @GetMapping("/pwned")
    public Map<String, Object> pwned() {
        return Map.of("pwned", pwned || Files.exists(Path.of("PWNED.marker")));
    }
}
