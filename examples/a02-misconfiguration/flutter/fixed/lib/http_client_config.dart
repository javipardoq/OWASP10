/// A02:2025 Security Misconfiguration - VERSION FIXED (capa de red de una app Flutter).
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

  /// FIX: validacion TLS estricta, solo hosts conocidos, solo https y sin datos
  /// sensibles en el log.
  factory HttpClientConfig.production() => const HttpClientConfig(
        trustAllCertificates: false,
        pinnedHosts: ['api.itau-demo.example'],
        logRequestBodies: false,
        logAuthHeaders: false,
        allowCleartext: false,
      );

  /// Decide si se acepta un certificado presentado por [host].
  /// [chainValidByPlatform] = la cadena valida contra el almacen de confianza del SO.
  bool acceptCertificate({required String host, required bool chainValidByPlatform}) {
    // FIX: la cadena debe ser valida y el host debe estar en la lista permitida
    if (trustAllCertificates) return true;
    return chainValidByPlatform && pinnedHosts.contains(host);
  }

  /// Linea que la app escribe en el log para una peticion.
  String logLine(String method, String url, Map<String, String> headers, String body) {
    final buf = StringBuffer('$method $url');
    // FIX: nunca se registran cabeceras de autenticacion ni cuerpos
    if (logAuthHeaders && headers.containsKey('Authorization')) {
      buf.write(' Authorization=${headers['Authorization']}');
    }
    if (logRequestBodies) buf.write(' body=$body');
    return buf.toString();
  }

  /// Se permite esta URL?
  bool allowsUrl(String url) => allowCleartext || url.startsWith('https://');
}
