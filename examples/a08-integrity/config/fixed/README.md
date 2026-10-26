# A08 — Config — FIXED (SHA-256 fijado)

## Qué demuestra
Se verifica el SHA-256 contra un hash fijado en `PINNED.sha256` antes de usar; fail-closed. En producción además firma (cosign/GPG/minisign) con la clave pública fijada. A08:2025 Fallas de integridad de software o datos.

## Cómo correrlo
```bash
./run.sh      # instala el artefacto legítimo
./attack.sh   # ataque de demo
./verify.sh   # PASS si el manipulado es rechazado Y el legítimo es aceptado
```

## El ataque
El artefacto manipulado tiene otro hash: `install.sh` aborta con RECHAZADO y no ejecuta nada.

## El código clave
```
# FIX: comparar con el hash fijado y rechazar si difiere
[ "$ACTUAL" != "$EXPECTED" ] && exit 1
```

## Referencias
- OWASP Top 10:2025 — A08 · Cheat Sheet: Software Supply Chain Security · ASVS 5.0 V15
