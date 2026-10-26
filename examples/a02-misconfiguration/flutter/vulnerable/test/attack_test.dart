// Ataque automatizado contra la version VULNERABLE.
// Los tests PASAN cuando la mala configuracion es explotable.
import 'package:test/test.dart';
import 'package:a02_misconfiguration_vulnerable/http_client_config.dart';

void main() {
  final cfg = HttpClientConfig.production();

  test('un MITM con certificado invalido es aceptado', () {
    expect(cfg.acceptCertificate(host: 'evil-proxy.example', chainValidByPlatform: false), isTrue);
  });

  test('el log filtra token y cuerpo sensibles', () {
    final line = cfg.logLine('POST', 'https://api.itau-demo.example/login',
        {'Authorization': 'Bearer DEMO-ONLY-token-123'}, '{"password":"DEMO-ONLY-pw"}');
    expect(line, contains('DEMO-ONLY-token-123'));
    expect(line, contains('DEMO-ONLY-pw'));
  });

  test('se permite trafico en texto plano', () {
    expect(cfg.allowsUrl('http://api.itau-demo.example/x'), isTrue);
  });
}
