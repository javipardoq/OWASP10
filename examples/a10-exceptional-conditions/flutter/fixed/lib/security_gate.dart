// A10:2025 Manejo incorrecto de condiciones excepcionales - fixed (Dart puro).
// Puerta de seguridad local de una app movil: antes de mostrar la pantalla de
// transferencias se ejecuta un chequeo (biometria / integridad del dispositivo).
// En Flutter real el chequeo es un MethodChannel (local_auth, Play Integrity...).

typedef DeviceCheck = Future<bool> Function();

class GateResult {
  final bool granted;
  final String reason;
  const GateResult({required this.granted, required this.reason});
}

class SecurityGate {
  final DeviceCheck check;
  SecurityGate(this.check);

  /// Devuelve si se concede acceso a la funcion sensible.
  Future<GateResult> unlock() async {
    // FIX: el resultado por defecto es DENEGADO (deny by default)
    try {
      final ok = await check();
      return GateResult(granted: ok, reason: ok ? 'verified' : 'verification failed');
    } catch (_) {
      // FIX: fail-closed - ante cualquier error del chequeo se deniega el acceso
      // FIX: razon generica, sin detalles internos (el detalle iria a un log local seguro)
      return const GateResult(granted: false, reason: "verification unavailable");
    }
  }
}
