package demo;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * A04:2025 Fallos criptograficos - VERSION CORREGIDA (Spring Boot).
 *
 * Registro/login con BCrypt (sal aleatoria por password + factor de trabajo 12).
 * Solo se usa spring-security-crypto; no se activa Spring Security. Usuarios en memoria.
 */
@SpringBootApplication
@RestController
public class App {

    // Almacen en memoria: username -> hash del password
    private final Map<String, String> users = new ConcurrentHashMap<>();

    // FIX: BCrypt genera una sal aleatoria por password e incluye el factor de trabajo (cost 12).
    private final BCryptPasswordEncoder encoder = new BCryptPasswordEncoder(12);

    // Pagina de inicio para ver el ejemplo en el navegador (los endpoints son API JSON).
    @GetMapping(value = "/", produces = "text/html;charset=UTF-8")
    public String landingPage(jakarta.servlet.http.HttpServletRequest req) {
        return Landing.page("A04 Fallos Criptograficos", "CORREGIDO", req.getLocalPort(),
            "POST /register guarda el password de un usuario y devuelve el hash almacenado (simula una filtracion de la BD). POST /login verifica credenciales.",
            "Registrar dos usuarios con el MISMO password y comparar los hashes. Con BCrypt (sal aleatoria + factor de trabajo 12) cada hash es distinto.",
            Landing.form("/register", new String[][]{{"username","alice"},{"password","password123"}}, "Registrar alice") + Landing.form("/register", new String[][]{{"username","bob"},{"password","password123"}}, "Registrar bob (mismo password)") + Landing.form("/login", new String[][]{{"username","alice"},{"password","password123"}}, "Login"));
    }

    public static void main(String[] args) {
        SpringApplication.run(App.class, args);
    }

    @PostMapping("/register")
    public Map<String, Object> register(@RequestParam String username, @RequestParam String password) {
        String hash = encoder.encode(password); // FIX: mismo password => hash distinto cada vez
        users.put(username, hash);
        // El hash se devuelve solo para la demo (simula una filtracion de la BD).
        return Map.of("username", username, "stored_hash", hash);
    }

    @PostMapping("/login")
    public Map<String, Object> login(@RequestParam String username, @RequestParam String password) {
        String stored = users.get(username);
        return Map.of("authenticated", stored != null && encoder.matches(password, stored));
    }
}
