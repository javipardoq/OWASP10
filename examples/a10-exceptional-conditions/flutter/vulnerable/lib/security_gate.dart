// A10:2025 Manejo incorrecto de condiciones excepcionales - vulnerable (Dart puro).
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

    try {
      final ok = await check();
      return GateResult(granted: ok, reason: ok ? 'verified' : 'verification failed');
    } catch (e) {
      // VULNERABLE: fail-open - si el chequeo (canal nativo caido, timeout, etc.)
      // lanza una excepcion, se concede acceso igualmente
      return GateResult(granted: true, reason: "check error: $e"); // VULNERABLE: filtra detalle interno
    }
  }
}
