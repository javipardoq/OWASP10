# A05:2025 Inyeccion — Flutter/Dart — VULNERABLE

## Qué demuestra
Inyeccion SQL (CWE-89) en la capa de datos local de una app Flutter. En una app real
se usa `sqflite` sobre el SQLite del dispositivo (cache offline); el patrón peligroso es
`database.rawQuery("... '$username' ...")`. Aquí se reproduce con un mini-motor en memoria
para correr **sin dependencias nativas**. Corresponde a **A05:2025 Inyección**.

## Cómo correrlo
```bash
./run.sh      # dart pub get + dart test (muestra el ataque)
./verify.sh   # pasa cuando la inyección tiene éxito (vulnerable confirmado)
```
Requisito: Dart SDK 3.x (o Flutter 3.x; Flutter incluye Dart).

## El ataque
`login("admin' --", "cualquier-cosa")` autentica como `admin` sin su contraseña: el `--`
comenta la verificación del password, igual que en SQLite real.

## El código clave
```dart
// VULNERABLE: se concatena la entrada en el texto de la consulta
final where = "username = '$username' AND password = '$password'";
```

## En una app Flutter real
Reemplazá el mini-motor por `sqflite`. El error equivalente sería:
```dart
db.rawQuery("SELECT * FROM users WHERE username = '$username' AND password = '$password'");
```

## Referencias
- OWASP Top 10:2025 — A05 Injection
- OWASP Mobile Top 10 / MASVS (almacenamiento y consultas locales)
- OWASP Cheat Sheet: SQL Injection Prevention
