# A04:2025 Fallos criptográficos — Flutter/Dart — VULNERABLE

## Qué demuestra
Fallo criptográfico (CWE-916 / CWE-328 / CWE-759): los passwords se guardan con **MD5 sin sal**. Corresponde a **A04:2025 Cryptographic Failures**. Si la base de datos se filtra, los passwords se recuperan casi al instante.

## Cómo correrlo
```bash
./run.sh      # dart pub get + dart test (muestra el ataque)
./verify.sh   # automatizado: dart test con el criterio de éxito/fallo
```
Requisito: Dart SDK 3.x (o Flutter 3.x; Flutter incluye Dart). Dart puro, sin dependencias nativas (solo `package:crypto` 3.0.7).

## El ataque
Se registran dos usuarios con el mismo password (`password123`):
- Ambos hashes son **idénticos** (no hay sal): se ve quién comparte password.
- Un mini diccionario "rainbow" (MD5/SHA-1 de passwords comunes) **revierte** el hash y recupera `password123`.

## El código clave
```
# VULNERABLE: hash rápido, roto y sin sal
md5.convert(utf8.encode(password)).toString()
```

## En una app Flutter real
El riesgo móvil típico: guardar un PIN/password (o su hash) en `SharedPreferences`, un archivo o `sqflite`, donde un backup o un dispositivo con root lo exponen. Lo correcto es **no guardar el password en el cliente** (que el backend lo verifique con un KDF) y, si se necesita un secreto local, guardarlo en `flutter_secure_storage` (Keychain/Keystore). Si hay que derivar claves en el dispositivo, usar PBKDF2/Argon2 con sal, como aquí. Una versión con rendimiento nativo puede usar `cryptography`/`pointycastle`.
## Referencias
- OWASP Top 10:2025 — A04 Cryptographic Failures
- OWASP Cheat Sheet: Password Storage
- OWASP ASVS 5.0 — V11 Criptografía / V6 Autenticación
