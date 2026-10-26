/// A02:2025 Security Misconfiguration - VERSION VULNERABLE (capa de red de una app Flutter).
///
/// Modela la politica del cliente HTTP (equivalente a configurar dio / HttpClient).
/// Es un objeto de configuracion para poder inspeccionarlo en tests sin red.
class HttpClientConfig {
  final bool trustAllCertificates;
  final List<String> pinnedHosts;
  final bool logRequestBodies;
  final bool logAuthHeaders;
  final bool allowCleartext;

  const HttpClientConfig({
    required this.trustAllCertificates,
    required this.pinnedHosts,
    required this.logRequestBodies,
    required this.logAuthHeaders,
    required this.allowCleartext,
  });

  /// VULNERABLE: acepta cualquier certificado TLS (equivale a
  /// `badCertificateCallback = (cert, host, port) => true`), permite http:// y
  /// registra cuerpos y cabeceras Authorization en el log del dispositivo.
  factory HttpClientConfig.production() => const HttpClientConfig(
        trustAllCertificates: true,
        pinnedHosts: [],
        logRequestBodies: true,
        logAuthHeaders: true,
        allowCleartext: true,
      );

  /// Decide si se acepta un certificado presentado por [host].
  /// [chainValidByPlatform] = la cadena valida contra el almacen de confianza del SO.
  bool acceptCertificate({required String host, required bool chainValidByPlatform}) {
    // VULNERABLE: se ignora la validacion; un MITM con cert autofirmado es aceptado
    if (trustAllCertificates) return true;
    return chainValidByPlatform;
  }

  /// Linea que la app escribe en el log para una peticion.
  String logLine(String method, String url, Map<String, String> headers, String body) {
    final buf = StringBuffer('$method $url');
    if (logAuthHeaders && headers.containsKey('Authorization')) {
      buf.write(' Authorization=${headers['Authorization']}');
    }
    if (logRequestBodies) buf.write(' body=$body');
    return buf.toString();
  }

  /// Se permite esta URL?
  bool allowsUrl(String url) => allowCleartext || url.startsWith('https://');
}
