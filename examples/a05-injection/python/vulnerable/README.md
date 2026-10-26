# A05:2025 Inyeccion — Python — VULNERABLE

## Qué demuestra
Inyeccion SQL (CWE-89) en el login de un banco de demo. La consulta se construye
concatenando la entrada del usuario, así que un atacante puede saltarse la
autenticación. Corresponde a **A05:2025 Inyección**.

## Cómo correrlo
```bash
./run.sh      # levanta la API en http://127.0.0.1:8054
./attack.sh   # ejecuta el ataque de inyección
./verify.sh   # automatizado: arranca, ataca y comprueba que la inyección funciona
```
Requisito: Python 3.11+ (solo stdlib).

## El ataque
El atacante envía como usuario `admin' --`. La consulta resultante queda:
```sql
SELECT username, balance FROM users WHERE username = 'admin' --' AND password = '...'
```
El `--` comenta el resto, así que la verificación de contraseña desaparece y el login
devuelve la cuenta de `admin` sin conocer su clave.

## El código clave
```python
# VULNERABLE: la entrada se concatena directamente en el SQL
query = f"SELECT username, balance FROM users WHERE username = '{username}' AND password = '{password}'"
```

## Referencias
- OWASP Top 10:2025 — A05 Injection
- OWASP Cheat Sheet: SQL Injection Prevention
- OWASP ASVS 5.0 — V5 Validación, Sanitización y Codificación
