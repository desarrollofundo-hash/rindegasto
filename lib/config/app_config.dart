import 'package:flutter/foundation.dart';

/// Configuración de la aplicación
/// Centraliza URLs, timeouts y configuraciones de red
class AppConfig {
  // URLs del servidor
  static const String _prodBaseUrl = 'http://190.119.200.124:45490';
  static const String _devBaseUrl = 'http://localhost:3000'; // Para desarrollo local
  static const String _testBaseUrl = 'http://10.0.2.2:3000'; // Para emulador
  
  /// URL base dependiendo del entorno
  /// Puedes cambiar esto para usar URLs locales durante desarrollo
  static String get baseUrl {
    // Opciones disponibles:
    // return _prodBaseUrl;  // Servidor de producción
    // return _devBaseUrl;   // Desarrollo local
    // return _testBaseUrl;  // Emulador
    return _prodBaseUrl;
  }
  
  /// URLs alternativas para probar conectividad
  static const List<String> alternativeUrls = [
    'http://190.119.200.124:45490',
    'http://190.119.200.124:8080',
    'http://192.168.1.100:45490', // Ejemplo de IP local
  ];
  
  // Timeouts
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration connectionTimeout = Duration(seconds: 10);
  static const Duration readTimeout = Duration(seconds: 30);
  
  // Configuraciones de reintento
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);
  
  // Configuraciones de conectividad
  static const bool enableConnectivityCheck = true;
  static const bool enableDetailedLogging = true;
  
  /// Obtiene la configuración completa como mapa
  static Map<String, dynamic> get config => {
    'baseUrl': baseUrl,
    'alternativeUrls': alternativeUrls,
    'defaultTimeout': defaultTimeout.inSeconds,
    'connectionTimeout': connectionTimeout.inSeconds,
    'readTimeout': readTimeout.inSeconds,
    'maxRetries': maxRetries,
    'retryDelay': retryDelay.inSeconds,
    'enableConnectivityCheck': enableConnectivityCheck,
    'enableDetailedLogging': enableDetailedLogging,
    'environment': kDebugMode ? 'debug' : 'release',
  };
  
  /// Endpoints específicos
  static const Map<String, String> endpoints = {
    'reportesRendicion': '/reporte/rendiciongasto',
    'reportesCosecha': '/reporte/cosechavalvulas',
    'rendicionPoliticas': '/maestros/rendicion_politica',
    'rendicionCategorias': '/maestros/rendicion_categoria',
    'categorias': '/maestros/categorias',
    'politicas': '/maestros/politicas',
    'usuarios': '/maestros/usuarios',
  };
  
  /// Obtiene la URL completa para un endpoint
  static String getEndpointUrl(String endpointKey) {
    final endpoint = endpoints[endpointKey];
    if (endpoint == null) {
      throw ArgumentError('Endpoint no encontrado: $endpointKey');
    }
    return '$baseUrl$endpoint';
  }
}