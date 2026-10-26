# A04:2025 — Flutter/Dart

Almacenamiento de passwords: `vulnerable/` usa **MD5 sin sal**; `fixed/` usa PBKDF2-HMAC-SHA256 (600000 iteraciones) con **sal aleatoria por password**. La única diferencia es la función de hash.

```diff
-md5.convert(utf8.encode(password)).toString()
+pbkdf2Sha256(utf8.encode(password), randomSalt16, 600000)   // HMAC-SHA256 con package:crypto
```

Ver `diff -r vulnerable fixed` para el cambio completo.
