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
 * A02:2025 Security Misconfiguration - version FIXED (Spring Boot).
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
        return Landing.page("A02 Configuracion de Seguridad Incorrecta", "CORREGIDO", req.getLocalPort(),
            "GET /profile?id=N devuelve el perfil de un usuario (ids 1 y 2). Un id mal formado provoca un error del servidor.",
            "Con un id no numerico (abc) el servidor lanza una excepcion, pero esta version solo devuelve un mensaje generico (el detalle queda en el log) y limita CORS a un origen permitido.",
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
            // FIX: solo el origen de la allow-list; el resto no recibe cabecera CORS
            http.setHeader("Vary", "Origin");
            if (ALLOWED_ORIGIN.equals(origin)) http.setHeader("Access-Control-Allow-Origin", ALLOWED_ORIGIN);
            http.setHeader("X-Content-Type-Options", "nosniff");
            chain.doFilter(req, res);
        });
        reg.setOrder(Integer.MIN_VALUE);
        return reg;
    }

    @RestControllerAdvice
    static class Errors {
        @ExceptionHandler(Exception.class)
        ResponseEntity<Map<String, Object>> onError(Exception e) {
            // FIX: el detalle queda en el log del servidor; el cliente recibe un mensaje generico
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of("error", "internal server error"));
        }
    }
}
