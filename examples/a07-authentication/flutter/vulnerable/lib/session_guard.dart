import 'dart:convert';

/// A07:2025 Fallas de autenticacion - VERSION VULNERABLE.
///
/// Guardia de sesion de una app movil: desbloqueo con PIN local de 4 digitos y
/// token de sesion persistido. Modela la capa de logica de una app Flutter.

/// Almacen clave/valor en memoria. Simula SharedPreferences (texto plano).
class PlainStore {
  final Map<String, String> data = {};
}

class SessionGuard {
  final PlainStore store;
  final DateTime Function() now; // reloj inyectable para testear expiracion
  final String _pin; // PIN real del usuario (demo)

  SessionGuard({required String pin, required this.store, DateTime Function()? now})
      : _pin = pin,
        now = now ?? DateTime.now;

  /// Intenta desbloquear con el PIN. Devuelve el token o null.
  String? unlock(String pin) {
    // VULNERABLE: sin limite de intentos locales; los 10.000 PINs se pueden probar.
    if (pin != _pin) return null;
    // VULNERABLE: token predecible (usuario + hora) guardado en texto plano
    // (SharedPreferences) y sin fecha de expiracion.
    final token = base64.encode(utf8.encode('alice:${now().millisecondsSinceEpoch}'));
    store.data['session_token'] = token;
    return token;
  }

  /// Valida un token de sesion presentado.
  bool isSessionValid(String token) {
    // VULNERABLE: el token nunca expira, vale mientras exista.
    return store.data['session_token'] == token;
  }
}
