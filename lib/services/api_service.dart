import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/reporte_model.dart';
import '../models/dropdown_option.dart';
import '../config/app_config.dart';
import 'enhanced_connectivity_service.dart';

class ApiService {
  // Usar configuración centralizada
  static String get baseUrl => AppConfig.baseUrl;
  static Duration get timeout => AppConfig.defaultTimeout;

  final http.Client client;

  ApiService({http.Client? client}) : client = client ?? http.Client();

  /// Método principal para obtener reportes de rendición de gasto
  Future<List<Reporte>> getReportesRendicionGasto({
    required String id,
    required String idrend,
    required String user,
  }) async {
    debugPrint('🚀 Iniciando petición a API...');
    debugPrint('📍 URL base: $baseUrl${AppConfig.endpoints['reportesRendicion']}');
    debugPrint('🏗️ Plataforma: ${Platform.operatingSystem}');
    debugPrint('🔧 Modo: ${kReleaseMode ? 'Release' : 'Debug'}');

    try {
      // Diagnóstico de conectividad en debug
      if (!kReleaseMode && AppConfig.enableConnectivityCheck) {
        final diagnostic = await EnhancedConnectivityService.fullDiagnostic();
        debugPrint('🔬 Diagnóstico completo: $diagnostic');

        if (!diagnostic['internetConnection']) {
          throw Exception('❌ Sin conexión a internet');
        }

        if (!diagnostic['primaryServerReachable']) {
          // Si hay URL alternativa, intentar usarla
          if (diagnostic['workingUrl'] != null) {
            debugPrint('🔄 Usando URL alternativa: ${diagnostic['workingUrl']}');
            // Aquí podrías cambiar temporalmente la baseUrl
          } else {
            throw Exception('❌ No se puede alcanzar el servidor $baseUrl');
          }
        }
      }

      // Construir la URL con los parámetros dinámicos
      final endpoint = AppConfig.endpoints['reportesRendicion']!;
      final uri = Uri.parse('$baseUrl$endpoint').replace(
        queryParameters: {'id': id, 'idrend': idrend, 'user': user},
      );

      debugPrint('📡 Realizando petición HTTP GET...');
      debugPrint('🌍 URL final: $uri');

      // Usar el servicio mejorado con reintentos
      final response = await EnhancedConnectivityService.httpRequestWithRetry(
        uri.toString(),
        timeout: timeout,
      );

      debugPrint('📊 Respuesta recibida - Status: ${response.statusCode}');
      debugPrint('📦 Headers: ${response.headers}');
      debugPrint('📏 Tamaño de respuesta: ${response.body.length} bytes');

      if (response.statusCode == 200) {
        return _processReportesResponse(response.body);
      } else {
        debugPrint('❌ Status ${response.statusCode}');
        debugPrint('📄 Response body: ${response.body}');
        throw Exception(
          'Error del servidor (${response.statusCode}): ${response.reasonPhrase}',
        );
      }
    } on SocketException catch (e) {
      debugPrint('🔌 Error de conexión (SocketException): $e');
      throw Exception(
        'Sin conexión al servidor. Verifica tu conexión a internet y que el servidor esté disponible.',
      );
    } on HttpException catch (e) {
      debugPrint('🌐 Error HTTP: $e');
      throw Exception('Error de protocolo HTTP: $e');
    } on FormatException catch (e) {
      debugPrint('📝 Error de formato: $e');
      throw Exception('El servidor devolvió datos en formato incorrecto');
    } on Exception catch (e) {
      debugPrint('❌ Error general: $e');
      rethrow;
    } catch (e) {
      debugPrint('💥 Error no manejado: $e');
      throw Exception('Error inesperado: $e');
    }
  }

  /// Procesa la respuesta de reportes
  List<Reporte> _processReportesResponse(String responseBody) {
    debugPrint('✅ Status 200 - Procesando JSON...');

    if (responseBody.isEmpty) {
      throw Exception('⚠️ Respuesta vacía del servidor');
    }

    try {
      final List<dynamic> jsonData = json.decode(responseBody);
      debugPrint('🎯 JSON parseado correctamente. Items: ${jsonData.length}');

      if (jsonData.isEmpty) {
        debugPrint('⚠️ La API devolvió una lista vacía');
        return [];
      }

      final reportes = <Reporte>[];
      int errores = 0;

      for (int i = 0; i < jsonData.length; i++) {
        try {
          final reporte = Reporte.fromJson(jsonData[i]);
          reportes.add(reporte);
        } catch (e) {
          errores++;
          debugPrint('⚠️ Error al parsear item $i: $e');
          if (errores < 5) {
            debugPrint('📄 JSON problemático: ${jsonData[i]}');
          }
        }
      }

      if (errores > 0) {
        debugPrint('⚠️ Se encontraron $errores errores de parsing');
      }

      debugPrint(
        '✅ ${reportes.length} reportes procesados correctamente ($errores errores)',
      );
      return reportes;
    } catch (e) {
      debugPrint('❌ Error al parsear JSON: $e');
      debugPrint(
        '📄 Respuesta raw (primeros 500 chars): '
        '${responseBody.substring(0, responseBody.length > 500 ? 500 : responseBody.length)}',
      );
      throw Exception('Error al procesar respuesta del servidor: $e');
    }
  }

