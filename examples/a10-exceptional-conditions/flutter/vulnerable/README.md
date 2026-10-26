# A10:2025 Excepciones — Dart/Flutter — VULNERABLE

## Qué demuestra
Fail-open en una puerta de seguridad local (biometria/integridad). Si el chequeo lanza una excepcion, se concede acceso y se filtra el detalle. **A10:2025** (CWE-636 / CWE-209). Paquete Dart puro.

## Cómo correrlo
```bash
./run.sh      # corre los tests (demo)
./attack.sh   # idem
./verify.sh   # dart test; PASS si el comportamiento es el esperado
```

## El ataque
Un atacante (hook Frida, servicio de integridad bloqueado, timeout del canal nativo) hace que el chequeo lance una excepcion; el test lo simula con un `DeviceCheck` que lanza.

## El código clave
```dart
catch (e) { return GateResult(granted: true, ...) }  // VULNERABLE
```
En una app Flutter real el `DeviceCheck` envuelve `local_auth` / un `MethodChannel` (Play Integrity, App Attest) y `SecurityGate.unlock()` se llama antes de navegar a la pantalla sensible.

## Referencias
- OWASP Top 10:2025 — A10 · MASVS-RESILIENCE / Cheat Sheet: Error Handling · ASVS 5.0 V16.5
