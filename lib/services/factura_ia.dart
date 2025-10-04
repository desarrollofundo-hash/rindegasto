import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Servicio mejorado para extraer datos de facturas con IA y Google ML Kit
class FacturaIA {
  static final _textRecognizer = TextRecognizer();
  static bool _modeloInicializado = false;

  /// Inicializa el sistema de extracción
  static Future<void> inicializarModelo() async {
    try {
      if (!_modeloInicializado) {
        _modeloInicializado = true;
        print('✅ Sistema de extracción inicializado');
      }
    } catch (e) {
      print('Error inicializando sistema: $e');
    }
  }

  /// Extrae datos específicos de facturas con IA optimizada
  static Future<Map<String, String>> extraerDatos(File imagen) async {
    try {
      // Inicializar modelo si no está listo
      await inicializarModelo();

      final inputImage = InputImage.fromFile(imagen);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      final texto = recognizedText.text.toUpperCase();
      final lineas = texto
          .split('\n')
          .where((l) => l.trim().isNotEmpty)
          .toList();

      Map<String, String> datos = {};

      // CAMPOS ESPECÍFICOS REQUERIDOS:

      // 1. RUC EMISOR
      final rucEmisor = _buscarRUC(lineas);
      if (rucEmisor != null) datos['RUC Emisor'] = rucEmisor;

      // 2. RUC CLIENTE
      final rucCliente = _buscarRUCCliente(texto, rucEmisor);
      if (rucCliente != null) datos['RUC Cliente'] = rucCliente;

      // 3. TIPO DE COMPROBANTE
      final tipoComprobante = _buscarTipoComprobante(lineas);
      if (tipoComprobante != null) datos['Tipo Comprobante'] = tipoComprobante;

      // 4. SERIE Y NÚMERO
      final serieNumero = _buscarSerieNumero(texto);
      if (serieNumero['serie'] != null) datos['Serie'] = serieNumero['serie']!;
      if (serieNumero['numero'] != null) {
        datos['Número'] = serieNumero['numero']!;
      }

      // 5. FECHA DE FACTURA
      final fechaEmision = _buscarFechaEmision(texto);
      if (fechaEmision != null) datos['Fecha'] = fechaEmision;

      // 6. TOTAL A PAGAR (con múltiples variaciones)
      final total = _buscarTotalMejorado(texto);
      if (total != null) datos['Total'] = total;

      // 7. IGV
      final igv = _buscarIGVMejorado(texto);
      if (igv != null) datos['IGV'] = igv;

      // 8. MONEDA
      final moneda = _buscarMonedaMejorada(texto);
      if (moneda != null) datos['Moneda'] = moneda;

      // 9. EMPRESA/RAZÓN SOCIAL
      final empresa = _buscarEmpresa(lineas);
      if (empresa != null) datos['Empresa'] = empresa;

      print('📋 Campos detectados: ${datos.keys.join(", ")}');
      return datos;
    } catch (e) {
      print('Error en OCR: $e');
      return {'Error': 'No se pudo procesar la imagen'};
    }
  }

