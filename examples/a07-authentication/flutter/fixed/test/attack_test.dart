import 'package:test/test.dart';
import 'package:a07_authentication_fixed/session_guard.dart';

void main() {
  test('PIN legitimo desbloquea', () {
    final g = SessionGuard(pin: '4821', store: SecureStore());
    expect(g.unlock('4821'), isNotNull);
  });

  test('BLOQUEADO: tras 5 PINs erroneos se bloquea, incluso con el PIN correcto', () {
    var t = DateTime(2026, 1, 1);
    final g = SessionGuard(pin: '4821', store: SecureStore(), now: () => t);
    for (var i = 0; i < 5; i++) {
      expect(g.unlock('000$i'), isNull);
    }
    expect(g.unlock('4821'), isNull); // bloqueado
    // la fuerza bruta completa ya no encuentra el PIN
    String? found;
    for (var i = 0; i < 10000 && found == null; i++) {
      if (g.unlock(i.toString().padLeft(4, '0')) != null) found = 'x';
    }
    expect(found, isNull);
    // tras el cooldown el usuario legitimo vuelve a entrar
    t = t.add(SessionGuard.lockout + const Duration(seconds: 1));
    expect(g.unlock('4821'), isNotNull);
  });

  test('BLOQUEADO: el token expira y se borra del almacen', () {
    var t = DateTime(2026, 1, 1);
    final store = SecureStore();
    final g = SessionGuard(pin: '4821', store: store, now: () => t);
    final token = g.unlock('4821')!;
    expect(g.isSessionValid(token), isTrue);
    t = t.add(SessionGuard.tokenTtl + const Duration(seconds: 1));
    expect(g.isSessionValid(token), isFalse);
    expect(store.data.containsKey('session_token'), isFalse);
  });
}
