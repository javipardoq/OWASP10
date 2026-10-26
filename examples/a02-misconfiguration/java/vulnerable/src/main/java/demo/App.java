package demo;

import jakarta.servlet.http.HttpServletResponse;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.web.servlet.FilterRegistrationBean;
import org.springframework.context.annotation.Bean;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.io.PrintWriter;
import java.io.StringWriter;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * A02:2025 Security Misconfiguration - version VULNERABLE (Spring Boot).
 * API con /profile?id=N. Un id mal formado provoca un error del servidor.
 */
@SpringBootApplication
@RestController
public class App {

    static final String ALLOWED_ORIGIN = "https://app.itau-demo.example"; // origen unico permitido (demo)
    static final Map<Integer, String> USERS = Map.of(1, "alice", 2, "bob");

    // Pagina de inicio para ver el ejemplo en el navegador (los endpoints son API JSON).
    @GetMapping(value = "/", produces = "text/html;charset=UTF-8")
    public String landingPage(jakarta.servlet.http.HttpServletRequest req) {
        return Landing.page("A02 Configuracion de Seguridad Incorrecta", "VULNERABLE", req.getLocalPort(),
            "GET /profile?id=N devuelve el perfil de un usuario (ids 1 y 2). Un id mal formado provoca un error del servidor.",
            "Con un id no numerico (abc) el servidor lanza una excepcion y esta version responde con el stack trace, clases, rutas y version del framework. Ademas CORS permite cualquier origen.",
            Landing.links(new String[][]{{"Peticion valida: id=1","/profile?id=1"},{"ATAQUE: id=abc (dispara el error)","/profile?id=abc"}}));
    }

    public static void main(String[] args) {
        SpringApplication.run(App.class, args);
    }

    @GetMapping("/profile")
    public ResponseEntity<Map<String, Object>> profile(@RequestParam(defaultValue = "") String id) {
        // Integer.parseInt lanza NumberFormatException con un id no numerico
        int n = Integer.parseInt(id);
        String name = USERS.get(n);
        if (name == null) return ResponseEntity.status(404).body(Map.of("error", "not found"));
        return ResponseEntity.ok(Map.of("id", n, "name", name, "email", name + "@example.com"));
    }

    @Bean
    FilterRegistrationBean<jakarta.servlet.Filter> corsFilter() {
        FilterRegistrationBean<jakarta.servlet.Filter> reg = new FilterRegistrationBean<>((req, res, chain) -> {
            var http = (HttpServletResponse) res;
            var origin = ((jakarta.servlet.http.HttpServletRequest) req).getHeader("Origin");
            // VULNERABLE: cualquier origen puede leer las respuestas
            http.setHeader("Access-Control-Allow-Origin", "*");
            chain.doFilter(req, res);
        });
        reg.setOrder(Integer.MIN_VALUE);
        return reg;
    }

    @RestControllerAdvice
    static class Errors {
        @ExceptionHandler(Exception.class)
        ResponseEntity<Map<String, Object>> onError(Exception e) {
            // VULNERABLE: stack trace, clase, rutas y version del framework al cliente
            StringWriter sw = new StringWriter();
            e.printStackTrace(new PrintWriter(sw));
            Map<String, Object> body = new LinkedHashMap<>();
            body.put("error", e.toString());
            body.put("stackTrace", sw.toString());
            body.put("framework", org.springframework.boot.SpringBootVersion.getVersion());
            body.put("java", System.getProperty("java.version"));
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(body);
        }
    }
}
