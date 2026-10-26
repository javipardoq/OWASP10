# A07:2025 Autenticación — Java (Spring Boot) — VULNERABLE

## Qué demuestra
Fuerza bruta / credential stuffing (CWE-307, tambien CWE-521) en el login. No hay limite de intentos ni bloqueo de cuenta: un atacante puede probar passwords sin restriccion. **A07:2025 Fallas de autenticación**.

## Cómo correrlo
```bash
./run.sh      # ./mvnw spring-boot:run (Maven Wrapper, JDK 17+) -> http://127.0.0.1:8070
./attack.sh   # 20 intentos con passwords incorrectos + 1 correcto, cuenta procesados vs rechazados
./verify.sh   # pasa si todos los intentos se procesan (sin 429)
```
Requisito: JDK 17+ (usa el Maven Wrapper `./mvnw`). Usuario semilla: `alice` / `alice-pass-123`.

## El ataque
Un bucle de 20 passwords incorrectos contra `alice` (y luego el correcto) recibe siempre 401/200: **todos los intentos se procesan** y nunca aparece un 429.

## El código clave
```java
// VULNERABLE: no hay contador de fallos, bloqueo ni rate limit
if (passwordMatches(username, password)) return ResponseEntity.ok(...);
return ResponseEntity.status(401).body(...);
```

## Referencias
- OWASP Top 10:2025 — A07 Authentication Failures · Cheat Sheet: Authentication (Account Lockout) · ASVS 5.0 V6 (Authentication)
