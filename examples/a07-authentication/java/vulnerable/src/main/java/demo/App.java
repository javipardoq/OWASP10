package demo;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.Map;

/**
 * A07:2025 Fallas de autenticacion (CWE-307) - VERSION VULNERABLE (Spring Boot).
 *
 * Login de un banco de demo SIN limite de intentos: permite fuerza bruta y
 * credential stuffing ilimitados contra una cuenta.
 */
@SpringBootApplication
@RestController
public class App {

    // Usuarios de demo en memoria (password en claro solo para simplificar la demo)
    private static final Map<String, String> USERS = Map.of(
            "alice", "alice-pass-123",
            "bob", "bob-pass-456",
            "admin", "DEMO-ONLY-s3cr3t");

    // Pagina de inicio para ver el ejemplo en el navegador (los endpoints son API JSON).
    @GetMapping(value = "/", produces = "text/html;charset=UTF-8")
    public String landingPage(jakarta.servlet.http.HttpServletRequest req) {
        return Landing.page("A07 Fallas de Autenticacion", "VULNERABLE", req.getLocalPort(),
            "POST /login valida usuario y password. alice es un usuario valido.",
            "Fuerza bruta: probar muchos passwords contra alice. La version vulnerable procesa todos los intentos sin limite; la corregida responde 429 tras 5 fallos.",
            Landing.form("/login", new String[][]{{"username","alice"},{"password","guess-1"}}, "ATAQUE: probar password (repetilo varias veces)"));
    }

    public static void main(String[] args) {
        SpringApplication.run(App.class, args);
    }

    @GetMapping("/health")
    public Map<String, Object> health() {
        return Map.of("ok", true);
    }

    @PostMapping("/login")
    public ResponseEntity<Map<String, Object>> login(@RequestParam String username, @RequestParam String password) {
        // VULNERABLE: no hay contador de fallos, bloqueo ni rate limit. Cada intento
        // se procesa igual, asi que un atacante puede probar miles de passwords.
        if (passwordMatches(username, password)) {
            return ResponseEntity.ok(Map.of("authenticated", true, "username", username));
        }
        return ResponseEntity.status(401).body(Map.of("authenticated", false));
    }

    static boolean passwordMatches(String username, String password) {
        String expected = USERS.get(username);
        if (expected == null) return false;
        return MessageDigest.isEqual(expected.getBytes(StandardCharsets.UTF_8), password.getBytes(StandardCharsets.UTF_8));
    }
}
