// Mismo ataque contra la version CORREGIDA.
// El test PASA cuando la inyeccion es BLOQUEADA y el login legitimo sigue funcionando.
import 'package:test/test.dart';
import 'package:a05_injection_fixed/auth_repository.dart';

void main() {
  final repo = AuthRepository();

  test('la inyeccion SQL ya no permite el bypass', () {
    final r = repo.login("admin' --", "cualquier-cosa");
    expect(r.authenticated, isFalse,
        reason: 'la consulta parametrizada debe bloquear la inyeccion');
  });

  test('el login legitimo sigue funcionando', () {
    final r = repo.login('alice', 'alice-pass-123');
    expect(r.authenticated, isTrue);
    expect(r.balance, 50000);
  });
}
