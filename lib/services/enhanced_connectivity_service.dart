import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

/// Servicio mejorado de conectividad con manejo de errores y reintentos
class EnhancedConnectivityService {
  static final EnhancedConnectivityService _instance = EnhancedConnectivityService._internal();
  factory EnhancedConnectivityService() => _instance;
  EnhancedConnectivityService._internal();

  /// Verifica si hay conexión a internet
  static Future<bool> hasInternetConnection() async {
    try {
      // Probar múltiples servicios DNS
      final results = await Future.wait([
        InternetAddress.lookup('google.com'),
        InternetAddress.lookup('cloudflare.com'),
        InternetAddress.lookup('8.8.8.8'),
      ]);
      
      return results.any((result) => result.isNotEmpty && result[0].rawAddress.isNotEmpty);
    } on SocketException catch (_) {
      return false;
    } catch (e) {
      debugPrint('❌ Error verificando conexión a internet: $e');
      return false;
    }
  }

  /// Prueba conectividad a un servidor específico
  static Future<bool> canReachServer(String baseUrl, {Duration? timeout}) async {
    try {
      final uri = Uri.parse(baseUrl);
      final host = uri.host;
      final port = uri.port;

      debugPrint('🔍 Probando conectividad a $host:$port');

      final socket = await Socket.connect(
        host,
        port,
        timeout: timeout ?? AppConfig.connectionTimeout,
      );
      socket.destroy();
      debugPrint('✅ Servidor $host:$port alcanzable');
      return true;
    } catch (e) {
      debugPrint('❌ No se puede conectar a servidor: $e');
      return false;
    }
  }

  /// Prueba múltiples URLs alternativas
  static Future<String?> findWorkingUrl(List<String> urls) async {
    debugPrint('🔍 Probando ${urls.length} URLs alternativas...');
    
    for (final url in urls) {
      try {
        final canConnect = await canReachServer(url);
        if (canConnect) {
          debugPrint('✅ URL funcional encontrada: $url');
          return url;
        }
      } catch (e) {
        debugPrint('❌ Fallo en URL $url: $e');
      }
    }
    
    debugPrint('❌ Ninguna URL alternativa funcionó');
    return null;
  }

  /// Hace una petición HTTP con reintentos automáticos
  static Future<http.Response> httpRequestWithRetry(
    String url, {
    Map<String, String>? headers,
    int? maxRetries,
    Duration? retryDelay,
    Duration? timeout,
  }) async {
    final actualMaxRetries = maxRetries ?? AppConfig.maxRetries;
    final actualRetryDelay = retryDelay ?? AppConfig.retryDelay;
    final actualTimeout = timeout ?? AppConfig.defaultTimeout;

    Exception? lastException;

    for (int attempt = 1; attempt <= actualMaxRetries; attempt++) {
      try {
        debugPrint('🚀 Intento $attempt/$actualMaxRetries - $url');

        final response = await http.get(
          Uri.parse(url),
          headers: headers ?? {
            'Accept': 'application/json',
            'Content-Type': 'application/json; charset=UTF-8',
            'User-Agent': 'Flutter-App/${Platform.operatingSystem}',
            'Connection': 'keep-alive',
            'Cache-Control': 'no-cache',
          },
        ).timeout(actualTimeout);

        debugPrint('✅ Éxito en intento $attempt - Status: ${response.statusCode}');
        return response;

      } on SocketException catch (e) {
        lastException = e;
        debugPrint('🔌 SocketException en intento $attempt: $e');
      } on TimeoutException catch (e) {
        lastException = e;
        debugPrint('⏰ TimeoutException en intento $attempt: $e');
      } on HttpException catch (e) {
        lastException = e;
        debugPrint('🌐 HttpException en intento $attempt: $e');
      } catch (e) {
        lastException = Exception('Error inesperado: $e');
        debugPrint('💥 Error inesperado en intento $attempt: $e');
      }

      // Si no es el último intento, esperar antes del siguiente
      if (attempt < actualMaxRetries) {
        debugPrint('⏳ Esperando ${actualRetryDelay.inSeconds}s antes del siguiente intento...');
        await Future.delayed(actualRetryDelay);
      }
    }

    // Si llegamos aquí, todos los intentos fallaron
    throw lastException ?? Exception('Todos los intentos de conexión fallaron');
  }

