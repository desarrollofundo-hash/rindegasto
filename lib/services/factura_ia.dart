import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Servicio simple para extraer datos de facturas con IA
class FacturaIA {
  static final _textRecognizer = TextRecognizer();

  /// Extrae datos principales de una factura para el modal peruano
  static Future<Map<String, String>> extraerDatos(File imagen) async {
    try {
      final inputImage = InputImage.fromFile(imagen);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      final texto = recognizedText.text.toUpperCase();
      final lineas = texto
          .split('\n')
          .where((l) => l.trim().isNotEmpty)
          .toList();

      Map<String, String> datos = {};

      // Extraer todos los campos del modal peruano
      final ruc = _buscarRUC(lineas);
      if (ruc != null) datos['RUC'] = ruc;

      final rucCliente = _buscarRUCCliente(lineas);
      if (rucCliente != null) datos['RUC Cliente'] = rucCliente;

      final tipoComprobante = _buscarTipoComprobante(lineas);
      if (tipoComprobante != null) datos['Tipo Comprobante'] = tipoComprobante;

      final serie = _buscarSerie(lineas);
      if (serie != null) datos['Serie'] = serie;

      final numero = _buscarNumero(lineas);
      if (numero != null) datos['Número'] = numero;

      final fechaEmision = _buscarFechaEmision(texto);
      if (fechaEmision != null) datos['Fecha Emisión'] = fechaEmision;

      final total = _buscarTotal(lineas);
      if (total != null) datos['Total'] = total;

      final igv = _buscarIGV(lineas);
      if (igv != null) datos['IGV'] = igv;

      final moneda = _buscarMoneda(lineas, texto);
      if (moneda != null) datos['Moneda'] = moneda;

      // Campos adicionales que pueden ser útiles
      final razonSocial = _buscarEmpresa(lineas);
      if (razonSocial != null) datos['Razón Social'] = razonSocial;

      return datos;
    } catch (e) {
      print('Error en OCR: $e');
      return {'Error': 'No se pudo procesar la imagen'};
    }
  }

  static String? _buscarRUC(List<String> lineas) {
    final patronRUC = RegExp(r'\b(\d{11})\b');
    for (String linea in lineas) {
      if (linea.contains('RUC')) {
        final match = patronRUC.firstMatch(linea);
        if (match != null) return match.group(1);
      }
    }
    // Buscar cualquier número de 11 dígitos
    for (String linea in lineas) {
      final match = patronRUC.firstMatch(linea);
      if (match != null) return match.group(1);
    }
    return null;
  }

  static String? _buscarRUCCliente(List<String> lineas) {
    // El RUC del cliente puede estar en líneas que contengan "CLIENTE" o similar
    final patronRUC = RegExp(r'\b(\d{11})\b');
    for (String linea in lineas) {
      if (linea.contains('CLIENTE') || linea.contains('ADQUIRIENTE')) {
        final match = patronRUC.firstMatch(linea);
        if (match != null) return match.group(1);
      }
    }
    return null;
  }

  static String? _buscarTipoComprobante(List<String> lineas) {
    final tipos = [
      'FACTURA ELECTRONICA',
      'FACTURA',
      'BOLETA ELECTRONICA',
      'BOLETA',
      'TICKET',
      'RECIBO',
    ];
    for (String linea in lineas) {
      for (String tipo in tipos) {
        if (linea.contains(tipo)) {
          // Simplificar el tipo
          if (tipo.contains('FACTURA')) return 'FACTURA';
          if (tipo.contains('BOLETA')) return 'BOLETA';
          return tipo;
        }
      }
    }
    return null;
  }

  static String? _buscarSerie(List<String> lineas) {
    // Buscar patrones como F001, B001, E001, etc.
    final patronSerie = RegExp(r'\b([A-Z]\d{3})\b');
    for (String linea in lineas) {
      final match = patronSerie.firstMatch(linea);
      if (match != null) {
        return match.group(1);
      }
    }

    // Buscar solo números de serie
    final patronSerieNum = RegExp(r'\b(\d{3})\b');
    for (String linea in lineas) {
      if (linea.contains('SERIE') || linea.contains('SER')) {
        final match = patronSerieNum.firstMatch(linea);
        if (match != null) {
          return match.group(1);
        }
      }
    }
    return null;
  }

