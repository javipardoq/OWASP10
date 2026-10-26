// Ataque automatizado contra la version VULNERABLE.
import 'package:test/test.dart';
import 'package:a10_exceptional_vulnerable/security_gate.dart';

void main() {
  Future<bool> brokenCheck() async =>
      throw StateError('PlatformException(integrity_service_unavailable, com.bank.app/IntegrityChannel:42)');
  Future<bool> goodCheck() async => true;
  Future<bool> rootedCheck() async => false;

  test('si el chequeo lanza excepcion, la puerta falla ABIERTA (acceso concedido)', () async {
    final r = await SecurityGate(brokenCheck).unlock();
    expect(r.granted, isTrue, reason: 'fail-open: el atacante fuerza el error y entra');
    expect(r.reason, contains('integrity_service_unavailable'), reason: 'se filtra detalle interno');
  });

  test('un dispositivo que no pasa el chequeo se deniega normalmente', () async {
    expect((await SecurityGate(rootedCheck).unlock()).granted, isFalse);
  });
}
