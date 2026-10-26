package demo;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * A06:2025 Diseno Inseguro - VERSION VULNERABLE (Spring Boot).
 *
 * Transferencia entre cuentas. El DISENO no modelo el caso de abuso: nunca se definio
 * que el monto deba ser positivo ni que no se pueda transferir mas que el saldo. No es
 * un bug de implementacion aislado, sino una falla de diseno (falta un requisito de
 * seguridad / regla de negocio). Con un monto NEGATIVO, el atacante "transfiere" -1000
 * de su cuenta a la victima, lo que en realidad le ROBA 1000 a la victima.
 */
@SpringBootApplication
@RestController
public class App {

    // Saldos en memoria (demo). alice=1000, bob=1000.
    private final Map<String, Integer> balances = new ConcurrentHashMap<>(Map.of(
            "alice", 1000,
            "bob", 1000
    ));

    // Pagina de inicio para ver el ejemplo en el navegador (los endpoints son API JSON).
    @GetMapping(value = "/", produces = "text/html;charset=UTF-8")
    public String landingPage(jakarta.servlet.http.HttpServletRequest req) {
        return Landing.page("A06 Diseno Inseguro", "VULNERABLE", req.getLocalPort(),
            "POST /transfer (from, to, amount) mueve dinero entre cuentas; GET /balance/{account} consulta el saldo.",
            "Una transferencia con monto NEGATIVO (-500) invierte el flujo: alice 'transfiere' -500 a bob y en realidad le roba 500. La version vulnerable no valida el diseno del monto; la corregida lo rechaza.",
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
    public Map<String, Object> transfer(@RequestParam String from,
                                        @RequestParam String to,
                                        @RequestParam int amount) {
        // VULNERABLE: no hay validacion de la regla de negocio. Un monto negativo
        // invierte el sentido de la transferencia y permite robar al destinatario.
        balances.merge(from, -amount, Integer::sum);
        balances.merge(to, amount, Integer::sum);
        return Map.of(
                "ok", true,
                "from", from, "fromBalance", balances.get(from),
                "to", to, "toBalance", balances.get(to)
        );
    }
}
