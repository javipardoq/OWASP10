# A10:2025 Excepciones — Java (Spring Boot) — FIXED

## Qué demuestra
Fail-closed. Ante cualquier excepcion en el chequeo antifraude se **deniega** la transferencia (503) con un mensaje generico; el detalle solo va al log del servidor. **A10:2025 Manejo incorrecto de condiciones excepcionales** (CWE-636 / CWE-209).

## Cómo correrlo
```bash
./run.sh      # levanta http://127.0.0.1:8101
./attack.sh   # POST /transfer forzando el error del chequeo
./verify.sh   # pasa si el ataque es bloqueado, el error es generico y el caso legitimo funciona
```

## El ataque
El mismo ataque (`amount=50000`, `riskScore=abc`) ahora devuelve 503 `transfer could not be processed` y no mueve fondos. Una transferencia legitima (100, riskScore=10) sigue funcionando.

## El código clave
```
approved = false;        // FIX: deny by default
catch -> return 503 generico  // FIX: fail-closed, sin detalles internos
```

## Referencias
- OWASP Top 10:2025 — A10 Mishandling of Exceptional Conditions · Cheat Sheet: Error Handling · ASVS 5.0 V16.5