  static String? _buscarNumero(List<String> lineas) {
    // Buscar patrones como F001-123456 o directamente números de 6-8 dígitos
    final patronCompleto = RegExp(r'[A-Z]?\d{3}-(\d+)');
    for (String linea in lineas) {
      final match = patronCompleto.firstMatch(linea);
      if (match != null) {
        return match.group(1);
      }
    }

    // Buscar números largos que podrían ser el número del comprobante
    final patronNumero = RegExp(r'\b(\d{6,8})\b');
    for (String linea in lineas) {
      if (linea.contains('NUMERO') ||
          linea.contains('NUM') ||
          linea.contains('Nº')) {
        final match = patronNumero.firstMatch(linea);
        if (match != null) {
          return match.group(1);
        }
      }
    }
    return null;
  }

  static String? _buscarFechaEmision(String texto) {
    final patronesFecha = [
      RegExp(r'\b(\d{1,2}[/-]\d{1,2}[/-]\d{4})\b'),
      RegExp(r'\b(\d{4}[/-]\d{1,2}[/-]\d{1,2})\b'),
      RegExp(r'\b(\d{1,2}\s+DE\s+\w+\s+DE\s+\d{4})\b'),
    ];

    // Buscar en líneas que contengan palabras relacionadas con fecha
    final lineas = texto.split('\n');
    for (String linea in lineas) {
      if (linea.contains('FECHA') ||
          linea.contains('EMISION') ||
          linea.contains('EMISIÓN')) {
        for (RegExp patron in patronesFecha) {
          final match = patron.firstMatch(linea);
          if (match != null) return match.group(1);
        }
      }
    }

    // Buscar en todo el texto
    for (RegExp patron in patronesFecha) {
      final match = patron.firstMatch(texto);
      if (match != null) return match.group(1);
    }
    return null;
  }

  static String? _buscarIGV(List<String> lineas) {
    final patronMonto = RegExp(r'(\d{1,3}(?:,\d{3})*(?:\.\d{2})?)');
    for (String linea in lineas) {
      if (linea.contains('IGV') ||
          linea.contains('I.G.V') ||
          linea.contains('IMPUESTO')) {
        final match = patronMonto.firstMatch(linea);
        if (match != null) {
          return match.group(1);
        }
      }
    }
    return null;
  }

  static String? _buscarMoneda(List<String> lineas, String texto) {
    // Buscar indicadores de moneda
    if (texto.contains('S/') ||
        texto.contains('SOLES') ||
        texto.contains('PEN')) {
      return 'PEN';
    }
    if (texto.contains('USD') ||
        texto.contains('DOLARES') ||
        texto.contains('US\$')) {
      return 'USD';
    }
    if (texto.contains('EUR') || texto.contains('EUROS')) {
      return 'EUR';
    }
    // Por defecto, asumir soles peruanos
    return 'PEN';
  }

  static String? _buscarEmpresa(List<String> lineas) {
    for (int i = 0; i < lineas.length && i < 5; i++) {
      final linea = lineas[i];
      if (linea.length > 8 &&
          !RegExp(r'^\d+$').hasMatch(linea) &&
          !linea.contains('RUC') &&
          !linea.contains('FACTURA') &&
          !linea.contains('BOLETA')) {
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

  static String? _buscarTotal(List<String> lineas) {
    final patronMonto = RegExp(r'(\d{1,3}(?:,\d{3})*(?:\.\d{2})?)');
    double? mayorMonto;
    String? mayorMontoStr;

    for (String linea in lineas) {
      if (linea.contains('TOTAL') && !linea.contains('SUBTOTAL')) {
        final match = patronMonto.firstMatch(linea);
        if (match != null) {
          final montoStr = match.group(1)!.replaceAll(',', '');
          final monto = double.tryParse(montoStr);
          if (monto != null && (mayorMonto == null || monto > mayorMonto)) {
            mayorMonto = monto;
            mayorMontoStr = match.group(1);
          }
        }
      }
    }

    if (mayorMontoStr != null) return mayorMontoStr;

    // Si no encuentra, buscar el monto más grande
    for (String linea in lineas) {
      final match = patronMonto.firstMatch(linea);
      if (match != null) {
        final montoStr = match.group(1)!.replaceAll(',', '');
        final monto = double.tryParse(montoStr);
        if (monto != null &&
            monto > 10 &&
            (mayorMonto == null || monto > mayorMonto)) {
          mayorMonto = monto;
          mayorMontoStr = match.group(1);
        }
      }
    }

    return mayorMontoStr;
  }

  static void dispose() {
    _textRecognizer.close();
  }
}
