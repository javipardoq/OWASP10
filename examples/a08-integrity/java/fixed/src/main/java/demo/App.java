package demo;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.io.IOException;
import java.io.ObjectInputStream;
import java.io.Serializable;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Map;
import java.util.Set;

/**
 * A08:2025 Fallas de integridad de software o datos - VERSION CORREGIDA.
 *
 * Misma app y mismos endpoints. La clase EvilPrefs sigue en el classpath, pero ya
 * no existe ningun camino de codigo que deserialice bytes del atacante.
 */
@SpringBootApplication
@RestController
public class App {

    static volatile boolean pwned = false;

    /** DTO fijo: solo datos, sin comportamiento. */
    public record Prefs(String theme, String language) {}

    public static class EvilPrefs implements Serializable {
        private static final long serialVersionUID = 1L;

        private void readObject(ObjectInputStream in) throws IOException, ClassNotFoundException {
            in.defaultReadObject();
            pwned = true;
            Files.writeString(Path.of("PWNED.marker"), "codigo ejecutado durante readObject()\n");
        }
    }

    private static final Set<String> THEMES = Set.of("light", "dark");
    private static final Set<String> LANGUAGES = Set.of("es", "en", "pt");

    // Pagina de inicio para ver el ejemplo en el navegador (los endpoints son API JSON).
    @GetMapping(value = "/", produces = "text/html;charset=UTF-8")
    public String landingPage(jakarta.servlet.http.HttpServletRequest req) {
        return Landing.page("A08 Fallas de Integridad de Software y Datos", "CORREGIDO", req.getLocalPort(),
            "POST /load-prefs recibe preferencias serializadas (application/octet-stream). GET /pwned indica si se ejecuto codigo del atacante.",
            "Un objeto Java serializado malicioso es rechazado: la version corregida restringe las clases permitidas al deserializar.",
            Landing.links(new String[][]{{"Estado: /pwned","/pwned"}}) + "<p>El payload es binario: no se puede enviar desde un formulario. Ejecuta <code>./attack.sh</code> y luego recarga <code>/pwned</code>.</p>");
    }

    public static void main(String[] args) {
        SpringApplication.run(App.class, args);
    }

    // FIX: solo JSON (Content-Type application/json) hacia un DTO fijo; sin serializacion
    // nativa de Java para entrada no confiable.
    @PostMapping(value = "/load-prefs", consumes = "application/json")
    public ResponseEntity<Map<String, Object>> loadPrefs(@RequestBody Prefs prefs) {
        // FIX: validacion estricta con lista blanca de valores
        if (prefs.theme() == null || !THEMES.contains(prefs.theme())
                || prefs.language() == null || !LANGUAGES.contains(prefs.language())) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(Map.of("loaded", false, "error", "invalid prefs"));
        }
        return ResponseEntity.ok(Map.of("loaded", true, "theme", prefs.theme(), "language", prefs.language()));
    }

    @GetMapping("/pwned")
    public Map<String, Object> pwned() {
        return Map.of("pwned", pwned || Files.exists(Path.of("PWNED.marker")));
    }
}
