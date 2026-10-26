package demo;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.HashMap;
import java.util.Map;

/**
 * A07:2025 Fallas de autenticacion (CWE-307) - VERSION CORREGIDA (Spring Boot).
 *
 * Igual que la vulnerable, pero con bloqueo temporal por usuario tras N fallos
 * consecutivos. NOTA: el contador es en memoria y por instancia (demo); en
 * produccion usar un almacen compartido (Redis) y combinar con limite por IP/MFA.
 */
@SpringBootApplication
@RestController
public class App {

    private static final Map<String, String> USERS = Map.of(
            "alice", "alice-pass-123",
            "bob", "bob-pass-456",
            "admin", "DEMO-ONLY-s3cr3t");

    // FIX: umbral y cooldown configurables (el test usa LOCKOUT_SECONDS=2).
    private static final int MAX_ATTEMPTS = 5;
    private final long lockoutMillis;

    private static final class State { int failures; long lockedUntil; }
    private final Map<String, State> states = new HashMap<>();

    public App(@Value("${LOCKOUT_SECONDS:30}") long lockoutSeconds) {
        this.lockoutMillis = lockoutSeconds * 1000;
    }

    // Pagina de inicio para ver el ejemplo en el navegador (los endpoints son API JSON).
    @GetMapping(value = "/", produces = "text/html;charset=UTF-8")
    public String landingPage(jakarta.servlet.http.HttpServletRequest req) {
        return Landing.page("A07 Fallas de Autenticacion", "CORREGIDO", req.getLocalPort(),
            "POST /login valida usuario y password. alice es un usuario valido.",
            "Fuerza bruta: probar muchos passwords contra alice. Esta version limita los intentos y responde 429 tras 5 fallos. Envia el formulario varias veces para verlo.",
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
    public synchronized ResponseEntity<Map<String, Object>> login(@RequestParam String username, @RequestParam String password) {
        long now = System.currentTimeMillis();
        State s = states.computeIfAbsent(username, k -> new State());
        // FIX: durante el bloqueo se rechaza SIN evaluar el password (ni el correcto entra).
        if (s.lockedUntil > now) {
            long retry = (s.lockedUntil - now + 999) / 1000;
            return ResponseEntity.status(429).header("Retry-After", String.valueOf(retry))
                    .body(Map.of("authenticated", false, "error", "locked"));
        }
        if (passwordMatches(username, password)) {
            s.failures = 0; // exito: reinicia el contador
            return ResponseEntity.ok(Map.of("authenticated", true, "username", username));
        }
        s.failures++;
        if (s.failures >= MAX_ATTEMPTS) { // FIX: al llegar al umbral se bloquea la cuenta
            s.failures = 0;
            s.lockedUntil = now + lockoutMillis;
        }
        return ResponseEntity.status(401).body(Map.of("authenticated", false));
    }

    static boolean passwordMatches(String username, String password) {
        String expected = USERS.get(username);
        if (expected == null) return false;
        return MessageDigest.isEqual(expected.getBytes(StandardCharsets.UTF_8), password.getBytes(StandardCharsets.UTF_8));
    }
}
