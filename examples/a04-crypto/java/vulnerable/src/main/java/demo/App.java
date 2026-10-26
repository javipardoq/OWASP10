package demo;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.*;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.HexFormat;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * A04:2025 Fallos criptograficos - VERSION VULNERABLE (Spring Boot).
 *
 * Registro/login con passwords almacenados como MD5 sin sal. Usuarios en memoria.
 */
@SpringBootApplication
@RestController
public class App {

    // Almacen en memoria: username -> hash del password
    private final Map<String, String> users = new ConcurrentHashMap<>();

    // Pagina de inicio para ver el ejemplo en el navegador (los endpoints son API JSON).
    @GetMapping(value = "/", produces = "text/html;charset=UTF-8")
    public String landingPage(jakarta.servlet.http.HttpServletRequest req) {
        return Landing.page("A04 Fallos Criptograficos", "VULNERABLE", req.getLocalPort(),
            "POST /register guarda el password de un usuario y devuelve el hash almacenado (simula una filtracion de la BD). POST /login verifica credenciales.",
            "Registrar dos usuarios con el MISMO password y comparar los hashes. En MD5 sin sal son identicos y se revierten con diccionarios; con BCrypt cada hash es distinto.",
            Landing.form("/register", new String[][]{{"username","alice"},{"password","password123"}}, "Registrar alice") + Landing.form("/register", new String[][]{{"username","bob"},{"password","password123"}}, "Registrar bob (mismo password)") + Landing.form("/login", new String[][]{{"username","alice"},{"password","password123"}}, "Login"));
    }

    public static void main(String[] args) {
        SpringApplication.run(App.class, args);
    }

    static String hashPassword(String password) throws Exception {
        // VULNERABLE: MD5 es rapido, esta roto y NO lleva sal. Mismo password => mismo hash,
        // y se revierte con diccionarios / rainbow tables en milisegundos.
        MessageDigest md = MessageDigest.getInstance("MD5");
        return HexFormat.of().formatHex(md.digest(password.getBytes(StandardCharsets.UTF_8)));
    }

    @PostMapping("/register")
    public Map<String, Object> register(@RequestParam String username, @RequestParam String password) throws Exception {
        String hash = hashPassword(password);
        users.put(username, hash);
        // El hash se devuelve solo para la demo (simula una filtracion de la BD).
        return Map.of("username", username, "stored_hash", hash);
    }

    @PostMapping("/login")
    public Map<String, Object> login(@RequestParam String username, @RequestParam String password) throws Exception {
        String stored = users.get(username);
        boolean ok = stored != null && MessageDigest.isEqual(
                stored.getBytes(StandardCharsets.UTF_8), hashPassword(password).getBytes(StandardCharsets.UTF_8));
        return Map.of("authenticated", ok);
    }
}
