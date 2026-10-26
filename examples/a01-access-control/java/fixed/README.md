# A01:2025 Control de acceso roto — Java (Spring Boot) — FIXED

## Qué demuestra
IDOR / referencia directa a objeto sin autorización (CWE-639, CWE-862) en `GET /accounts/{id}`.
El servidor verifica la propiedad y responde 403 si no es el dueño. **A01:2025 Broken Access Control**.

## Cómo correrlo
```bash
./run.sh      # http://127.0.0.1:8011
./attack.sh   # alice pide /accounts/1002 (cuenta de bob)
./verify.sh   # automatizado
```
Requisito: JDK 17+ (usa el Maven Wrapper ./mvnw).

## El ataque
`curl -H "X-User: alice" /accounts/1002`. Resultado: HTTP 403 (forbidden); la cuenta propia (1001) sigue accesible.

## El código clave
```java
// FIX: el recurso debe pertenecer al usuario autenticado
if (!user.equals(row.get("OWNER"))) { return ResponseEntity.status(403).body(Map.of("error", "forbidden")); }
```

## Referencias
- OWASP Top 10:2025 — A01 Broken Access Control · Cheat Sheet: Authorization / IDOR Prevention · ASVS 5.0 V8
