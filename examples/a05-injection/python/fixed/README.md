# A05:2025 Inyeccion — Python — CORREGIDO

## Qué demuestra
La misma API de login, pero con **consultas parametrizadas**. La entrada del usuario
viaja como parámetro, separada del texto SQL, así que la inyección deja de funcionar.
Corresponde a **A05:2025 Inyección**.

## Cómo correrlo
```bash
./run.sh      # levanta la API en http://127.0.0.1:8055
./attack.sh   # el mismo ataque; ahora falla
./verify.sh   # comprueba que la inyección se bloquea y el login válido sigue andando
```
Requisito: Python 3.11+ (solo stdlib).

## El ataque (ahora bloqueado)
Enviar `admin' --` como usuario ya no autentica: el driver trata ese texto como un
nombre de usuario literal, que no existe, y devuelve `authenticated: false`.

## El código clave
```python
# FIX: consulta parametrizada; los '?' son marcadores, el valor no se interpreta como SQL
query = "SELECT username, balance FROM users WHERE username = ? AND password = ?"
db.execute(query, (username, password))
```

## Referencias
- OWASP Top 10:2025 — A05 Injection
- OWASP Cheat Sheet: SQL Injection Prevention (usar siempre consultas parametrizadas)
- OWASP ASVS 5.0 — V5 Validación, Sanitización y Codificación
