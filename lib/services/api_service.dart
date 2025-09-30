import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/reporte_model.dart';
import '../models/dropdown_option.dart';
import 'connectivity_helper.dart';

class ApiService {
  static const String baseUrl = 'http://190.119.200.124:45490';
  static const Duration timeout = Duration(seconds: 60);

  final http.Client client;

  ApiService({http.Client? client}) : client = client ?? http.Client();

  Future<List<Reporte>> getReportesRendicionGasto({
    required String id,
    required String idrend,
    required String user,
  }) async {
    /*     debugPrint('🚀 Iniciando petición a API...');
    debugPrint('📍 URL base: $baseUrl/reporte/rendiciongasto');
    debugPrint('🏗️ Plataforma: ${Platform.operatingSystem}');
    debugPrint('🔧 Modo: ${kReleaseMode ? 'Release' : 'Debug'}'); */

    try {
      // Diagnóstico de conectividad en debug
      if (!kReleaseMode) {
        final diagnostic = await ConnectivityHelper.fullConnectivityDiagnostic(
          baseUrl,
        );
        debugPrint('🔬 Diagnóstico completo: $diagnostic');

        if (!diagnostic['internetConnection']) {
          throw Exception('❌ Sin conexión a internet');
        }

        if (!diagnostic['serverReachable']) {
          throw Exception('❌ No se puede alcanzar el servidor $baseUrl');
        }
      }

      // Construir la URL con los parámetros dinámicos
      final uri = Uri.parse(
        '$baseUrl/reporte/rendiciongasto',
      ).replace(queryParameters: {'id': id, 'idrend': idrend, 'user': user});
      /* 
      debugPrint('📡 Realizando petición HTTP GET...');
      debugPrint('🌍 URL final: $uri');
 */
      final response = await client
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json; charset=UTF-8',
              'User-Agent': 'Flutter-App/${Platform.operatingSystem}',
              'Connection': 'keep-alive',
              'Cache-Control': 'no-cache',
            },
          )
          .timeout(timeout);
      /* 
      debugPrint('📊 Respuesta recibida - Status: ${response.statusCode}');
      debugPrint('📦 Headers: ${response.headers}');
      debugPrint('📏 Tamaño de respuesta: ${response.body.length} bytes'); */

      if (response.statusCode == 200) {
        debugPrint('✅ Status 200 - Procesando JSON...');

        if (response.body.isEmpty) {
          throw Exception('⚠️ Respuesta vacía del servidor');
        }

        try {
          final List<dynamic> jsonData = json.decode(response.body);
          /*   debugPrint(
            '🎯 JSON parseado correctamente. Items: ${jsonData.length}',
          ); */

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
              /*               debugPrint('⚠️ Error al parsear item $i: $e');
 */
              if (errores < 5) {
                debugPrint('📄 JSON problemático: ${jsonData[i]}');
              }
            }
          }

          if (errores > 0) {
            /*             debugPrint('⚠️ Se encontraron $errores errores de parsing');
 */
          }

