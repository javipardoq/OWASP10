# A04:2025 — Node.js (Express)

Almacenamiento de passwords: `vulnerable/` usa **MD5 sin sal**; `fixed/` usa PBKDF2-HMAC-SHA256 (600000 iteraciones) con **sal aleatoria por password**. La única diferencia es la función de hash.

```diff
-crypto.createHash("md5").update(password).digest("hex")
+crypto.pbkdf2(password, crypto.randomBytes(16), 600000, 32, "sha256", ...)
```

Ver `diff -r vulnerable fixed` para el cambio completo.
