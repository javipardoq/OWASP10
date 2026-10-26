package demo;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.*;

import jakarta.annotation.PostConstruct;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * A01:2025 Broken Access Control (IDOR) - VERSION CORREGIDA (Spring Boot + H2).
 *
 * GET /accounts/{id} devuelve el saldo de una cuenta bancaria. Autenticacion de demo:
 * cabecera X-User (alice o bob). alice es duena de 1001, bob de 1002.
 */
@SpringBootApplication
@RestController
public class App {

    private static final Set<String> KNOWN_USERS = Set.of("alice", "bob");
    private final JdbcTemplate jdbc;

    public App(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    // Pagina de inicio para ver el ejemplo en el navegador (los endpoints son API JSON).
    @GetMapping(value = "/", produces = "text/html;charset=UTF-8")
    public String landingPage(jakarta.servlet.http.HttpServletRequest req) {
        return Landing.page("A01 Control de Acceso Roto (IDOR)", "CORREGIDO", req.getLocalPort(),
            "GET /accounts/{id} devuelve el saldo de una cuenta. La autenticacion usa la cabecera X-User (alice o bob). alice es duena de la cuenta 1001, bob de la 1002.",
            "alice pide la cuenta 1002 (de bob). En esta version el servidor comprueba que la cuenta pertenezca al usuario autenticado y responde 403 sin revelar datos.",
            Landing.links(new String[][]{{"Tu propia cuenta: alice -> 1001","/accounts/1001?user=alice"},{"ATAQUE: alice -> cuenta 1002 de bob","/accounts/1002?user=alice"}}));
    }

    public static void main(String[] args) {
        SpringApplication.run(App.class, args);
    }

    @PostConstruct
    void seed() {
        jdbc.execute("CREATE TABLE accounts (id INT PRIMARY KEY, owner VARCHAR, balance INT)");
        jdbc.update("INSERT INTO accounts (id, owner, balance) VALUES (?,?,?)", 1001, "alice", 50000);
        jdbc.update("INSERT INTO accounts (id, owner, balance) VALUES (?,?,?)", 1002, "bob", 1200);
    }

    @GetMapping("/accounts/{id}")
    public ResponseEntity<Map<String, Object>> account(
            @PathVariable int id, @RequestHeader(value = "X-User", required = false) String userHeader,
            @RequestParam(value = "user", required = false) String userParam) {
        // El navegador no manda cabeceras facil: se acepta ?user= como alternativa (la cabecera tiene prioridad).
        String user = userHeader != null ? userHeader : userParam;
        // Autenticacion (demo): el usuario debe ser conocido -> 401 si no.
        if (user == null || !KNOWN_USERS.contains(user)) {
            return ResponseEntity.status(401).body(Map.of("error", "unauthenticated"));
        }
        List<Map<String, Object>> rows = jdbc.queryForList("SELECT id, owner, balance FROM accounts WHERE id = ?", id);
        if (rows.isEmpty()) {
            return ResponseEntity.status(404).body(Map.of("error", "not found"));
        }
        Map<String, Object> row = rows.get(0);
        // FIX: control de acceso en el servidor - el recurso debe pertenecer al usuario autenticado.
        // Se responde 403 sin revelar datos de la cuenta ajena.
        if (!user.equals(row.get("OWNER"))) {
            return ResponseEntity.status(403).body(Map.of("error", "forbidden"));
        }
        return ResponseEntity.ok(Map.of("id", id, "owner", row.get("OWNER"), "balance", row.get("BALANCE")));
    }
}
