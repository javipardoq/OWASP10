// A05:2025 Inyeccion (SQL Injection) - VERSION VULNERABLE (Dart / capa de datos Flutter)
//
// En una app Flutter real esta clase envolveria `sqflite` (SQLite local del dispositivo),
// que se usa como cache offline. El patron peligroso es el mismo: construir la consulta
// concatenando la entrada del usuario (p. ej. `database.rawQuery("... '$username' ...")`).
//
// Para que el ejemplo corra en cualquier maquina SIN dependencias nativas, aqui se
// reemplaza SQLite por un mini-motor en memoria que interpreta un WHERE de la misma forma
// (interpolando el texto). La leccion de seguridad es identica.

class User {
  final String username;
  final String password;
  final int balance;
  const User(this.username, this.password, this.balance);
}

const _seed = [
  User('alice', 'alice-pass-123', 50000),
  User('bob', 'bob-pass-456', 1200),
  User('admin', 'DEMO-ONLY-s3cr3t', 9999999),
];

class AuthResult {
  final bool authenticated;
  final String? username;
  final int? balance;
  const AuthResult(this.authenticated, [this.username, this.balance]);
}

class AuthRepository {
  AuthResult login(String username, String password) {
    // VULNERABLE: se arma el "WHERE" concatenando la entrada del usuario, igual que
    // database.rawQuery("SELECT ... WHERE username = '$username' AND password = '$password'").
    // Con  username = admin' --  el atacante comenta la verificacion de password.
    final where =
        "username = '$username' AND password = '$password'";
    final rows = _query(where);
    if (rows.isNotEmpty) {
      final u = rows.first;
      return AuthResult(true, u.username, u.balance);
    }
    return const AuthResult(false);
  }

  // Mini-interprete que emula como SQLite evaluaria el texto del WHERE interpolado,
  // incluyendo el comentario `--` que trunca el resto de la condicion.
  List<User> _query(String where) {
    final commentIdx = where.indexOf('--');
    final effective = commentIdx >= 0 ? where.substring(0, commentIdx) : where;
    final conditions = effective
        .split(RegExp(r'\bAND\b'))
        .map((c) => c.trim())
        .where((c) => c.isNotEmpty)
        .toList();
    return _seed.where((u) => conditions.every((c) => _matches(u, c))).toList();
  }

  bool _matches(User u, String condition) {
    final m = RegExp(r"^(\w+)\s*=\s*'(.*)'$").firstMatch(condition);
    if (m == null) {
      // Una condicion sin comillas de cierre (resto de la inyeccion) se ignora,
      // igual que tras el `--`.
      return true;
    }
    final field = m.group(1);
    final value = m.group(2);
    switch (field) {
      case 'username':
        return u.username == value;
      case 'password':
        return u.password == value;
      default:
        return false;
    }
  }
}