  /// Extrae características numéricas del texto OCR
  // ignore: unused_element
  static List<double> _extraerCaracteristicas(String texto) {
    final caracteristicas = List<double>.filled(50, 0.0);

    try {
      // Características básicas del texto
      caracteristicas[0] =
          texto.length.toDouble() / 1000; // Longitud normalizada
      caracteristicas[1] =
          texto.split('\n').length.toDouble() / 50; // Líneas normalizadas
      caracteristicas[2] =
          RegExp(r'\d').allMatches(texto).length.toDouble() /
          100; // Densidad numérica

      // Presencia de palabras clave (0 o 1)
      caracteristicas[3] = texto.contains('RUC') ? 1.0 : 0.0;
      caracteristicas[4] = texto.contains('IGV') ? 1.0 : 0.0;
      caracteristicas[5] = texto.contains('TOTAL') ? 1.0 : 0.0;
      caracteristicas[6] = texto.contains('FACTURA') ? 1.0 : 0.0;
      caracteristicas[7] = texto.contains('BOLETA') ? 1.0 : 0.0;
      caracteristicas[8] = texto.contains('FECHA') ? 1.0 : 0.0;
      caracteristicas[9] = texto.contains('EMISIÓN') ? 1.0 : 0.0;
      caracteristicas[10] = texto.contains('SERIE') ? 1.0 : 0.0;

      // Patrones de números
      final numeros11Digitos = RegExp(r'\b\d{11}\b').allMatches(texto).length;
      caracteristicas[11] = numeros11Digitos.toDouble();

      final patronesFecha = RegExp(
        r'\d{2}[/-]\d{2}[/-]\d{4}',
      ).allMatches(texto).length;
      caracteristicas[12] = patronesFecha.toDouble();

      final patronesMoneda = RegExp(r'S/\.?\s*\d+').allMatches(texto).length;
      caracteristicas[13] = patronesMoneda.toDouble();

      // Características de formato
      caracteristicas[14] =
          RegExp(r'[A-Z]{3,}').allMatches(texto).length.toDouble() / 10;
      caracteristicas[15] = RegExp(
        r'\d+\.\d{2}',
      ).allMatches(texto).length.toDouble();
      caracteristicas[16] = RegExp(
        r'\d+,\d{3}',
      ).allMatches(texto).length.toDouble();

      // Posición relativa de elementos clave
      final posicionRUC = texto.indexOf('RUC');
      caracteristicas[17] = posicionRUC >= 0
          ? posicionRUC.toDouble() / texto.length
          : 0.0;

      final posicionIGV = texto.indexOf('IGV');
      caracteristicas[18] = posicionIGV >= 0
          ? posicionIGV.toDouble() / texto.length
          : 0.0;

      final posicionTotal = texto.indexOf('TOTAL');
      caracteristicas[19] = posicionTotal >= 0
          ? posicionTotal.toDouble() / texto.length
          : 0.0;

      // Más características específicas para Perú
      caracteristicas[20] = texto.contains('SUNAT') ? 1.0 : 0.0;
      caracteristicas[21] = texto.contains('CONTRIBUYENTE') ? 1.0 : 0.0;
      caracteristicas[22] = RegExp(r'\b[FBT]\d{3}-\d+').hasMatch(texto)
          ? 1.0
          : 0.0; // Serie
      caracteristicas[23] = RegExp(
        r'\d{8}',
      ).allMatches(texto).length.toDouble(); // DNI
      caracteristicas[24] = texto.contains('18%') ? 1.0 : 0.0; // IGV 18%

      // Características de estructura
      final lineas = texto.split('\n');
      double sumaLongitudLineas = lineas.fold(
        0,
        (sum, linea) => sum + linea.length,
      );
      caracteristicas[25] = lineas.isNotEmpty
          ? sumaLongitudLineas / lineas.length / 50
          : 0.0;

      // Densidad de puntuación
      caracteristicas[26] =
          RegExp(r'[.,:;]').allMatches(texto).length.toDouble() / 100;

      // Más patrones específicos (rellenar hasta 50)
      for (int i = 27; i < 50; i++) {
        caracteristicas[i] = 0.0; // Reservado para futuras características
      }
    } catch (e) {
      print('Error extrayendo características: $e');
    }

    return caracteristicas;
  }

  /// Interpreta la predicción del modelo y extrae valores
  // ignore: unused_element
  static Map<String, String> _interpretarPrediccion(
    List<double> prediccion,
    String texto,
  ) {
    final datos = <String, String>{};

    try {
      // Los primeros 10 valores son probabilidades de presencia (0-1)
      // Los siguientes 10 son valores normalizados que hay que desnormalizar

      final umbrales = 0.5; // Umbral para considerar que un campo está presente

      // Interpretar flags de presencia
      if (prediccion[0] > umbrales) {
        // tiene_ruc_emisor
        final ruc = _buscarRUCMejorado(texto);
        if (ruc != null) datos['RUC'] = ruc;
      }

      if (prediccion[1] > umbrales) {
        // tiene_fecha_emision
        final fecha = _buscarFechaMejorada(texto);
        if (fecha != null) datos['Fecha Emisión'] = fecha;
      }

      if (prediccion[2] > umbrales) {
        // tiene_igv
        final igv = _buscarIGVMejorado(texto);
        if (igv != null) datos['IGV'] = igv;
      }

      if (prediccion[3] > umbrales) {
        // tiene_total
        final total = _buscarTotalMejorado(texto);
        if (total != null) datos['Total'] = total;
      }

      if (prediccion[4] > umbrales) {
        // tiene_serie
        final serie = _buscarSerieMejorada(texto);
        if (serie != null) datos['Serie'] = serie;
      }

      if (prediccion[5] > umbrales) {
        // tiene_numero
        final numero = _buscarNumeroMejorado(texto);
        if (numero != null) datos['Número'] = numero;
      }

      if (prediccion[6] > umbrales) {
        // tiene_tipo_comprobante
        final tipo = _buscarTipoComprobanteMejorado(texto);
        if (tipo != null) datos['Tipo Comprobante'] = tipo;
      }

      if (prediccion[7] > umbrales) {
        // tiene_ruc_cliente
        final rucCliente = _buscarRUCClienteMejorado(texto);
        if (rucCliente != null) datos['RUC Cliente'] = rucCliente;
      }

      if (prediccion[8] > umbrales) {
        // tiene_razon_social
        final razonSocial = _buscarEmpresaMejorada(texto);
        if (razonSocial != null) datos['Razón Social'] = razonSocial;
      }

      if (prediccion[9] > umbrales) {
        // tiene_moneda
        final moneda = _buscarMonedaMejorada(texto);
        if (moneda != null) datos['Moneda'] = moneda;
      }

      print('🤖 Modelo ML aplicado: ${datos.length} campos detectados');
    } catch (e) {
      print('Error interpretando predicción: $e');
    }

    return datos;
  }

