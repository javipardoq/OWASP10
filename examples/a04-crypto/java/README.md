# A04:2025 — Java (Spring Boot)

Almacenamiento de passwords: `vulnerable/` usa **MD5 sin sal**; `fixed/` usa BCrypt (cost 12) con **sal aleatoria por password**. La única diferencia es la función de hash.

```diff
-String hash = MessageDigest.getInstance("MD5").digest(...)
+new BCryptPasswordEncoder(12).encode(password)   // sal aleatoria + cost 12
```

Ver `diff -r vulnerable fixed` para el cambio completo.
