# A05:2025 Inyeccion — Java (Spring Boot) — CORREGIDO

## Qué demuestra
Login con **consulta parametrizada** vía `JdbcTemplate.queryForList(sql, args...)`. La
entrada viaja como parámetro ligado; la inyección deja de funcionar. **A05:2025**.

## Cómo correrlo
```bash
./run.sh      # http://127.0.0.1:8051
./attack.sh   # el mismo ataque, ahora falla
./verify.sh   # pasa si la inyección se bloquea y el login legítimo funciona
```
Requisito: JDK 17+.

## El código clave
```java
// FIX: parámetros ligados; el valor nunca se interpreta como SQL
String sql = "SELECT username, balance FROM users WHERE username = ? AND password = ?";
jdbc.queryForList(sql, username, password);
```

## Referencias
- OWASP Top 10:2025 — A05 Injection · Cheat Sheet: SQL Injection Prevention · ASVS 5.0 V5
