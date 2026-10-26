# A04:2025 Fallos criptográficos — Java (Spring Boot) — VULNERABLE

## Qué demuestra
Fallo criptográfico (CWE-916 / CWE-328 / CWE-759): los passwords se guardan con **MD5 sin sal**. Corresponde a **A04:2025 Cryptographic Failures**. Si la base de datos se filtra, los passwords se recuperan casi al instante.

## Cómo correrlo
```bash
./run.sh      # levanta la API en http://127.0.0.1:8040
./attack.sh   # registra 2 usuarios con el mismo password y ataca los hashes
./verify.sh   # automatizado: arranca, ataca, comprueba y apaga
```
Endpoints: `POST /register` y `POST /login` (form-urlencoded). `/register` devuelve `stored_hash` solo para la demo (simula una filtración de la BD).

## El ataque
Se registran dos usuarios con el mismo password (`password123`):
- Ambos hashes son **idénticos** (no hay sal): se ve quién comparte password.
- Un mini diccionario "rainbow" (MD5/SHA-1 de passwords comunes) **revierte** el hash y recupera `password123`.

## El código clave
```
# VULNERABLE: hash rápido, roto y sin sal
String hash = MessageDigest.getInstance("MD5").digest(...)
```

## Referencias
- OWASP Top 10:2025 — A04 Cryptographic Failures
- OWASP Cheat Sheet: Password Storage
- OWASP ASVS 5.0 — V11 Criptografía / V6 Autenticación
