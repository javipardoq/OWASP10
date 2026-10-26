// A04:2025 Fallos criptograficos - VERSION CORREGIDA (capa de datos Dart de una app Flutter)
//
// PBKDF2-HMAC-SHA256 en Dart puro (paquete `crypto`), sal aleatoria por password y
// 600000 iteraciones. Sin dependencias nativas.
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

// FIX: factor de trabajo recomendado por OWASP para PBKDF2-HMAC-SHA256
const int pbkdf2Iterations = 600000;

String _hex(List<int> b) => b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();

List<int> _unhex(String s) => [
      for (var i = 0; i < s.length; i += 2) int.parse(s.substring(i, i + 2), radix: 16)
    ];

/// PBKDF2-HMAC-SHA256 (RFC 8018) con un unico bloque de 32 bytes (dkLen = 32).
Uint8List pbkdf2Sha256(List<int> password, List<int> salt, int iterations) {
  final hmac = Hmac(sha256, password);
  var u = hmac.convert([...salt, 0, 0, 0, 1]).bytes;
  final t = Uint8List.fromList(u);
  for (var i = 1; i < iterations; i++) {
    u = hmac.convert(u).bytes;
    for (var j = 0; j < t.length; j++) {
      t[j] ^= u[j];
    }
  }
  return t;
}

class PasswordStore {
  // username -> hash almacenado (lo que un atacante con el dispositivo/backup extrae)
  final Map<String, String> storage = {};
  final Random _rng = Random.secure();

  String hashPassword(String password) {
    // FIX: sal aleatoria unica por password + KDF lento. Mismo password => hash distinto.
    final salt = List<int>.generate(16, (_) => _rng.nextInt(256));
    final dk = pbkdf2Sha256(utf8.encode(password), salt, pbkdf2Iterations);
    return 'pbkdf2_sha256\$$pbkdf2Iterations\$${_hex(salt)}\$${_hex(dk)}';
  }

  String register(String username, String password) {
    final h = hashPassword(password);
    storage[username] = h;
    return h;
  }

  bool login(String username, String password) {
    final stored = storage[username];
    if (stored == null) return false;
    final parts = stored.split(r'$');
    final dk = pbkdf2Sha256(utf8.encode(password), _unhex(parts[2]), int.parse(parts[1]));
    final expected = _unhex(parts[3]);
    // Comparacion en tiempo constante
    var diff = dk.length ^ expected.length;
    for (var i = 0; i < dk.length && i < expected.length; i++) {
      diff |= dk[i] ^ expected[i];
    }
    return diff == 0;
  }
}
