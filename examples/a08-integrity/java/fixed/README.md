# A08 — Java — FIXED

## Qué demuestra
Mismo servicio; sin serialización nativa para entrada no confiable. A08:2025 Fallas de integridad de software o datos.

## Cómo correrlo
```bash
./run.sh      # ./mvnw spring-boot:run en :8081
./attack.sh   # ataque de demo
./verify.sh   # PASS si no hay efecto lateral Y la carga JSON legítima funciona
```

## El ataque
El mismo payload binario se rechaza (415, no es JSON). Un JSON inválido da 400. No existe ningún camino que deserialice clases arbitrarias.

## El código clave
```
// FIX: JSON hacia un DTO fijo (record) + lista blanca de valores
@PostMapping(value="/load-prefs", consumes="application/json")
public ... loadPrefs(@RequestBody Prefs prefs)
```

## Referencias
- OWASP Top 10:2025 — A08 · Cheat Sheet: Deserialization · ASVS 5.0 V1
