// Mismo ataque contra la version CORREGIDA: debe ser bloqueado.
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:test/test.dart';
import 'package:a04_crypto_fixed/password_store.dart';

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

  test('PBKDF2-HMAC-SHA256 coincide con el vector de prueba RFC 7914 (c=1)', () {
    final dk = pbkdf2Sha256(utf8.encode('passwd'), utf8.encode('salt'), 1);
    final hex = dk.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
    expect(hex, '55ac046e56e3089fec1691c22544b605f94185216dde0465e68b9d57c20dacbc');
  });

  test('mismo password => hashes distintos (con sal)', () {
    final a = store.register('victima-a', 'password123');
    final b = store.register('victima-b', 'password123');
    print('hash A: $a\nhash B: $b');
    expect(a, isNot(equals(b)));
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('el diccionario NO revierte el hash', () {
    expect(crack(store.storage['victima-a']!), isNull);
  });

  test('el login legitimo sigue funcionando', () {
    expect(store.login('victima-a', 'password123'), isTrue);
    expect(store.login('victima-a', 'otro'), isFalse);
  }, timeout: const Timeout(Duration(minutes: 2)));
}
