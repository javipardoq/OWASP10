# A02:2025 Misconfiguration — Dart/Flutter — VULNERABLE

## Qué demuestra
El cliente HTTP acepta cualquier certificado TLS (MITM posible), permite http:// y registra tokens y cuerpos en el log. Corresponde a **A02:2025** (CWE-295, CWE-532). La política se modela como un objeto de configuración (`HttpClientConfig`) que los
tests inspeccionan; Dart puro, sin red ni dependencias nativas.

## Cómo correrlo
```bash
./run.sh      # ejecuta los tests (demo)
./attack.sh   # ejecuta el ataque como tests
./verify.sh   # automatizado: dart test con el criterio de éxito/fallo
```
Requisito: Dart SDK 3.x (o Flutter).

## El ataque
Un proxy MITM con certificado inválido es aceptado y el token/contraseña quedan en el log del dispositivo.

## El código clave
```dart
// VULNERABLE: se acepta cualquier certificado
if (trustAllCertificates) return true;
```

## En una app Flutter real
Con `dio`/`HttpClient`: no asignar `badCertificateCallback = (_, __, ___) => true`; usar
pinning de certificado/clave pública; `usesCleartextTraffic=false` (Android) y ATS activo (iOS);
no loguear `Authorization` ni cuerpos (desactivar `LogInterceptor` en release); guardar tokens
en `flutter_secure_storage`.

## Referencias
- OWASP Top 10:2025 — A02 Security Misconfiguration
- OWASP Mobile: Certificate Pinning / Transport Layer Security Cheat Sheets
- OWASP ASVS 5.0 — V12 Comunicaciones seguras