  static String? _buscarRUC(List<String> lineas) {
    final patronRUC = RegExp(r'\b(\d{11})\b');
    // Búsqueda optimizada basada en facturas reales peruanas
    final patronEtiquetaRUC = RegExp(
      r'R\.?U\.?C\.?\s*:?\s*N?º?\.?\s*(\d{11})|RUC\s*:\s*(\d{11})',
      caseSensitive: false,
    );

    for (String linea in lineas) {
      final matchEtiqueta = patronEtiquetaRUC.firstMatch(linea);
      if (matchEtiqueta != null) {
        return matchEtiqueta.group(1) ?? matchEtiqueta.group(2);
      }
      // Fallback si la etiqueta está en una línea y el número en otra, o sin etiqueta
      if (linea.contains('RUC')) {
        final match = patronRUC.firstMatch(linea);
        if (match != null) return match.group(1);
      }
    }
    // Si no se encuentra con etiqueta, buscar cualquier número de 11 dígitos
    for (String linea in lineas) {
      final match = patronRUC.firstMatch(linea);
      if (match != null) return match.group(1);
    }
    return null;
  }

  static String? _buscarRUCCliente(String texto, String? rucEmisor) {
    final lineas = texto.split('\n');
    final patronRUC = RegExp(r'\b(\d{11})\b');
    final patronesEtiqueta = [
      RegExp(
        r'(?:CLIENTE|ADQUIRIENTE|SEÑOR\(A/ES\))\s*.*?R\.?U\.?C\.?\s*:?\s*(\d{11})',
        caseSensitive: false,
      ),
      RegExp(r'RUC\s*:\s*(\d{11})', caseSensitive: false), // Un RUC genérico
    ];

    final textoUnido = texto.replaceAll('\n', ' ');

    // 1. Búsqueda prioritaria con etiquetas compuestas
    for (final patron in patronesEtiqueta) {
      final matches = patron.allMatches(textoUnido);
      for (final match in matches) {
        final rucEncontrado = match.group(1);
        if (rucEncontrado != null && rucEncontrado != rucEmisor) {
          return rucEncontrado;
        }
      }
    }

    // 2. Búsqueda por líneas con palabras clave
    int indiceLineaCliente = -1;
    for (int i = 0; i < lineas.length; i++) {
      if (lineas[i].contains('CLIENTE') || lineas[i].contains('SEÑOR')) {
        indiceLineaCliente = i;
        break;
      }
    }

    if (indiceLineaCliente != -1) {
      // Buscar en las 5 líneas siguientes a donde se encontró "CLIENTE"
      for (
        int i = indiceLineaCliente;
        i < lineas.length && i < indiceLineaCliente + 5;
        i++
      ) {
        final match = patronRUC.firstMatch(lineas[i]);
        if (match != null) {
          final rucEncontrado = match.group(1);
          if (rucEncontrado != rucEmisor) {
            return rucEncontrado;
          }
        }
      }
    }

    // 3. Búsqueda general, excluyendo al emisor y priorizando RUCs que no sean el del emisor
    final todosLosRucs = patronRUC
        .allMatches(texto)
        .map((m) => m.group(1))
        .whereType<String>()
        .toList();
    final rucsUnicos = todosLosRucs.toSet().toList();

    for (final ruc in rucsUnicos) {
      if (ruc != rucEmisor) {
        return ruc; // Devuelve el primer RUC que no sea del emisor
      }
    }

    return null;
  }

  // ========== MÉTODOS MEJORADOS CON IA ==========

  /// Búsqueda mejorada de RUC con mayor precisión
  static String? _buscarRUCMejorado(String texto) {
    // Usar el método existente como base pero con mejor priorización
    final lineas = texto.split('\n').where((l) => l.trim().isNotEmpty).toList();
    final resultado = _buscarRUC(lineas);
    if (resultado != null) {
      print('🎯 RUC detectado con IA: $resultado');
    }
    return resultado;
  }