          /*    debugPrint(
            '✅ ${reportes.length} reportes procesados correctamente ($errores errores)',
          ); */
          return reportes;
        } catch (e) {
          debugPrint('❌ Error al parsear JSON: $e');
          debugPrint(
            '📄 Tipo de respuesta: ${response.headers['content-type']}',
          );
          debugPrint(
            '📄 Respuesta raw (primeros 500 chars): '
            '${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}',
          );
          throw Exception('Error al procesar respuesta del servidor: $e');
        }
      } else {
        /*      debugPrint('❌ Status ${response.statusCode}');
        debugPrint('📄 Response body: ${response.body}'); */
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

  /// Método genérico para obtener opciones de dropdown desde la API
  /// [endpoint] - La ruta del endpoint (ej: 'categorias', 'politicas', 'usuarios')
  Future<List<DropdownOption>> getDropdownOptionsPolitica(
    String endpoint,
  ) async {
    debugPrint('🚀 Obteniendo opciones de dropdown para: $endpoint');
    debugPrint('📍 URL: $baseUrl/$endpoint');

    try {
      // Diagnóstico de conectividad en modo debug
      if (!kReleaseMode) {
        final diagnostic = await ConnectivityHelper.fullConnectivityDiagnostic(
          baseUrl,
        );
        if (!diagnostic['internetConnection']) {
          throw Exception('❌ Sin conexión a internet');
        }
        if (!diagnostic['serverReachable']) {
          throw Exception('❌ No se puede alcanzar el servidor $baseUrl');
        }
      }

      debugPrint('📡 Realizando petición HTTP para dropdown...');
      final response = await client
          .get(
            Uri.parse('$baseUrl/$endpoint'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json; charset=UTF-8',
              'User-Agent': 'Flutter-App/${Platform.operatingSystem}',
              'Connection': 'keep-alive',
              'Cache-Control': 'no-cache',
            },
          )
          .timeout(timeout);

      debugPrint('📊 Respuesta dropdown - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        debugPrint('✅ Status 200 - Procesando JSON de dropdown...');

        if (response.body.isEmpty) {
          throw Exception('⚠️ Respuesta vacía del servidor');
        }

        try {
          final jsonData = json.decode(response.body);

          // Si la respuesta es una lista directa
          if (jsonData is List) {
            final options = jsonData
                .map<DropdownOption>((item) => DropdownOption.fromJson(item))
                .where((option) => option.isActive)
                .toList();

            debugPrint('✅ ${options.length} opciones de dropdown cargadas');
            return options;
          }

          // Si la respuesta tiene estructura de objeto
          final dropdownResponse = DropdownOptionsResponse.fromJson(jsonData);
          debugPrint(
            '✅ ${dropdownResponse.options.length} opciones de dropdown cargadas',
          );
          return dropdownResponse.options;
        } catch (e) {
          debugPrint('❌ Error al parsear JSON de dropdown: $e');
          throw Exception('Error al procesar respuesta del servidor: $e');
        }
      } else {
        debugPrint('❌ Status ${response.statusCode}');
        throw Exception(
          'Error del servidor (${response.statusCode}): ${response.reasonPhrase}',
        );
      }
    } on SocketException catch (e) {
      debugPrint('🔌 Error de conexión en dropdown: $e');
      throw Exception(
        'Sin conexión al servidor. Verifica tu conexión a internet.',
      );
    } on HttpException catch (e) {
      debugPrint('🌐 Error HTTP en dropdown: $e');
      throw Exception('Error de protocolo HTTP: $e');
    } on FormatException catch (e) {
      debugPrint('📝 Error de formato en dropdown: $e');
      throw Exception('El servidor devolvió datos en formato incorrecto');
    } catch (e) {
      debugPrint('💥 Error no manejado en dropdown: $e');
      throw Exception('Error inesperado: $e');
    }
  }

  /// Método genérico para obtener opciones de dropdown desde la API
  /// [endpoint] - La ruta del endpoint (ej: 'categorias', 'politicas', 'usuarios')
  Future<List<DropdownOption>> getDropdownOptionsCategoria(
    String endpoint,
  ) async {
    debugPrint('🚀 Obteniendo opciones de dropdown para: $endpoint');
    debugPrint('📍 URL: $baseUrl/$endpoint');

    try {
      // Diagnóstico de conectividad en modo debug
      if (!kReleaseMode) {
        final diagnostic = await ConnectivityHelper.fullConnectivityDiagnostic(
          baseUrl,
        );
        if (!diagnostic['internetConnection']) {
          throw Exception('❌ Sin conexión a internet');
        }
        if (!diagnostic['serverReachable']) {
          throw Exception('❌ No se puede alcanzar el servidor $baseUrl');
        }
      }

      debugPrint('📡 Realizando petición HTTP para dropdown...');
      final response = await client
          .get(
            Uri.parse('$baseUrl/$endpoint'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json; charset=UTF-8',
              'User-Agent': 'Flutter-App/${Platform.operatingSystem}',
              'Connection': 'keep-alive',
              'Cache-Control': 'no-cache',
            },
          )
          .timeout(timeout);

      debugPrint('📊 Respuesta dropdown - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        debugPrint('✅ Status 200 - Procesando JSON de dropdown...');

        if (response.body.isEmpty) {
          throw Exception('⚠️ Respuesta vacía del servidor');
        }

        try {
          final jsonData = json.decode(response.body);

          // Si la respuesta es una lista directa
          if (jsonData is List) {
            final options = jsonData
                .map<DropdownOption>((item) => DropdownOption.fromJson(item))
                .where((option) => option.isActive)
                .toList();

            debugPrint('✅ ${options.length} opciones de dropdown cargadas');
            return options;
          }

          // Si la respuesta tiene estructura de objeto
          final dropdownResponse = DropdownOptionsResponse.fromJson(jsonData);
          debugPrint(
            '✅ ${dropdownResponse.options.length} opciones de dropdown cargadas',
          );
          return dropdownResponse.options;
        } catch (e) {
          debugPrint('❌ Error al parsear JSON de dropdown: $e');
          throw Exception('Error al procesar respuesta del servidor: $e');
        }
      } else {
        debugPrint('❌ Status ${response.statusCode}');
        throw Exception(
          'Error del servidor (${response.statusCode}): ${response.reasonPhrase}',
        );
      }
    } on SocketException catch (e) {
      debugPrint('🔌 Error de conexión en dropdown: $e');
      throw Exception(
        'Sin conexión al servidor. Verifica tu conexión a internet.',
      );
    } on HttpException catch (e) {
      debugPrint('🌐 Error HTTP en dropdown: $e');
      throw Exception('Error de protocolo HTTP: $e');
    } on FormatException catch (e) {
      debugPrint('📝 Error de formato en dropdown: $e');
      throw Exception('El servidor devolvió datos en formato incorrecto');
    } catch (e) {
      debugPrint('💥 Error no manejado en dropdown: $e');
      throw Exception('Error inesperado: $e');
    }
  }

  /// Métodos específicos para diferentes tipos de dropdown
  /// Puedes personalizar estos endpoints según tu API

  /// Obtener categorías
  Future<List<DropdownOption>> getCategorias() async {
    return await getDropdownOptionsCategoria('categoria');
  }

  /// Obtener políticas
  Future<List<DropdownOption>> getPoliticas() async {
    return await getDropdownOptionsPolitica('politicas');
  }

  /// Obtener usuarios
  Future<List<DropdownOption>> getUsuarios() async {
    return await getDropdownOptionsPolitica('usuarios');
  }

  /// ==================== ENDPOINTS ESPECÍFICOS DE RENDICIÓN ====================

  /// Obtener políticas de rendición
  Future<List<DropdownOption>> getRendicionPoliticas() async {
    debugPrint('🚀 Obteniendo políticas de rendición...');
    debugPrint('📍 URL: $baseUrl/maestros/rendicion_politica');

    try {
      // Diagnóstico de conectividad en modo debug
      if (!kReleaseMode) {
        final diagnostic = await ConnectivityHelper.fullConnectivityDiagnostic(
          baseUrl,
        );
        if (!diagnostic['internetConnection']) {
          throw Exception('❌ Sin conexión a internet');
        }
        if (!diagnostic['serverReachable']) {
          throw Exception('❌ No se puede alcanzar el servidor $baseUrl');
        }
      }

      final response = await client
          .get(
            Uri.parse('$baseUrl/maestros/rendicion_politica'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json; charset=UTF-8',
              'User-Agent': 'Flutter-App/${Platform.operatingSystem}',
              'Connection': 'keep-alive',
              'Cache-Control': 'no-cache',
            },
          )
          .timeout(timeout);

      debugPrint(
        '📊 Respuesta políticas rendición - Status: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Status 200 - Procesando políticas de rendición...');

        if (response.body.isEmpty) {
          throw Exception('⚠️ Respuesta vacía del servidor');
        }

        try {
          final jsonData = json.decode(response.body);

          // Si la respuesta es una lista directa
          if (jsonData is List) {
            final options = jsonData
                .map<DropdownOption>((item) => DropdownOption.fromJson(item))
                .where((option) => option.isActive)
                .toList();

            debugPrint('✅ ${options.length} políticas de rendición cargadas');
            return options;
          }

          // Si la respuesta tiene estructura de objeto
          final dropdownResponse = DropdownOptionsResponse.fromJson(jsonData);
          debugPrint(
            '✅ ${dropdownResponse.options.length} políticas de rendición cargadas',
          );
          return dropdownResponse.options;
        } catch (e) {
          debugPrint('❌ Error al parsear JSON de políticas: $e');
          throw Exception('Error al procesar respuesta del servidor: $e');
        }
      } else {
        debugPrint('❌ Status ${response.statusCode}');
        throw Exception(
          'Error del servidor (${response.statusCode}): ${response.reasonPhrase}',
        );
      }
    } on SocketException catch (e) {
      debugPrint('🔌 Error de conexión en políticas: $e');
      throw Exception(
        'Sin conexión al servidor. Verifica tu conexión a internet.',
      );
    } on HttpException catch (e) {
      debugPrint('🌐 Error HTTP en políticas: $e');
      throw Exception('Error de protocolo HTTP: $e');
    } on FormatException catch (e) {
      debugPrint('📝 Error de formato en políticas: $e');
      throw Exception('El servidor devolvió datos en formato incorrecto');
    } catch (e) {
      debugPrint('💥 Error no manejado en políticas: $e');
      throw Exception('Error inesperado: $e');
    }
  }

  /// Obtener categorías de rendición según la política seleccionada
  /// [politica] - NOMBRE de la política o "todos" para obtener todas las categorías
  Future<List<DropdownOption>> getRendicionCategorias({
    String politica = 'todos',
  }) async {
    debugPrint(
      '🚀 Obteniendo categorías de rendición para política: $politica',
    );
    debugPrint(
      '📍 URL: $baseUrl/maestros/rendicion_categoria?politica=$politica',
    );

    try {
      // Diagnóstico de conectividad en modo debug
      if (!kReleaseMode) {
        final diagnostic = await ConnectivityHelper.fullConnectivityDiagnostic(
          baseUrl,
        );
        if (!diagnostic['internetConnection']) {
          throw Exception('❌ Sin conexión a internet');
        }
        if (!diagnostic['serverReachable']) {
          throw Exception('❌ No se puede alcanzar el servidor $baseUrl');
        }
      }

      final uri = Uri.parse(
        '$baseUrl/maestros/rendicion_categoria',
      ).replace(queryParameters: {'politica': politica});

      final response = await client
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json; charset=UTF-8',
              'User-Agent': 'Flutter-App/${Platform.operatingSystem}',
              'Connection': 'keep-alive',
              'Cache-Control': 'no-cache',
            },
          )
          .timeout(timeout);

      debugPrint(
        '📊 Respuesta categorías rendición - Status: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Status 200 - Procesando categorías de rendición...');

        if (response.body.isEmpty) {
          throw Exception('⚠️ Respuesta vacía del servidor');
        }

        try {
          final jsonData = json.decode(response.body);

          // Si la respuesta es una lista directa
          if (jsonData is List) {
            final options = jsonData
                .map<DropdownOption>((item) => DropdownOption.fromJson(item))
                .where((option) => option.isActive)
                .toList();

            debugPrint(
              '✅ ${options.length} categorías de rendición cargadas para política: $politica',
            );
            debugPrint('✅ ${options.length} opciones: $options');
            return options;
          }

          // Si la respuesta tiene estructura de objeto
          final dropdownResponse = DropdownOptionsResponse.fromJson(jsonData);
          debugPrint(
            '✅ ${dropdownResponse.options.length} categorías de rendición cargadas para política: $politica',
          );
          return dropdownResponse.options;
        } catch (e) {
          debugPrint('❌ Error al parsear JSON de categorías: $e');
          throw Exception('Error al procesar respuesta del servidor: $e');
        }
      } else {
        debugPrint('❌ Status ${response.statusCode}');
        throw Exception(
          'Error del servidor (${response.statusCode}): ${response.reasonPhrase}',
        );
      }
    } on SocketException catch (e) {
      debugPrint('🔌 Error de conexión en categorías: $e');
      throw Exception(
        'Sin conexión al servidor. Verifica tu conexión a internet.',
      );
    } on HttpException catch (e) {
      debugPrint('🌐 Error HTTP en categorías: $e');
      throw Exception('Error de protocolo HTTP: $e');
    } on FormatException catch (e) {
      debugPrint('📝 Error de formato en categorías: $e');
      throw Exception('El servidor devolvió datos en formato incorrecto');
    } catch (e) {
      debugPrint('💥 Error no manejado en categorías: $e');
      throw Exception('Error inesperado: $e');
    }
  }

  /// Guardar factura/rendición de gasto
  /// [facturaData] - Map con los datos de la factura a guardar
  /// Retorna true si se guardó exitosamente, false en caso contrario
  Future<bool> saveRendicionGasto(Map<String, dynamic> facturaData) async {
    debugPrint('🚀 Guardando factura/rendición de gasto...');
    debugPrint('📍 URL: $baseUrl/saveupdate/saverendiciongasto');
    debugPrint('📦 Datos a enviar: $facturaData');

    try {
      // Diagnóstico de conectividad en modo debug
      if (!kReleaseMode) {
        final diagnostic = await ConnectivityHelper.fullConnectivityDiagnostic(
          baseUrl,
        );
        if (!diagnostic['internetConnection']) {
          throw Exception('❌ Sin conexión a internet');
        }
        if (!diagnostic['serverReachable']) {
          throw Exception('❌ No se puede alcanzar el servidor $baseUrl');
        }
      }

      final response = await client
          .post(
            Uri.parse('$baseUrl/saveupdate/saverendiciongasto'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'User-Agent': 'Flutter-App/${Platform.operatingSystem}',
              'Connection': 'keep-alive',
            },
            body: json.encode([facturaData]),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint(
        '📊 Respuesta guardar factura - Status: ${response.statusCode}',
      );
      debugPrint('📄 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Verificar si la respuesta contiene errores
        if (response.body.contains('Error') ||
            response.body.contains('error')) {
          debugPrint('❌ Error en respuesta del servidor: ${response.body}');
          throw Exception('Error del servidor: ${response.body}');
        }

        debugPrint('✅ Factura guardada exitosamente');
        return true;
      } else {
        debugPrint('❌ Error del servidor: ${response.statusCode}');
        throw Exception(
          'Error del servidor: ${response.statusCode}\nRespuesta: ${response.body}',
        );
      }
    } on SocketException catch (e) {
      debugPrint('🔌 Error de conexión al guardar factura: $e');
      throw Exception(
        'Sin conexión al servidor. Verifica tu conexión a internet.',
      );
    } on HttpException catch (e) {
      debugPrint('🌐 Error HTTP al guardar factura: $e');
      throw Exception('Error de protocolo HTTP: $e');
    } on FormatException catch (e) {
      debugPrint('📝 Error de formato al guardar factura: $e');
      throw Exception('El servidor devolvió datos en formato incorrecto');
    } catch (e) {
      debugPrint('💥 Error no manejado al guardar factura: $e');
      rethrow;
    }
  }

  /// Autenticar usuario con credenciales
  /// [usuario] - Nombre de usuario o DNI
  /// [contrasena] - Contraseña del usuario
  /// [app] - ID de la aplicación (por defecto 12)
  /// Retorna el Map con los datos del usuario si el login es exitoso
  Future<Map<String, dynamic>> loginCredencial({
    required String usuario,
    required String contrasena,
    int app = 12,
  }) async {
    debugPrint('🚀 Iniciando autenticación de usuario...');
    debugPrint('📍 URL: $baseUrl/login/credencial');
    debugPrint('👤 Usuario: $usuario');
    debugPrint('📱 App ID: $app');

    try {
      // Diagnóstico de conectividad en modo debug
      if (!kReleaseMode) {
        final diagnostic = await ConnectivityHelper.fullConnectivityDiagnostic(
          baseUrl,
        );
        if (!diagnostic['internetConnection']) {
          throw Exception('❌ Sin conexión a internet');
        }
        if (!diagnostic['serverReachable']) {
          throw Exception('❌ No se puede alcanzar el servidor $baseUrl');
        }
      }

      final uri = Uri.parse('$baseUrl/login/credencial').replace(
        queryParameters: {
          'usuario': usuario,
          'contrasena': contrasena,
          'app': app.toString(),
        },
      );

      final response = await client
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'User-Agent': 'Flutter-App/${Platform.operatingSystem}',
              'Connection': 'keep-alive',
              'Cache-Control': 'no-cache',
            },
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('📊 Respuesta login - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        debugPrint('✅ Status 200 - Procesando respuesta de login...');

        if (response.body.isEmpty) {
          throw Exception('⚠️ Respuesta vacía del servidor');
        }

        try {
          final List<dynamic> jsonResponse = json.decode(response.body);

          if (jsonResponse.isNotEmpty) {
            final userData = jsonResponse[0];

            // Verificar que el usuario esté activo
            if (userData['estado'] == 'S') {
              debugPrint('✅ Usuario autenticado exitosamente');
              debugPrint('👤 Usuario: ${userData['usenam']}');
              return userData;
            } else {
              debugPrint('❌ Usuario inactivo');
              throw Exception('Usuario inactivo. Contacta al administrador.');
            }
          } else {
            debugPrint('❌ Lista de usuarios vacía');
            throw Exception('Usuario o contraseña incorrectos');
          }
        } catch (e) {
          if (e.toString().contains('Usuario inactivo') ||
              e.toString().contains('Usuario o contraseña incorrectos')) {
            rethrow;
          }
          debugPrint('❌ Error al parsear JSON de login: $e');
          throw Exception('Error al procesar respuesta del servidor: $e');
        }
      } else {
        debugPrint('❌ Error del servidor: ${response.statusCode}');
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } on SocketException catch (e) {
      debugPrint('🔌 Error de conexión en login: $e');
      throw Exception(
        'Sin conexión al servidor. Verifica tu conexión a internet.',
      );
    } on HttpException catch (e) {
      debugPrint('🌐 Error HTTP en login: $e');
      throw Exception('Error de protocolo HTTP: $e');
    } on FormatException catch (e) {
      debugPrint('📝 Error de formato en login: $e');
      throw Exception('El servidor devolvió datos en formato incorrecto');
    } catch (e) {
      if (e.toString().contains('Usuario inactivo') ||
          e.toString().contains('Usuario o contraseña incorrectos') ||
          e.toString().contains('Sin conexión') ||
          e.toString().contains('Error del servidor')) {
        rethrow;
      }
      debugPrint('💥 Error no manejado en login: $e');
      throw Exception('Error inesperado en login: $e');
    }
  }

  /// Obtener empresas asociadas a un usuario
  /// [userId] - ID del usuario para consultar sus empresas
  /// Retorna lista de Maps con los datos de las empresas del usuario
  Future<List<Map<String, dynamic>>> getUserCompanies(int userId) async {
    debugPrint('🚀 Obteniendo empresas del usuario...');
    debugPrint('📍 URL: $baseUrl/reporte/usuarioconsumidor');
    debugPrint('👤 User ID: $userId');

    try {
      // Diagnóstico de conectividad en modo debug
      if (!kReleaseMode) {
        final diagnostic = await ConnectivityHelper.fullConnectivityDiagnostic(
          baseUrl,
        );
        if (!diagnostic['internetConnection']) {
          throw Exception('❌ Sin conexión a internet');
        }
        if (!diagnostic['serverReachable']) {
          throw Exception('❌ No se puede alcanzar el servidor $baseUrl');
        }
      }

      final uri = Uri.parse(
        '$baseUrl/reporte/usuarioconsumidor',
      ).replace(queryParameters: {'id': userId.toString()});

      final response = await client
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'User-Agent': 'Flutter-App/${Platform.operatingSystem}',
              'Connection': 'keep-alive',
              'Cache-Control': 'no-cache',
            },
          )
          .timeout(const Duration(seconds: 30));

      debugPrint(
        '📊 Respuesta empresas usuario - Status: ${response.statusCode}',
      );
      debugPrint('📄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        debugPrint('✅ Status 200 - Procesando empresas del usuario...');

        if (response.body.isEmpty) {
          throw Exception('⚠️ Respuesta vacía del servidor');
        }

        try {
          final List<dynamic> jsonData = json.decode(response.body);

          if (jsonData.isEmpty) {
            debugPrint('⚠️ No se encontraron empresas asociadas al usuario');
            return [];
          }

          debugPrint(
            '✅ ${jsonData.length} empresas encontradas para el usuario',
          );
          return jsonData.cast<Map<String, dynamic>>();
        } catch (e) {
          debugPrint('❌ Error al parsear JSON de empresas: $e');
          throw Exception('Error al procesar respuesta del servidor: $e');
        }
      } else {
        debugPrint('❌ Error del servidor: ${response.statusCode}');
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } on SocketException catch (e) {
      debugPrint('🔌 Error de conexión al obtener empresas: $e');
      throw Exception(
        'Sin conexión al servidor. Verifica tu conexión a internet.',
      );
    } on HttpException catch (e) {
      debugPrint('🌐 Error HTTP al obtener empresas: $e');
      throw Exception('Error de protocolo HTTP: $e');
    } on FormatException catch (e) {
      debugPrint('📝 Error de formato al obtener empresas: $e');
      throw Exception('El servidor devolvió datos en formato incorrecto');
    } catch (e) {
      if (e.toString().contains('Sin conexión') ||
          e.toString().contains('Error del servidor') ||
          e.toString().contains('Respuesta vacía') ||
          e.toString().contains('Error al procesar')) {
        rethrow;
      }
      debugPrint('💥 Error no manejado al obtener empresas: $e');
      throw Exception('Error inesperado al obtener empresas: $e');
    }
  }

  // Cerrar el cliente cuando ya no se necesite
  void dispose() {
    client.close();
  }
}