  /// Diagnóstico completo de conectividad
  static Future<Map<String, dynamic>> fullDiagnostic({String? customUrl}) async {
    debugPrint('🔬 Iniciando diagnóstico completo de conectividad...');
    final diagnostic = <String, dynamic>{};
    final stopwatch = Stopwatch()..start();

    try {
      // 1. Test de conexión a internet
      diagnostic['internetConnection'] = await hasInternetConnection();
      debugPrint('🌐 Internet: ${diagnostic['internetConnection']}');

      // 2. Test de conectividad al servidor principal
      final baseUrl = customUrl ?? AppConfig.baseUrl;
      diagnostic['primaryServerReachable'] = await canReachServer(baseUrl);
      debugPrint('🖥️ Servidor principal: ${diagnostic['primaryServerReachable']}');

      // 3. Si el servidor principal no funciona, probar alternativas
      if (!diagnostic['primaryServerReachable']) {
        final workingUrl = await findWorkingUrl(AppConfig.alternativeUrls);
        diagnostic['alternativeUrlFound'] = workingUrl != null;
        diagnostic['workingUrl'] = workingUrl;
      }

      // 4. Test de endpoint específico
      try {
        final testUrl = '${customUrl ?? AppConfig.baseUrl}${AppConfig.endpoints['reportesRendicion']}';
        final testResponse = await httpRequestWithRetry(
          testUrl,
          maxRetries: 1,
          timeout: const Duration(seconds: 10),
        );
        
        diagnostic['endpointTest'] = {
          'success': testResponse.statusCode == 200,
          'statusCode': testResponse.statusCode,
          'responseTime': stopwatch.elapsedMilliseconds,
        };
      } catch (e) {
        diagnostic['endpointTest'] = {
          'success': false,
          'error': e.toString(),
          'responseTime': stopwatch.elapsedMilliseconds,
        };
      }

      // 5. Información del dispositivo
      diagnostic['platform'] = Platform.operatingSystem;
      diagnostic['isEmulator'] = Platform.isAndroid && !Platform.environment.containsKey('FLUTTER_TEST');
      diagnostic['dartVersion'] = Platform.version;

      stopwatch.stop();
      diagnostic['totalDiagnosticTime'] = stopwatch.elapsedMilliseconds;

      debugPrint('📋 Diagnóstico completo: $diagnostic');
      return diagnostic;

    } catch (e) {
      stopwatch.stop();
      diagnostic['error'] = e.toString();
      diagnostic['totalDiagnosticTime'] = stopwatch.elapsedMilliseconds;
      debugPrint('❌ Error en diagnóstico: $e');
      return diagnostic;
    }
  }

  /// Obtiene sugerencias basadas en el diagnóstico
  static List<String> getSuggestions(Map<String, dynamic> diagnostic) {
    final suggestions = <String>[];

    if (!diagnostic['internetConnection']) {
      suggestions.add('📶 Verifica tu conexión a internet WiFi o datos móviles');
      suggestions.add('🔄 Intenta cambiar de red WiFi o usar datos móviles');
    }

    if (!diagnostic['primaryServerReachable']) {
      suggestions.add('🏢 El servidor principal no está disponible');
      suggestions.add('⏰ Puede ser un problema temporal del servidor');
      
      if (diagnostic['alternativeUrlFound'] == true) {
        suggestions.add('✅ Se encontró una URL alternativa funcional');
      } else {
        suggestions.add('❌ Ninguna URL alternativa funciona');
        suggestions.add('🔧 Contacta al administrador del sistema');
      }
    }

    if (diagnostic['platform'] == 'android' && diagnostic['isEmulator'] == true) {
      suggestions.add('📱 Estás usando un emulador Android');
      suggestions.add('🔧 Verifica la configuración de red del emulador');
      suggestions.add('💡 Prueba en un dispositivo físico');
    }

    if (suggestions.isEmpty) {
      suggestions.add('✅ La conectividad parece estar funcionando correctamente');
    }

    return suggestions;
  }
}