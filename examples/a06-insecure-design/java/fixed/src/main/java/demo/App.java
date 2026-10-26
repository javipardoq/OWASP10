package demo;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * A06:2025 Diseno Inseguro - VERSION CORREGIDA (Spring Boot).
 *
 * El diseno ahora modela las reglas de negocio como requisitos de seguridad explicitos
 * (parte del threat model, ver THREAT-MODEL.md):
 *   R1. El monto debe ser > 0.
 *   R2. No se puede transferir mas que el saldo disponible.
 *   R3. Origen y destino deben existir y ser distintos.
 * Estas validaciones se aplican de forma centralizada, antes de mover fondos.
 */
@SpringBootApplication
@RestController
public class App {

    private final Map<String, Integer> balances = new ConcurrentHashMap<>(Map.of(
            "alice", 1000,
            "bob", 1000
    ));

    // Pagina de inicio para ver el ejemplo en el navegador (los endpoints son API JSON).
    @GetMapping(value = "/", produces = "text/html;charset=UTF-8")
    public String landingPage(jakarta.servlet.http.HttpServletRequest req) {
        return Landing.page("A06 Diseno Inseguro", "CORREGIDO", req.getLocalPort(),
            "POST /transfer (from, to, amount) mueve dinero entre cuentas; GET /balance/{account} consulta el saldo.",
            "Una transferencia con monto NEGATIVO (-500) intenta invertir el flujo. La version corregida valida el monto y lo rechaza.",
            Landing.links(new String[][]{{"Saldo de alice","/balance/alice"},{"Saldo de bob","/balance/bob"}}) + Landing.form("/transfer", new String[][]{{"from","alice"},{"to","bob"},{"amount","-500"}}, "ATAQUE: transferir -500"));
    }

    public static void main(String[] args) {
        SpringApplication.run(App.class, args);
    }

    @GetMapping("/balance/{account}")
    public Map<String, Object> balance(@PathVariable String account) {
        return Map.of("account", account, "balance", balances.getOrDefault(account, 0));
    }

    @PostMapping("/transfer")
    public ResponseEntity<Map<String, Object>> transfer(@RequestParam String from,
                                                         @RequestParam String to,
                                                         @RequestParam int amount) {
        // FIX: validar las reglas de negocio (caso de abuso modelado en el diseno).
        if (amount <= 0) {                                   // R1
            return bad("el monto debe ser positivo");
        }
        if (from.equals(to)) {                               // R3
            return bad("origen y destino deben ser distintos");
        }
        if (!balances.containsKey(from) || !balances.containsKey(to)) {
            return bad("cuenta inexistente");
        }
        synchronized (balances) {
            int fromBalance = balances.get(from);
            if (fromBalance < amount) {                      // R2
                return bad("saldo insuficiente");
            }
            balances.put(from, fromBalance - amount);
            balances.merge(to, amount, Integer::sum);
        }
        return ResponseEntity.ok(Map.of(
                "ok", true,
                "from", from, "fromBalance", balances.get(from),
                "to", to, "toBalance", balances.get(to)
        ));
    }

    private ResponseEntity<Map<String, Object>> bad(String reason) {
        return ResponseEntity.badRequest().body(Map.of("ok", false, "error", reason));
    }
}
