# A04:2025 Fallos criptográficos — Node.js (Express) — CORREGIDO

## Qué demuestra
El mismo servicio, pero los passwords se guardan con un **hash de password adecuado**: PBKDF2-HMAC-SHA256 con 600000 iteraciones, con **sal aleatoria por password** y comparación en tiempo constante. Corrige **A04:2025 Cryptographic Failures** (CWE-916).

## Cómo correrlo
```bash
./run.sh      # levanta la API en http://127.0.0.1:8043
./attack.sh   # registra 2 usuarios con el mismo password y ataca los hashes
./verify.sh   # automatizado: arranca, ataca, comprueba y apaga
```
Endpoints: `POST /register` y `POST /login` (form-urlencoded). `/register` devuelve `stored_hash` solo para la demo (simula una filtración de la BD).

## El ataque
El mismo ataque falla:
- Los dos hashes **difieren** (sal única por password).
- El diccionario MD5/SHA-1 **no** revierte nada (el hash incluye sal y factor de trabajo, así que habría que atacar cada hash por separado y lentamente).
- El login legítimo con el password correcto **sigue funcionando**; el incorrecto se rechaza.

## El código clave
```
# FIX: KDF lento + sal aleatoria por password
crypto.pbkdf2(password, crypto.randomBytes(16), 600000, 32, "sha256", ...)
```

## Referencias
- OWASP Top 10:2025 — A04 Cryptographic Failures
- OWASP Cheat Sheet: Password Storage
- OWASP ASVS 5.0 — V11 Criptografía / V6 Autenticación
