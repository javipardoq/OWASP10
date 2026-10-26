# A02:2025 Misconfiguration — Dart/Flutter — FIXED

## Qué demuestra
El cliente valida la cadena TLS, solo acepta hosts permitidos, bloquea http:// y no registra datos sensibles (CWE-295, CWE-532). La política se modela como un objeto de configuración (`HttpClientConfig`) que los
tests inspeccionan; Dart puro, sin red ni dependencias nativas.

## Cómo correrlo
```bash
./run.sh      # ejecuta los tests (demo)
./attack.sh   # ejecuta el ataque como tests
./verify.sh   # automatizado: dart test con el criterio de éxito/fallo
```
Requisito: Dart SDK 3.x (o Flutter).

## El ataque
El mismo MITM es rechazado, el log no contiene token ni cuerpo, y el uso legítimo (host propio sobre https) sigue funcionando.

## El código clave
```dart
// FIX: cadena valida Y host permitido
return chainValidByPlatform && pinnedHosts.contains(host);
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
