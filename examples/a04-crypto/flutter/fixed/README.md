# A04:2025 Fallos criptográficos — Flutter/Dart — CORREGIDO

## Qué demuestra
El mismo servicio, pero los passwords se guardan con un **hash de password adecuado**: PBKDF2-HMAC-SHA256 con 600000 iteraciones, con **sal aleatoria por password** y comparación en tiempo constante. Corrige **A04:2025 Cryptographic Failures** (CWE-916).

## Cómo correrlo
```bash
./run.sh      # dart pub get + dart test (muestra el ataque)
./verify.sh   # automatizado: dart test con el criterio de éxito/fallo
```
Requisito: Dart SDK 3.x (o Flutter 3.x; Flutter incluye Dart). Dart puro, sin dependencias nativas (solo `package:crypto` 3.0.7).

## El ataque
El mismo ataque falla:
- Los dos hashes **difieren** (sal única por password).
- El diccionario MD5/SHA-1 **no** revierte nada (el hash incluye sal y factor de trabajo, así que habría que atacar cada hash por separado y lentamente).
- El login legítimo con el password correcto **sigue funcionando**; el incorrecto se rechaza.

## El código clave
```
# FIX: KDF lento + sal aleatoria por password
pbkdf2Sha256(utf8.encode(password), randomSalt16, 600000)   // HMAC-SHA256 con package:crypto
```

## En una app Flutter real
El riesgo móvil típico: guardar un PIN/password (o su hash) en `SharedPreferences`, un archivo o `sqflite`, donde un backup o un dispositivo con root lo exponen. Lo correcto es **no guardar el password en el cliente** (que el backend lo verifique con un KDF) y, si se necesita un secreto local, guardarlo en `flutter_secure_storage` (Keychain/Keystore). Si hay que derivar claves en el dispositivo, usar PBKDF2/Argon2 con sal, como aquí. Una versión con rendimiento nativo puede usar `cryptography`/`pointycastle`.
## Referencias
- OWASP Top 10:2025 — A04 Cryptographic Failures
- OWASP Cheat Sheet: Password Storage
- OWASP ASVS 5.0 — V11 Criptografía / V6 Autenticación
