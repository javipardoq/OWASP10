import 'dart:math';

/// A07:2025 Fallas de autenticacion - VERSION CORREGIDA.
///
/// Misma guardia de sesion, con limite de intentos de PIN, bloqueo temporal y
/// token aleatorio con expiracion.

/// Almacen clave/valor en memoria. En una app real: flutter_secure_storage
/// (Keychain / Android Keystore) en lugar de SharedPreferences.
class SecureStore {
  final Map<String, String> data = {};
}

class SessionGuard {
  static const maxAttempts = 5; // FIX: umbral de intentos fallidos
  static const lockout = Duration(minutes: 5); // FIX: cooldown tras superar el umbral
  static const tokenTtl = Duration(minutes: 15); // FIX: vida maxima del token

  final SecureStore store;
  final DateTime Function() now; // reloj inyectable para testear expiracion
  final String _pin;
  int _failures = 0;
  DateTime? _lockedUntil;
  DateTime? _tokenExpiry;

  SessionGuard({required String pin, required this.store, DateTime Function()? now})
      : _pin = pin,
        now = now ?? DateTime.now;

  /// Intenta desbloquear con el PIN. Devuelve el token o null.
  String? unlock(String pin) {
    // FIX: durante el bloqueo no se evalua el PIN (ni el correcto entra).
    final locked = _lockedUntil;
    if (locked != null && now().isBefore(locked)) return null;
    if (pin != _pin) {
      _failures++;
      if (_failures >= maxAttempts) {
        _failures = 0;
        _lockedUntil = now().add(lockout);
      }
      return null;
    }
    _failures = 0;
    // FIX: token aleatorio criptograficamente seguro con expiracion.
    final rnd = Random.secure();
    final token = List.generate(32, (_) => rnd.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
    store.data['session_token'] = token;
    _tokenExpiry = now().add(tokenTtl);
    return token;
  }

  /// Valida un token de sesion presentado.
  bool isSessionValid(String token) {
    final exp = _tokenExpiry;
    // FIX: un token expirado se rechaza y se borra del almacen.
    if (exp == null || !now().isBefore(exp)) {
      store.data.remove('session_token');
      return false;
    }
    return store.data['session_token'] == token;
  }
}