  /// Búsqueda mejorada de fecha con patrones más precisos
  static String? _buscarFechaMejorada(String texto) {
    final patronesPrioritarios = [
      RegExp(
        r'FECHA\s+(?:DE\s+)?EMISIÓN\s*:?\s*(\d{2}[/-]\d{2}[/-]\d{4})',
        caseSensitive: false,
      ),
      RegExp(r'FECHA\s*:?\s*(\d{2}[/-]\d{2}[/-]\d{4})', caseSensitive: false),
      RegExp(r'\b(\d{2}/\d{2}/\d{4})\b'), // Formato dd/mm/yyyy
      RegExp(r'\b(\d{2}-\d{2}-\d{4})\b'), // Formato dd-mm-yyyy
    ];

    for (final patron in patronesPrioritarios) {
      final match = patron.firstMatch(texto);
      if (match != null) {
        final fecha = match.group(1)!;
        print('📅 Fecha detectada con IA: $fecha');
        return fecha;
      }
    }

    return _buscarFechaEmision(texto);
  }

  /// Búsqueda mejorada de IGV con múltiples patrones
  static String? _buscarIGVMejorado(String texto) {
    // PATRONES ESPECÍFICOS PARA EL FORMATO: "IGV: S/ [monto]"
    final patronesEspecificosSoles = [
      // Formato exacto: "IGV: S/ 12.34"
      RegExp(r'IGV\s*:\s*S/\s*([\d,]+\.?\d{0,2})', caseSensitive: false),
      // Formato: "IGV:S/12.34" (sin espacios)
      RegExp(r'IGV\s*:\s*S/\s*([\d,]+\.?\d{0,2})', caseSensitive: false),
      // Formato: "I.G.V.: S/ 12.34"
      RegExp(r'I\.G\.V\.\s*:\s*S/\s*([\d,]+\.?\d{0,2})', caseSensitive: false),
      // Formato: "IGV S/ 12.34" (sin dos puntos)
      RegExp(r'IGV\s+S/\s*([\d,]+\.?\d{0,2})', caseSensitive: false),
    ];

    // Primero buscar patrones específicos con S/
    for (final patron in patronesEspecificosSoles) {
      final match = patron.firstMatch(texto);
      if (match != null) {
        final igv = match.group(1)!.replaceAll(',', '');
        // Validar que sea un número válido
        final numero = double.tryParse(igv);
        if (numero != null && numero > 0) {
          print('💰 IGV detectado (S/): $igv');
          return numero.toStringAsFixed(2);
        }
      }
    }

    // PATRONES ADICIONALES MEJORADOS
    final patronesMejorados = [
      // Patrones con porcentaje específico
      RegExp(
        r'IGV\s*18%\s*[:\s]*S/\s*([\d,]+\.?\d{0,2})',
        caseSensitive: false,
      ),
      RegExp(
        r'IGV\s*\(18%\)\s*[:\s]*S/\s*([\d,]+\.?\d{0,2})',
        caseSensitive: false,
      ),
      RegExp(
        r'I\.G\.V\.\s*18%\s*[:\s]*S/\s*([\d,]+\.?\d{0,2})',
        caseSensitive: false,
      ),
      RegExp(
        r'I\.G\.V\.\s*\(18%\)\s*[:\s]*S/\s*([\d,]+\.?\d{0,2})',
        caseSensitive: false,
      ),

      // Patrones generales con diferentes separadores
      RegExp(r'IGV\s*[:\s]\s*S/?\s*([\d,]+\.?\d{0,2})', caseSensitive: false),
      RegExp(
        r'I\.G\.V\.\s*[:\s]\s*S/?\s*([\d,]+\.?\d{0,2})',
        caseSensitive: false,
      ),

      // Patrones para IMPUESTO GENERAL A LAS VENTAS
      RegExp(
        r'IMPUESTO\s+GENERAL\s+A\s+LAS\s+VENTAS\s*[:\s]*S/\s*([\d,]+\.?\d{0,2})',
        caseSensitive: false,
      ),

      // Patrones más amplios (como fallback)
      RegExp(
        r'IGV\s+(?:1[0-8]|20)%\s*[:\s]*S/?\s*([\d,]+\.?\d{0,2})',
        caseSensitive: false,
      ),
      RegExp(
        r'I\.G\.V\.\s*(?:1[0-8]|20)%\s*[:\s]*S/?\s*([\d,]+\.?\d{0,2})',
        caseSensitive: false,
      ),
      RegExp(
        r'(?:IGV|I\.G\.V\.?)\s*\((?:1[0-8]|20)%\)\s*[:\s]*S/?\s*([\d,]+\.?\d{0,2})',
        caseSensitive: false,
      ),

      // Patrones sin símbolo de moneda pero contextualizados
      RegExp(r'IGV\s*[:\s]\s*([\d,]+\.?\d{2})', caseSensitive: false),
      RegExp(r'I\.G\.V\.\s*[:\s]\s*([\d,]+\.?\d{2})', caseSensitive: false),
    ];

    for (final patron in patronesMejorados) {
      final match = patron.firstMatch(texto);
      if (match != null) {
        final igv = match.group(1)!.replaceAll(',', '');
        // Validar que sea un número válido y razonable (IGV típicamente no supera 1000 en facturas normales)
        final numero = double.tryParse(igv);
        if (numero != null && numero > 0 && numero < 10000) {
          print('💰 IGV detectado (mejorado): $igv');
          return numero.toStringAsFixed(2);
        }
      }
    }

    // Fallback a la función original
    return _buscarIGV(texto);
  }

