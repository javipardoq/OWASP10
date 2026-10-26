// Mismo ataque contra la version FIXED.
// Los tests PASAN cuando el ataque es bloqueado y el uso legitimo sigue funcionando.
import 'package:test/test.dart';
import 'package:a02_misconfiguration_fixed/http_client_config.dart';

void main() {
  final cfg = HttpClientConfig.production();

  test('un MITM con certificado invalido es rechazado', () {
    expect(cfg.acceptCertificate(host: 'evil-proxy.example', chainValidByPlatform: false), isFalse);
    // aunque la cadena sea valida, un host fuera de la lista tampoco se acepta
    expect(cfg.acceptCertificate(host: 'evil-proxy.example', chainValidByPlatform: true), isFalse);
  });

  test('el log no filtra token ni cuerpo', () {
    final line = cfg.logLine('POST', 'https://api.itau-demo.example/login',
        {'Authorization': 'Bearer DEMO-ONLY-token-123'}, '{"password":"DEMO-ONLY-pw"}');
    expect(line, isNot(contains('DEMO-ONLY-token-123')));
    expect(line, isNot(contains('DEMO-ONLY-pw')));
  });

  test('se bloquea el trafico en texto plano', () {
    expect(cfg.allowsUrl('http://api.itau-demo.example/x'), isFalse);
  });

  test('el uso legitimo funciona: host propio con cadena valida sobre https', () {
    expect(cfg.acceptCertificate(host: 'api.itau-demo.example', chainValidByPlatform: true), isTrue);
    expect(cfg.allowsUrl('https://api.itau-demo.example/x'), isTrue);
  });
}
