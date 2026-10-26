# A08 — Config — VULNERABLE (sin verificar artefacto)

## Qué demuestra
Se instala y ejecuta un artefacto sin verificar integridad (CWE-494). A08:2025 Fallas de integridad de software o datos.

## Cómo correrlo
```bash
./run.sh      # instala el artefacto legítimo
./attack.sh   # ataque de demo
./verify.sh   # PASS si el artefacto manipulado fue aceptado y ejecutado
```

## El ataque
Un mirror comprometido sirve `tool-tampered.sh`; `install.sh` lo ejecuta sin comprobar nada.

## El código clave
```
# VULNERABLE: sin verificar hash ni firma
cp "$ARTIFACT" install/tool.sh && ./install/tool.sh
```

## Referencias
- OWASP Top 10:2025 — A08 · Cheat Sheet: Software Supply Chain Security · ASVS 5.0 V15
