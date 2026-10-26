# A05:2025 Inyeccion — Java (Spring Boot) — VULNERABLE

## Qué demuestra
Inyeccion SQL (CWE-89) en el login. La consulta se arma concatenando la entrada del
usuario con `JdbcTemplate.queryForList(sql)`. **A05:2025 Inyección**.

## Cómo correrlo
```bash
./run.sh      # ./mvnw spring-boot:run -> http://127.0.0.1:8050
./attack.sh   # inyección de bypass de autenticación
./verify.sh   # pasa si el ataque funciona
```
Requisito: JDK 17+ (usa el Maven Wrapper `./mvnw`, no hace falta instalar Maven).

## El ataque
`username = admin' --` comenta la verificación de password y autentica como admin.

## El código clave
```java
// VULNERABLE: concatenación directa en el SQL
String sql = "SELECT username, balance FROM users WHERE username = '" + username + "' AND password = '" + password + "'";
jdbc.queryForList(sql);
```

## Referencias
- OWASP Top 10:2025 — A05 Injection · Cheat Sheet: SQL Injection Prevention · ASVS 5.0 V5
