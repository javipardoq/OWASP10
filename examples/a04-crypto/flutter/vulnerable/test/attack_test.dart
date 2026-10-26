// Ataque automatizado contra la version VULNERABLE.
// Los tests PASAN cuando la debilidad se demuestra (confirma la vulnerabilidad).
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:test/test.dart';
import 'package:a04_crypto_vulnerable/password_store.dart';

// Mini diccionario "rainbow": MD5/SHA-1 de passwords comunes.
const words = ['123456', 'qwerty', 'letmein', 'admin', 'welcome', 'password', 'password123', 'iloveyou', 'abc123'];

String? crack(String hash) {
  for (final w in words) {
    if (md5.convert(utf8.encode(w)).toString() == hash ||
        sha1.convert(utf8.encode(w)).toString() == hash) {
      return w;
    }
  }
  return null;
}

void main() {
  final store = PasswordStore();

  test('mismo password => mismo hash (sin sal)', () {
    final a = store.register('victima-a', 'password123');
    final b = store.register('victima-b', 'password123');
    print('hash A: $a\nhash B: $b');
    expect(a, equals(b));
  });

  test('el diccionario revierte el hash almacenado', () {
    final stored = store.storage['victima-a']!;
    expect(crack(stored), 'password123');
  });

  test('el login legitimo funciona', () {
    expect(store.login('victima-a', 'password123'), isTrue);
    expect(store.login('victima-a', 'otro'), isFalse);
  });
}
