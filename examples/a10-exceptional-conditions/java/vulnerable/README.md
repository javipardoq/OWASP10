# A10:2025 Excepciones — Java (Spring Boot) — VULNERABLE

## Qué demuestra
Fail-open (CWE-636 / CWE-209). Si el chequeo antifraude lanza una excepcion, el codigo la captura y **sigue con la transferencia**, ademas de devolver el detalle interno al cliente. **A10:2025 Manejo incorrecto de condiciones excepcionales**.

## Cómo correrlo
```bash
./run.sh      # levanta http://127.0.0.1:8100
./attack.sh   # POST /transfer forzando el error del chequeo
./verify.sh   # pasa si el ataque funciona (transferencia ejecutada + detalle filtrado)
```

## El ataque
El atacante envia `amount=50000` (normalmente denegado) con `riskScore=abc`, lo que hace fallar el parser del servicio antifraude. El catch asume aprobado: la transferencia se ejecuta y la respuesta incluye `checkError` con host interno y clase.

## El código clave
```
catch -> approved = true;   // VULNERABLE: fail-open
checkError = e.message;   // VULNERABLE: filtra detalle interno
```

## Referencias
- OWASP Top 10:2025 — A10 Mishandling of Exceptional Conditions · Cheat Sheet: Error Handling · ASVS 5.0 V16.5
