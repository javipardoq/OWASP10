// A05:2025 Inyeccion (SQL Injection) - VERSION CORREGIDA (Dart / capa de datos Flutter)
//
// En una app Flutter real esto corresponde a usar consultas parametrizadas de `sqflite`:
//   database.rawQuery('SELECT ... WHERE username = ? AND password = ?', [username, password]);
// Los valores viajan en una lista de argumentos, separados del texto SQL, por lo que
// nunca se interpretan como codigo y la inyeccion deja de funcionar.

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
    // FIX: la consulta tiene marcadores (?) y los valores se pasan aparte. El valor
    // "admin' --" se compara como un username literal, que no existe => no autentica.
    final rows = _query(
      'username = ? AND password = ?',
      [username, password],
    );
    if (rows.isNotEmpty) {
      final u = rows.first;
      return AuthResult(true, u.username, u.balance);
    }
    return const AuthResult(false);
  }

  // Mini-interprete parametrizado: las condiciones se definen con marcadores '?' y los
  // argumentos se comparan por igualdad exacta, sin construir ni reparsear texto SQL.
  List<User> _query(String whereTemplate, List<Object?> args) {
    final conditions = whereTemplate
        .split(RegExp(r'\bAND\b'))
        .map((c) => c.trim())
        .toList();
    var argIndex = 0;
    final predicates = <bool Function(User)>[];
    for (final c in conditions) {
      final m = RegExp(r'^(\w+)\s*=\s*\?$').firstMatch(c);
      if (m == null) {
        throw ArgumentError('solo se permiten condiciones parametrizadas: $c');
      }
      final field = m.group(1)!;
      final value = args[argIndex++];
      predicates.add((u) => _fieldValue(u, field) == value);
    }
    return _seed.where((u) => predicates.every((p) => p(u))).toList();
  }

  Object? _fieldValue(User u, String field) {
    switch (field) {
      case 'username':
        return u.username;
      case 'password':
        return u.password;
      default:
        throw ArgumentError('campo no permitido: $field');
    }
  }
}