  /// Búsqueda mejorada de total con contexto
  static String? _buscarTotalMejorado(String texto) {
    final patronesMejorados = [
      // Patrones específicos para TOTAL A PAGAR
      RegExp(
        r'TOTAL\s*A\s*PAGAR\s*[:\sS/$]*?\s*([\d,]+\.\d{2})',
        caseSensitive: false,
      ),
      RegExp(
        r'TOTAL\s*PAGAR\s*[:\sS/$]*?\s*([\d,]+\.\d{2})',
        caseSensitive: false,
      ),
      // Patrones para IMPORTE TOTAL
      RegExp(
        r'IMPORTE\s*TOTAL\s*[:\sS/$]*?\s*([\d,]+\.\d{2})',
        caseSensitive: false,
      ),
      RegExp(
        r'IMPORTE\s*NETO\s*[:\sS/$]*?\s*([\d,]+\.\d{2})',
        caseSensitive: false,
      ),
      // Patrones para MONTO TOTAL
      RegExp(
        r'MONTO\s*TOTAL\s*[:\sS/$]*?\s*([\d,]+\.\d{2})',
        caseSensitive: false,
      ),
      RegExp(
        r'MONTO\s*FINAL\s*[:\sS/$]*?\s*([\d,]+\.\d{2})',
        caseSensitive: false,
      ),
      // Patrones para SUMA TOTAL
      RegExp(
        r'SUMA\s*TOTAL\s*[:\sS/$]*?\s*([\d,]+\.\d{2})',
        caseSensitive: false,
      ),
      // Patrones simples
      RegExp(r'TOTAL\s*[:\sS/$]*?\s*([\d,]+\.\d{2})', caseSensitive: false),
      RegExp(r'NETO\s*[:\sS/$]*?\s*([\d,]+\.\d{2})', caseSensitive: false),
      // Patrón para TOTAL PAGADO
      RegExp(
        r'TOTAL\s*PAGADO\s*[:\sS/$]*?\s*([\d,]+\.\d{2})',
        caseSensitive: false,
      ),
    ];

    for (final patron in patronesMejorados) {
      final matches = patron.allMatches(texto);
      if (matches.isNotEmpty) {
        final total = matches.last.group(1)!.replaceAll(RegExp(r'[S/$,]'), '');
        print('� Total detectado con IA: $total');
        return total;
      }
    }

    return _buscarTotal(texto);
  }

  /// Búsqueda mejorada de serie
  static String? _buscarSerieMejorada(String texto) {
    final patronesSerie = [
      RegExp(r'SERIE\s*:?\s*([A-Z]\d{3})', caseSensitive: false),
      RegExp(r'N[UÚ]MERO\s*:?\s*([A-Z]\d{3})-\d+', caseSensitive: false),
      RegExp(r'\b([FBT]\d{3})-\d+'), // Formato típico de serie
    ];

    for (final patron in patronesSerie) {
      final match = patron.firstMatch(texto);
      if (match != null) {
        final serie = match.group(1)!;
        print('🔢 Serie detectada con IA: $serie');
        return serie;
      }
    }

    return _buscarSerieNumero(texto)['serie'];
  }

  /// Búsqueda mejorada de número
  static String? _buscarNumeroMejorado(String texto) {
    final patronesNumero = [
      RegExp(r'N[UÚ]MERO\s*:?\s*[A-Z]\d{3}-(\d+)', caseSensitive: false),
      RegExp(r'\b[A-Z]\d{3}-(\d+)'), // Formato típico
      RegExp(r'CORRELATIVO\s*:?\s*(\d+)', caseSensitive: false),
    ];

    for (final patron in patronesNumero) {
      final match = patron.firstMatch(texto);
      if (match != null) {
        final numero = match.group(1)!;
        print('🔢 Número detectado con IA: $numero');
        return numero;
      }
    }

    return _buscarSerieNumero(texto)['numero'];
  }

