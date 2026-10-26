# A08 — Java — VULNERABLE

## Qué demuestra
Deserialización insegura (CWE-502) en `POST /load-prefs`: `ObjectInputStream.readObject()` sobre bytes del atacante. A08:2025 Fallas de integridad de software o datos.

## Cómo correrlo
```bash
./run.sh      # ./mvnw spring-boot:run en :8080
./attack.sh   # ataque de demo
./verify.sh   # PASS si el código se ejecutó durante la deserialización
```

## El ataque
Envía un flujo serializado de `EvilPrefs`, cuyo `readObject()` escribe `PWNED.marker` y activa un flag. `GET /pwned` devuelve true. En un ataque real sería una cadena de gadgets con RCE.

## El código clave
```
// VULNERABLE: readObject() sobre entrada no confiable
Object obj = new ObjectInputStream(new ByteArrayInputStream(body)).readObject();
```

## Referencias
- OWASP Top 10:2025 — A08 Software or Data Integrity Failures · Cheat Sheet: Deserialization · ASVS 5.0 V1 (deserialización segura)
