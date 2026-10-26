package demo;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * A09:2025 Fallas de registro y alertas de seguridad - VERSION CORREGIDA.
 *
 * Cada fallo de login emite un evento de seguridad estructurado (sin secretos) y,
 * al superar el umbral de fallos, se emite una ALERTA.
 */
@SpringBootApplication
@RestController
public class App {

    private static final String USER = "alice";
    private static final String PASSWORD = "DEMO-ONLY-s3cret";
    private static final int ALERT_THRESHOLD = 3;

    private final ConcurrentHashMap<String, AtomicInteger> failures = new ConcurrentHashMap<>();

    // Pagina de inicio para ver el ejemplo en el navegador (los endpoints son API JSON).
    @GetMapping(value = "/", produces = "text/html;charset=UTF-8")
    public String landingPage(jakarta.servlet.http.HttpServletRequest req) {
        return Landing.page("A09 Fallas de Registro y Alertas", "CORREGIDO", req.getLocalPort(),
            "POST /login valida credenciales. Un buen sistema deja registro de los intentos fallidos.",
            "Un atacante prueba passwords contra alice. Esta version registra cada fallo en el log del servidor. Revisa la consola.",
            Landing.form("/login", new String[][]{{"username","alice"},{"password","DEMO-ONLY-wrong-guess"}}, "ATAQUE: login fallido"));
    }

    public static void main(String[] args) {
        SpringApplication.run(App.class, args);
    }

    /** Evento estructurado (una linea JSON) a stdout; en produccion iria al SIEM. */
    private static void securityLog(String event, String username, String source, String extra) {
        System.out.println("SECURITY_EVENT {\"timestamp\":\"" + Instant.now() + "\",\"event\":\"" + event
                + "\",\"username\":\"" + sanitize(username) + "\",\"source\":\"" + sanitize(source) + "\"" + extra + "}");
    }

    // Evita inyeccion de logs (CWE-117): se eliminan caracteres de control y comillas
    private static String sanitize(String s) {
        return s.replaceAll("[^A-Za-z0-9@._:-]", "_");
    }

    @PostMapping("/login")
    public ResponseEntity<Map<String, Object>> login(@RequestParam String username, @RequestParam String password,
                                                     @RequestHeader(value = "X-Forwarded-For", defaultValue = "127.0.0.1") String source) {
        if (USER.equals(username) && PASSWORD.equals(password)) {
            failures.remove(username);
            securityLog("AUTH_SUCCESS", username, source, "");
            return ResponseEntity.ok(Map.of("authenticated", true));
        }
        // FIX: se registra el fallo (nunca la password) y se cuenta para alertar
        securityLog("AUTH_FAILURE", username, source, "");
        int count = failures.computeIfAbsent(username, k -> new AtomicInteger()).incrementAndGet();
        if (count >= ALERT_THRESHOLD) {
            // FIX: señal de alerta tras N fallos consecutivos (posible fuerza bruta)
            securityLog("ALERT", username, source, ",\"reason\":\"BRUTE_FORCE_SUSPECTED\",\"failures\":" + count);
        }
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("authenticated", false));
    }
}