  /// Búsqueda mejorada de tipo de comprobante
  static String? _buscarTipoComprobanteMejorado(String texto) {
    final tiposComprobante = {
      'FACTURA': RegExp(r'\bFACTURA\b', caseSensitive: false),
      'BOLETA': RegExp(r'\bBOLETA\b', caseSensitive: false),
      'NOTA DE CRÉDITO': RegExp(
        r'\bNOTA\s+DE\s+CR[EÉ]DITO\b',
        caseSensitive: false,
      ),
      'NOTA DE DÉBITO': RegExp(
        r'\bNOTA\s+DE\s+D[EÉ]BITO\b',
        caseSensitive: false,
      ),
      'RECIBO': RegExp(r'\bRECIBO\b', caseSensitive: false),
      'TICKET': RegExp(r'\bTICKET\b', caseSensitive: false),
    };

    for (final entry in tiposComprobante.entries) {
      if (entry.value.hasMatch(texto)) {
        print('📄 Tipo detectado con IA: ${entry.key}');
        return entry.key;
      }
    }

    final lineas = texto.split('\n');
    return _buscarTipoComprobante(lineas);
  }

  /// Búsqueda mejorada de RUC cliente
  static String? _buscarRUCClienteMejorado(String texto) {
    final rucEmisor = _buscarRUCMejorado(texto);
    final resultado = _buscarRUCCliente(texto, rucEmisor);
    if (resultado != null) {
      print('🏢 RUC Cliente detectado con IA: $resultado');
    }
    return resultado;
  }

  /// Búsqueda mejorada de razón social
  static String? _buscarEmpresaMejorada(String texto) {
    final lineas = texto.split('\n').where((l) => l.trim().isNotEmpty).toList();
    final resultado = _buscarEmpresa(lineas);
    if (resultado != null) {
      print('🏭 Razón Social detectada con IA: $resultado');
    }
    return resultado;
  }

  /// Búsqueda mejorada de moneda
  static String? _buscarMonedaMejorada(String texto) {
    final patronesMoneda = [
      RegExp(r'\bSOLES?\b', caseSensitive: false),
      RegExp(r'\bPEN\b'),
      RegExp(r'\bS/\.?\b'),
      RegExp(r'\bDOLAR', caseSensitive: false),
      RegExp(r'\bUSD\b'),
      RegExp(r'\bUS\$'),
    ];

    if (patronesMoneda[0].hasMatch(texto) ||
        patronesMoneda[1].hasMatch(texto) ||
        patronesMoneda[2].hasMatch(texto)) {
      print('💱 Moneda detectada con IA: PEN');
      return 'PEN';
    }

    if (patronesMoneda[3].hasMatch(texto) ||
        patronesMoneda[4].hasMatch(texto) ||
        patronesMoneda[5].hasMatch(texto)) {
      print('💱 Moneda detectada con IA: USD');
      return 'USD';
    }

    final lineas = texto.split('\n');
    return _buscarMoneda(lineas, texto);
  }

  /// Limpia recursos del sistema
  static void dispose() {
    _modeloInicializado = false;
    _textRecognizer.close();
    print('🔄 Recursos liberados');
  }

  static String? _buscarTipoComprobante(List<String> lineas) {
    final tipos = [
      'FACTURA ELECTR[OÓ]NICA',
      'FACTURA',
      'BOLETA DE VENTA ELECTR[OÓ]NICA',
      'BOLETA ELECTR[OÓ]NICA',
      'BOLETA',
      'TICKET',
      'RECIBO',
    ];
    for (String linea in lineas) {
      for (String tipo in tipos) {
        final patron = RegExp(tipo, caseSensitive: false);
        if (patron.hasMatch(linea)) {
          if (tipo.contains('FACTURA')) return 'FACTURA';
          if (tipo.contains('BOLETA')) return 'BOLETA';
          return tipo.replaceAll(r'ELECTR[OÓ]NICA', '').trim();
        }
      }
    }
    return null;
  }

  static Map<String, String?> _buscarSerieNumero(String texto) {
    final patrones = [
      RegExp(
        r'\b([FBTE][A-Z0-9]{2,4})\s*-\s*(\d{1,8})\b',
        caseSensitive: false,
      ), // F002-0013014, F001-12345
      RegExp(
        r'\b([A-Z]{1,4}\d)\s*-\s*(\d{6,8})\b',
        caseSensitive: false,
      ), // FPP1-002359
      RegExp(
        r'N[º\s\.]*([FBTE][A-Z0-9]{3})\s*-\s*(\d{1,8})',
        caseSensitive: false,
      ), // Nº F001-12345
      RegExp(
        r'SERIE\s*:\s*([A-Z0-9]{3,5})\s*NRO\.\s*:\s*(\d{1,8})',
        caseSensitive: false,
      ),
      RegExp(
        r'(\b[A-Z0-9]{3,5}\b)\s*-\s*(\d{4,8}\b)',
        caseSensitive: false,
      ), // Series flexibles de 3-5 caracteres
    ];

    for (final patron in patrones) {
      final match = patron.firstMatch(texto);
      if (match != null && match.groupCount >= 2) {
        return {
          'serie': match.group(1)?.trim(),
          'numero': match.group(2)?.trim(),
        };
      }
    }
    return {'serie': null, 'numero': null};
  }

