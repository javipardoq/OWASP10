# A01:2025 Control de acceso roto — Flutter/Dart — VULNERABLE

## Qué demuestra
IDOR / referencia directa a objeto sin autorización (CWE-639, CWE-862) en `GET /accounts/{id}`.
Cualquier usuario autenticado lee cualquier cuenta. **A01:2025 Broken Access Control**.

## Cómo correrlo
```bash
./run.sh      # dart pub get + dart test
./verify.sh   # pasa cuando el comportamiento esperado se cumple
```
Requisito: Dart SDK 3.x (o Flutter 3.x).

## El ataque
Un cliente alterado (APK modificado, Frida, proxy) salta el guard de UI (`AccountScreen.canView`) y llama a `AccountRepository.getAccount(callerId: "alice", accountId: 1002)`. Resultado: HTTP 200 con el saldo de bob (1200). Solo se valida que el usuario esté autenticado.

## El código clave
```dart
// VULNERABLE: la capa de datos confia en el guard de la UI
final acc = _accounts[accountId];
if (acc == null) throw NotFoundException(accountId);
return acc;
```

## En una app Flutter real
`AccountRepository` sería un cliente `dio` hacia `GET /accounts/{id}` (token en `flutter_secure_storage`). El guard de UI mejora la UX, pero la autorización la debe re-verificar el backend con el usuario del token.

## Referencias
- OWASP Top 10:2025 — A01 Broken Access Control · Cheat Sheet: Authorization / IDOR Prevention · ASVS 5.0 V8
