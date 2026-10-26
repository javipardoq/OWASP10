# A07:2025 Autenticación — Dart/Flutter — FIXED

## Qué demuestra
La misma guardia de sesión con **límite de 5 intentos de PIN + bloqueo de 5 min**, token
aleatorio (`Random.secure`) con **expiración de 15 min** y borrado del almacén al expirar.
**A07:2025 Fallas de autenticación** (CWE-307, CWE-613).

## Cómo correrlo
```bash
./run.sh      # dart test
./attack.sh   # intenta la fuerza bruta y el reuso de token (ahora bloqueados)
./verify.sh   # pasa si el ataque es bloqueado y el PIN legítimo funciona (tests verdes)
```
Requisito: Dart SDK 3.x (o Flutter). Solo `test: 1.25.15`.

## El ataque
Tras 5 PINs erróneos el guardia se bloquea, incluso para el PIN correcto; la fuerza bruta
completa ya no encuentra nada. Pasado el cooldown, el usuario legítimo vuelve a entrar. El
token caduca y se elimina.

## El código clave
```dart
// FIX: durante el bloqueo no se evalua el PIN (ni el correcto entra)
if (locked != null && now().isBefore(locked)) return null;
// FIX: token aleatorio seguro con expiracion
_tokenExpiry = now().add(tokenTtl);
```

## En una app Flutter real
Guardar el token en `flutter_secure_storage` (Keychain/Keystore), persistir el contador de
intentos de forma segura (sobrevive a reinicios de la app), preferir biometría
(`local_auth`) y validar sesión/lockout también en el servidor (el límite local es solo defensa en profundidad).

## Referencias
- OWASP Top 10:2025 — A07 · MASVS-AUTH · Cheat Sheet: Authentication / Session Management · ASVS 5.0 V6, V7