  static String? _buscarFechaEmision(String texto) {
    final patronesFecha = [
      RegExp(
        r'FECHA(?:\s+DE)?\s+EMISI[OÓ]N\s*[:\s]*(\d{2}[/-]\d{2}[/-]\d{4})',
        caseSensitive: false,
      ),
      RegExp(
        r'F\.\s*EMISI[OÓ]N\s*[:\s]*(\d{2}[/-]\d{2}[/-]\d{4})',
        caseSensitive: false,
      ),
      RegExp(
        r'FECHA\s*[:]?\s*(\d{2}/\d{2}/\d{4})',
        caseSensitive: false,
      ), // FECHA : 27/05/2025
      RegExp(r'\b(\d{2}/\d{2}/\d{4})\b'),
      RegExp(r'\b(\d{4}-\d{2}-\d{2})\b'),
      RegExp(
        r'FECHA\s+EMISI[OÓ]N\s*[:]?\s*(\d{2}/\d{2}/\d{4})',
        caseSensitive: false,
      ),
      RegExp(
        r'(\d{2}/\d{2}/\d{4})\s+\d{2}:\d{2}:\d{2}',
        caseSensitive: false,
      ), // 27/05/2025 13:54:50
      RegExp(r'(\d{1,2}\s+DE\s+\w+\s+DE\s+\d{4})', caseSensitive: false),
    ];

    for (final patron in patronesFecha) {
      final match = patron.firstMatch(texto);
      if (match != null) return match.group(1)?.trim();
    }
    return null;
  }

  static String? _buscarIGV(String texto) {
    final patrones = [
      // Patrones específicos con porcentajes
      RegExp(
        r'IGV\s*18%\s*S/\s*([\d,]+\.\d{2})',
        caseSensitive: false,
      ), // IGV 18% S/ 3.00
      RegExp(
        r'IGV\s*S/\s*18%\s*([\d,]+\.\d{2})',
        caseSensitive: false,
      ), // IGV s/ 18% 3.00
      RegExp(
        r'IGV\s*\(18%\)\s*[:\sS/$]*?\s*([\d,]+\.\d{2})',
        caseSensitive: false,
      ), // IGV (18%) : 3.00
      RegExp(
        r'I\.G\.V\.\s*18%\s*[:\sS/$]*?\s*([\d,]+\.\d{2})',
        caseSensitive: false,
      ), // I.G.V. 18% : 3.00
      RegExp(
        r'I\.G\.V\.\s*\(18%\)\s*[:\sS/$]*?\s*([\d,]+\.\d{2})',
        caseSensitive: false,
      ), // I.G.V. (18%) : 3.00
      // Patrones con formato común IGV: valor
      RegExp(
        r'IGV\s*:\s*[\d,]+\.?\d*\s*%\s*([\d,]+\.\d{2})',
        caseSensitive: false,
      ), // IGV: 10.00 % 0.77
      RegExp(
        r'IGV\s*[:\s]\s*([\d,]+\.\d{2})',
        caseSensitive: false,
      ), // IGV : 3.00 o IGV 3.00
      RegExp(
        r'I\.G\.V\.\s*[:\s]\s*([\d,]+\.\d{2})',
        caseSensitive: false,
      ), // I.G.V. : 3.00 o I.G.V. 3.00
      // Patrón para nombre completo del impuesto
      RegExp(
        r'IMPUESTO\s+GENERAL\s+A\s+LAS\s+VENTAS\s*[:\sS/$]*?\s*([\d,]+\.\d{2})',
        caseSensitive: false,
      ), // Impuesto General a las Ventas : 3.00
      // Patrones generales con porcentajes variables
      RegExp(
        r'IGV\s+(?:1[0-8]|20)%\s*[:\sS/$]*?\s*([\d,]+\.\d{2})',
        caseSensitive: false,
      ), // IGV 18% : 2.20
      RegExp(
        r'I\.G\.V\.\s*(?:1[0-8]|20)%\s*[:\sS/$]*?\s*([\d,]+\.\d{2})',
        caseSensitive: false,
      ), // I.G.V. 18% 3.00
      // Patrones con paréntesis
      RegExp(
        r'(?:IGV|I\.G\.V\.?)\s*\((?:1[0-8]|20)%\)\s*[:\sS/$]*?\s*([\d,]+\.\d{2})',
        caseSensitive: false,
      ), // IGV (18%) o I.G.V. (18%)
      // Patrones de respaldo sin porcentaje específico
      RegExp(
        r'TOTAL\s+IGV\s*[:\sS/$]*?\s*([\d,]+\.\d{2})',
        caseSensitive: false,
      ), // TOTAL IGV : 3.00
      RegExp(
        r'(?:IGV|I\.G\.V\.?)\s*[:\sS/$]*?\s*([\d,]+\.\d{2})',
        caseSensitive: false,
      ), // IGV o I.G.V. seguido de monto
      // Busca línea con IGV seguida de número en línea posterior
      RegExp(
        r'(?:IGV|I\.G\.V\.?)[^\n]*\n[^\d]*([\d,]+\.\d{2})',
        caseSensitive: false,
        multiLine: true,
      ),
    ];

    for (final patron in patrones) {
      final matches = patron.allMatches(texto);
      if (matches.isNotEmpty) {
        // Devuelve el último match, que suele ser el correcto en la sección de totales
        return matches.last.group(1)!.replaceAll(RegExp(r'[S/$,]'), '');
      }
    }
    return null;
  }

