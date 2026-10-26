# A05:2025 Inyeccion — Flutter/Dart — CORREGIDO

## Qué demuestra
La misma capa de datos, pero con **consulta parametrizada**: los valores van en una lista
de argumentos, separados del texto. En una app Flutter real esto es
`db.rawQuery('... WHERE username = ? AND password = ?', [username, password])`.
Corresponde a **A05:2025 Inyección**.

## Cómo correrlo
```bash
./run.sh      # dart pub get + dart test
./verify.sh   # pasa cuando la inyección se bloquea y el login legítimo funciona
```
Requisito: Dart SDK 3.x (o Flutter 3.x).

## El ataque (ahora bloqueado)
`login("admin' --", "x")` ya no autentica: `admin' --` se compara como username literal,
que no existe.

## El código clave
```dart
// FIX: marcadores ? y valores pasados aparte; nunca se interpolan en el SQL
_query('username = ? AND password = ?', [username, password]);
```

## En una app Flutter real
```dart
db.rawQuery('SELECT * FROM users WHERE username = ? AND password = ?', [username, password]);
```

## Referencias
- OWASP Top 10:2025 — A05 Injection
- OWASP MASVS — almacenamiento local seguro
- OWASP Cheat Sheet: SQL Injection Prevention