  /// Método genérico para obtener opciones de dropdown desde la API
  Future<List<DropdownOption>> getDropdownOptionsPolitica(String endpoint) async {
    debugPrint('🚀 Obteniendo opciones de dropdown para: $endpoint');
    debugPrint('📍 URL: $baseUrl/$endpoint');

    try {
      // Diagnóstico de conectividad en modo debug
      if (!kReleaseMode && AppConfig.enableConnectivityCheck) {
        final diagnostic = await EnhancedConnectivityService.fullDiagnostic();
        if (!diagnostic['internetConnection']) {
          throw Exception('❌ Sin conexión a internet');
        }
        if (!diagnostic['primaryServerReachable']) {
          throw Exception('❌ No se puede alcanzar el servidor $baseUrl');
        }
      }

      debugPrint('📡 Realizando petición HTTP para dropdown...');
      
      // Usar el servicio mejorado con reintentos
      final response = await EnhancedConnectivityService.httpRequestWithRetry(
        '$baseUrl/$endpoint',
        timeout: timeout,
      );

      debugPrint('📊 Respuesta dropdown - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return _processDropdownResponse(response.body);
      } else {
        debugPrint('❌ Status ${response.statusCode}');
        throw Exception(
          'Error del servidor (${response.statusCode}): ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      debugPrint('❌ Error en dropdown: $e');
      rethrow;
    }
  }

  /// Procesa la respuesta de dropdown
  List<DropdownOption> _processDropdownResponse(String responseBody) {
    debugPrint('✅ Status 200 - Procesando JSON de dropdown...');

    if (responseBody.isEmpty) {
      throw Exception('⚠️ Respuesta vacía del servidor');
    }

    try {
      final jsonData = json.decode(responseBody);

      // Si la respuesta es una lista directa
      if (jsonData is List) {
        final options = jsonData
            .map<DropdownOption>((item) => DropdownOption.fromJson(item))
            .toList();
        debugPrint('✅ ${options.length} opciones de dropdown procesadas');
        return options;
      }

      // Si la respuesta es un objeto con una propiedad que contiene la lista
      if (jsonData is Map<String, dynamic>) {
        // Buscar propiedades comunes que puedan contener la lista
        final possibleKeys = ['data', 'items', 'results', 'options'];
        for (final key in possibleKeys) {
          if (jsonData.containsKey(key) && jsonData[key] is List) {
            final options = (jsonData[key] as List)
                .map<DropdownOption>((item) => DropdownOption.fromJson(item))
                .toList();
            debugPrint('✅ ${options.length} opciones encontradas en "$key"');
            return options;
          }
        }
      }

      throw Exception('Formato de respuesta no reconocido para dropdown');
    } catch (e) {
      debugPrint('❌ Error al parsear JSON de dropdown: $e');
      debugPrint(
        '📄 Respuesta: ${responseBody.substring(0, responseBody.length > 200 ? 200 : responseBody.length)}',
      );
      throw Exception('Error al procesar opciones de dropdown: $e');
    }
  }

  // Métodos específicos para cada tipo de dropdown
  Future<List<DropdownOption>> getCategorias() async {
    return getDropdownOptionsPolitica('maestros/categorias');
  }

  Future<List<DropdownOption>> getPoliticas() async {
    return getDropdownOptionsPolitica('maestros/politicas');
  }

  Future<List<DropdownOption>> getUsuarios() async {
    return getDropdownOptionsPolitica('maestros/usuarios');
  }

  Future<List<DropdownOption>> getRendicionPoliticas() async {
    return getDropdownOptionsPolitica('maestros/rendicion_politica');
  }

  Future<List<DropdownOption>> getRendicionCategorias({String? politica}) async {
    String endpoint = 'maestros/rendicion_categoria';
    if (politica != null && politica != 'todos') {
      endpoint += '?politica=$politica';
    }
    return getDropdownOptionsPolitica(endpoint);
  }

  /// Método para diagnosticar problemas de conectividad
  Future<Map<String, dynamic>> diagnoseConnectivity() async {
    final diagnostic = await EnhancedConnectivityService.fullDiagnostic();
    final suggestions = EnhancedConnectivityService.getSuggestions(diagnostic);
    
    return {
      ...diagnostic,
      'suggestions': suggestions,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}