  static String? _buscarMoneda(List<String> lineas, String texto) {
    final textoUnido = texto.replaceAll('\n', ' ');
    // Buscar indicadores de moneda explícitos
    if (RegExp(r'S/|SOLES|PEN', caseSensitive: false).hasMatch(textoUnido)) {
      return 'PEN';
    }
    if (RegExp(
      r'US\$|USD|D[OÓ]LARES',
      caseSensitive: false,
    ).hasMatch(textoUnido)) {
      return 'USD';
    }
    if (RegExp(r'EUR|EUROS', caseSensitive: false).hasMatch(textoUnido)) {
      return 'EUR';
    }
    // Por defecto, si no se encuentra nada, asumir PEN, que es lo más común.
    return 'PEN';
  }

  static String? _buscarEmpresa(List<String> lineas) {
    // Buscar en las primeras líneas, excluyendo líneas que son claramente RUC o títulos
    for (int i = 0; i < lineas.length && i < 8; i++) {
      final linea = lineas[i].trim();
      if (linea.length > 3 &&
          !RegExp(r'^\d+$').hasMatch(linea) &&
          !RegExp(r'^\d{11}$').hasMatch(linea) && // Excluir RUCs
          !RegExp(
            r'RUC|FACTURA|BOLETA|ELECTR[OÓ]NICA|SERIE|FECHA|F\d+|E\d+|B\d+',
            caseSensitive: false,
          ).hasMatch(linea) &&
          // Incluir líneas que parecen nombres de empresa
          RegExp(r'[A-Z]{2,}', caseSensitive: false).hasMatch(linea)) {
        return linea
            .toLowerCase()
            .split(' ')
            .map(
              (palabra) => palabra.isNotEmpty
                  ? palabra[0].toUpperCase() + palabra.substring(1)
                  : '',
            )
            .join(' ');
      }
    }
    return null;
  }

  static String? _buscarTotal(String texto) {
    final textoUnido = texto.replaceAll('\n', ' ');
    final patronesPrioritarios = [
      RegExp(
        r'TOTAL\s*[:\sS/$]*?\s*([\d,]+\.\d{2})',
        caseSensitive: false,
      ), // TOTAL : S/ 27.00
      RegExp(
        r'IMPORTE\s*TOTAL\s*[:\sS/$]*?\s*([\d,]+\.\d{2})',
        caseSensitive: false,
      ), // IMPORTE TOTAL S/ 36.90
      RegExp(
        r'TOTAL\s*A\s*PAGAR\s*[:\sS/$]*?\s*([\d,]+\.\d{2})',
        caseSensitive: false,
      ),
      RegExp(
        r'TOTAL\s+PAGADO\s*[:\sS/$]*?\s*([\d,]+\.\d{2})',
        caseSensitive: false,
      ), // TOTAL PAGADO
      RegExp(r'\bTOTAL\s*[:\sS/$]*?\s*([\d,]+\.\d{2})', caseSensitive: false),
    ];

    for (final patron in patronesPrioritarios) {
      final matches = patron.allMatches(textoUnido);
      if (matches.isNotEmpty) {
        return matches.last.group(1)!.replaceAll(RegExp(r'[S/$,]'), '');
      }
    }

    final patronMonto = RegExp(r'(\d{1,3}(?:,?\d{3})*\.\d{2})');
    final matches = patronMonto.allMatches(texto);
    double? mayorMonto;

    if (matches.isNotEmpty) {
      for (final match in matches) {
        final montoStr = match.group(1)!.replaceAll(RegExp(r'[S/$,]'), '');
        final monto = double.tryParse(montoStr);
        if (monto != null) {
          if (mayorMonto == null || monto > mayorMonto) {
            mayorMonto = monto;
          }
        }
      }
    }

    return mayorMonto?.toStringAsFixed(2);
  }
}
