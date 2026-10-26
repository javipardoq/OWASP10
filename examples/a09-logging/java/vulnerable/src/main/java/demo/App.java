package demo;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * A09:2025 Fallas de registro y alertas de seguridad - VERSION VULNERABLE.
 *
 * Falla demostrada: los intentos de login FALLIDOS no dejan NINGUN registro
 * (sin auditoria, sin alertas). Un ataque de fuerza bruta pasa desapercibido.
 */
@SpringBootApplication
@RestController
public class App {

    // Credencial falsa de demo
    private static final String USER = "alice";
    private static final String PASSWORD = "DEMO-ONLY-s3cret";

    // Pagina de inicio para ver el ejemplo en el navegador (los endpoints son API JSON).
    @GetMapping(value = "/", produces = "text/html;charset=UTF-8")
    public String landingPage(jakarta.servlet.http.HttpServletRequest req) {
        return Landing.page("A09 Fallas de Registro y Alertas", "VULNERABLE", req.getLocalPort(),
            "POST /login valida credenciales. Un buen sistema deja registro de los intentos fallidos.",
            "Un atacante prueba passwords contra alice. La version vulnerable no registra los fallos (ataque invisible); la corregida deja registro de cada intento. Revisa el log del servidor.",
            Landing.form("/login", new String[][]{{"username","alice"},{"password","DEMO-ONLY-wrong-guess"}}, "ATAQUE: login fallido"));
    }

    public static void main(String[] args) {
        SpringApplication.run(App.class, args);
    }

    @PostMapping("/login")
    public ResponseEntity<Map<String, Object>> login(@RequestParam String username, @RequestParam String password,
                                                     @RequestHeader(value = "X-Forwarded-For", defaultValue = "127.0.0.1") String source) {
        if (USER.equals(username) && PASSWORD.equals(password)) {
            return ResponseEntity.ok(Map.of("authenticated", true));
        }
        // VULNERABLE: el fallo de autenticacion no se registra ni cuenta para alertas
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("authenticated", false));
    }
}
