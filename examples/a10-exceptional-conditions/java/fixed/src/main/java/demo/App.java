package demo;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.LinkedHashMap;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * A10:2025 Manejo incorrecto de condiciones excepcionales - VERSION FIXED (Spring Boot).
 * Transferencias: el chequeo antifraude debe aprobar antes de mover fondos.
 */
@SpringBootApplication
@RestController
public class App {

    // Saldos en memoria (auto-sembrados)
    private final Map<String, Long> balances = new ConcurrentHashMap<>(Map.of("alice", 100000L, "bob", 500L, "mallory", 0L));

    // Pagina de inicio para ver el ejemplo en el navegador (los endpoints son API JSON).
    @GetMapping(value = "/", produces = "text/html;charset=UTF-8")
    public String landingPage(jakarta.servlet.http.HttpServletRequest req) {
        return Landing.page("A10 Manejo Incorrecto de Condiciones Excepcionales", "CORREGIDO", req.getLocalPort(),
            "POST /transfer ejecuta transferencias pasando por un chequeo antifraude que usa riskScore.",
            "Con riskScore no numerico (abc) el chequeo lanza una excepcion; la version corregida falla cerrada y la transferencia NO se ejecuta.",
            Landing.form("/transfer", new String[][]{{"from","alice"},{"to","mallory"},{"amount","50000"},{"riskScore","abc"}}, "ATAQUE: riskScore=abc"));
    }

    public static void main(String[] args) {
        SpringApplication.run(App.class, args);
    }

    // Servicio antifraude simulado: lanza excepcion si riskScore no es numerico
    // (como una dependencia caida o que recibe datos inesperados).
    private boolean fraudCheck(long amount, String riskScore) {
        int risk;
        try {
            risk = Integer.parseInt(riskScore);
        } catch (NumberFormatException e) {
            throw new IllegalStateException("FraudService: invalid riskScore '" + riskScore + "' at fraud-svc.internal:9443 (stack: FraudClient.parse)", e);
        }
        return amount <= 1000 && risk < 80; // true = aprobado
    }

    @PostMapping("/transfer")
    public ResponseEntity<Map<String, Object>> transfer(@RequestParam String from, @RequestParam String to,
                                                        @RequestParam long amount,
                                                        @RequestParam(defaultValue = "0") String riskScore) {
        if (!balances.containsKey(from) || !balances.containsKey(to) || amount <= 0)
            return ResponseEntity.badRequest().body(Map.of("error", "bad request"));
        boolean approved = false; // FIX: denegado por defecto (deny by default)
        try {
            approved = fraudCheck(amount, riskScore);
        } catch (Exception e) {
            // FIX: fail-closed - detalle solo en el log del servidor; se deniega
            System.err.println("fraud check failed: " + e.getMessage());
            // FIX: respuesta generica, sin detalles internos
            return ResponseEntity.status(503).body(Map.of("executed", false, "error", "transfer could not be processed"));
        }
        if (!approved) return ResponseEntity.status(403).body(Map.of("executed", false, "error", "denied by fraud check"));
        if (balances.get(from) < amount) return ResponseEntity.badRequest().body(Map.of("executed", false, "error", "insufficient funds"));
        balances.merge(from, -amount, Long::sum);
        balances.merge(to, amount, Long::sum);
        Map<String, Object> out = new LinkedHashMap<>();
        out.put("executed", true); out.put("from", from); out.put("to", to);
        out.put("amount", amount); out.put("balance", balances.get(from));
        return ResponseEntity.ok(out);
    }
}
