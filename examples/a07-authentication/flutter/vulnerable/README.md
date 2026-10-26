# A07:2025 Autenticación — Dart/Flutter — VULNERABLE

## Qué demuestra
Guardia de sesión móvil (PIN local de 4 dígitos + token de sesión) sin límite de intentos,
con token predecible, en texto plano y que **nunca expira** (CWE-307, CWE-613, CWE-922).
**A07:2025 Fallas de autenticación**.

## Cómo correrlo
```bash
./run.sh      # dart test: demo legítima + ataque
./attack.sh   # fuerza bruta de los 10.000 PINs y reuso de token viejo
./verify.sh   # pasa si el ataque tiene éxito (tests verdes)
```
Requisito: Dart SDK 3.x (o Flutter). Paquete Dart puro, solo `test: 1.25.15`.

## El ataque
Un atacante con el dispositivo (o malware) prueba los PINs `0000..9999` sin límite y
encuentra el correcto; además un token robado sigue válido un año después.

## El código clave
```dart
// VULNERABLE: sin limite de intentos locales
if (pin != _pin) return null;
// VULNERABLE: token predecible, en texto plano y sin expiracion
store.data['session_token'] = base64.encode(utf8.encode('alice:${now().millisecondsSinceEpoch}'));
```

## En una app Flutter real
`SessionGuard` es la capa de lógica detrás de la pantalla de PIN/biometría. `PlainStore`
representa `SharedPreferences` (texto plano, extraíble en dispositivos rooteados).

## Referencias
- OWASP Top 10:2025 — A07 · MASVS-AUTH · Cheat Sheet: Authentication / Session Management · ASVS 5.0 V6, V7
