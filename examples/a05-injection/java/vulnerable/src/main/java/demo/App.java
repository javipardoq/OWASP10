package demo;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.*;

import jakarta.annotation.PostConstruct;
import java.util.List;
import java.util.Map;

/**
 * A05:2025 Inyeccion (SQL Injection) - VERSION VULNERABLE (Spring Boot + H2).
 *
 * API de login de un banco de demo. Construye el SQL concatenando la entrada del
 * usuario, por lo que es vulnerable a inyeccion SQL. H2 en memoria, auto-sembrada.
 */
@SpringBootApplication
@RestController
public class App {

    private final JdbcTemplate jdbc;

    public App(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    // Pagina de inicio para ver el ejemplo en el navegador (los endpoints son API JSON).
    @GetMapping(value = "/", produces = "text/html;charset=UTF-8")
    public String landingPage(jakarta.servlet.http.HttpServletRequest req) {
        return Landing.page("A05 Inyeccion SQL", "VULNERABLE", req.getLocalPort(),
            "POST /login valida username y password contra una tabla de usuarios (alice, bob, admin).",
            "Con username <code>admin' --</code> (y cualquier password) la version vulnerable concatena la entrada en el SQL, comenta la verificacion del password y autentica como admin.",
            Landing.form("/login", new String[][]{{"username","admin' --"},{"password","cualquiera"}}, "ATAQUE: login como admin") + Landing.form("/login", new String[][]{{"username","alice"},{"password","alice-pass-123"}}, "Login legitimo"));
    }

    public static void main(String[] args) {
        SpringApplication.run(App.class, args);
    }

    @PostConstruct
    void seed() {
        jdbc.execute("CREATE TABLE users (id INT PRIMARY KEY AUTO_INCREMENT, username VARCHAR, password VARCHAR, balance INT)");
        jdbc.update("INSERT INTO users (username, password, balance) VALUES (?,?,?)", "alice", "alice-pass-123", 50000);
        jdbc.update("INSERT INTO users (username, password, balance) VALUES (?,?,?)", "bob", "bob-pass-456", 1200);
        jdbc.update("INSERT INTO users (username, password, balance) VALUES (?,?,?)", "admin", "DEMO-ONLY-s3cr3t", 9999999);
    }

    @PostMapping("/login")
    public Map<String, Object> login(@RequestParam String username, @RequestParam String password) {
        // VULNERABLE: la entrada del usuario se concatena directamente en el SQL.
        // Con  username = admin' --  el atacante comenta la verificacion de password.
        String sql = "SELECT username, balance FROM users "
                + "WHERE username = '" + username + "' AND password = '" + password + "'";
        List<Map<String, Object>> rows = jdbc.queryForList(sql); // ejecuta SQL manipulado
        if (!rows.isEmpty()) {
            Map<String, Object> r = rows.get(0);
            return Map.of("authenticated", true, "username", r.get("USERNAME"), "balance", r.get("BALANCE"));
        }
        return Map.of("authenticated", false);
    }
}
