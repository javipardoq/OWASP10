import 'package:test/test.dart';
import 'package:a07_authentication_vulnerable/session_guard.dart';

void main() {
  test('PIN legitimo desbloquea', () {
    final g = SessionGuard(pin: '4821', store: PlainStore());
    expect(g.unlock('4821'), isNotNull);
  });

  test('ATAQUE: fuerza bruta de los 10.000 PINs tiene exito (sin limite local)', () {
    final g = SessionGuard(pin: '4821', store: PlainStore());
    String? found;
    for (var i = 0; i < 10000 && found == null; i++) {
      if (g.unlock(i.toString().padLeft(4, '0')) != null) found = i.toString().padLeft(4, '0');
    }
    expect(found, '4821');
  });

  test('ATAQUE: un token robado sigue valido 1 anio despues (nunca expira)', () {
    var t = DateTime(2026, 1, 1);
    final store = PlainStore();
    final g = SessionGuard(pin: '4821', store: store, now: () => t);
    final token = g.unlock('4821')!;
    t = t.add(const Duration(days: 365));
    expect(g.isSessionValid(token), isTrue);
    // y ademas esta en texto plano en el almacen
    expect(store.data['session_token'], token);
  });
}
