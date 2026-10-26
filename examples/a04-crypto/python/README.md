# A04:2025 — Python (stdlib)

Almacenamiento de passwords: `vulnerable/` usa **MD5 sin sal**; `fixed/` usa PBKDF2-HMAC-SHA256 (600000 iteraciones) con **sal aleatoria por password**. La única diferencia es la función de hash.

```diff
-hashlib.md5(password.encode()).hexdigest()
+hashlib.pbkdf2_hmac("sha256", password.encode(), os.urandom(16), 600_000)
```

Ver `diff -r vulnerable fixed` para el cambio completo.
