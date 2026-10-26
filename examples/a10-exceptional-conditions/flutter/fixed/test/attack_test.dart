// Ataque automatizado contra la version FIXED.
import 'package:test/test.dart';
import 'package:a10_exceptional_fixed/security_gate.dart';

void main() {
  Future<bool> brokenCheck() async =>
      throw StateError('PlatformException(integrity_service_unavailable, com.bank.app/IntegrityChannel:42)');
  Future<bool> goodCheck() async => true;
  Future<bool> rootedCheck() async => false;

  test('si el chequeo lanza excepcion, la puerta falla CERRADA (acceso denegado)', () async {
    final r = await SecurityGate(brokenCheck).unlock();
    expect(r.granted, isFalse);
    expect(r.reason, isNot(contains('integrity')));
    expect(r.reason, isNot(contains('PlatformException')));
  });

  test('un dispositivo legitimo que pasa el chequeo sigue teniendo acceso', () async {
    expect((await SecurityGate(goodCheck).unlock()).granted, isTrue);
  });

  test('un dispositivo que no pasa el chequeo se deniega', () async {
    expect((await SecurityGate(rootedCheck).unlock()).granted, isFalse);
  });
}
