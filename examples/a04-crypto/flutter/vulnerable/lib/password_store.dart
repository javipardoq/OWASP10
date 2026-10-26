// A04:2025 Fallos criptograficos - VERSION VULNERABLE (capa de datos Dart de una app Flutter)
//
// Guarda el "verificador" del password/PIN en el almacenamiento local del dispositivo
// (en una app real: SharedPreferences / archivo / sqflite). Aqui es un Map en memoria.
import 'dart:convert';
import 'package:crypto/crypto.dart';

class PasswordStore {
  // username -> hash almacenado (lo que un atacante con el dispositivo/backup extrae)
  final Map<String, String> storage = {};

  // VULNERABLE: MD5 es rapido, esta roto y NO lleva sal. Mismo password => mismo hash,
  // y se revierte con diccionarios / rainbow tables en milisegundos.
  String hashPassword(String password) => md5.convert(utf8.encode(password)).toString();

  String register(String username, String password) {
    final h = hashPassword(password);
    storage[username] = h;
    return h;
  }

  bool login(String username, String password) {
    final stored = storage[username];
    return stored != null && stored == hashPassword(password);
  }
}
