import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/factura_data.dart';
import '../widgets/factura_modal_peru_evid.dart';

/// Modal alternativo que recibe datos extraídos por OCR y muestra
/// una versión prellenada del modal de factura peruana.
class FacturaModalPeruOCR extends StatelessWidget {
  final Map<String, String> ocrData;
  final File? evidenciaFile;
  final String politicaSeleccionada;
  final void Function(FacturaData, String?) onSave;
  final VoidCallback onCancel;

  const FacturaModalPeruOCR({
    super.key,
    required this.ocrData,
    this.evidenciaFile,
    required this.politicaSeleccionada,
    required this.onSave,
    required this.onCancel,
  });

  /// Helper para convertir el mapa OCR a FacturaData compatible
  FacturaData _facturaFromOcr() {
    final ruc = ocrData['RUC Emisor'] ?? ocrData['RUC'] ?? '';
    final tipo = ocrData['Tipo Comprobante'] ?? '';
    final serie = ocrData['Serie'] ?? '';
    final numero = ocrData['Número'] ?? ocrData['Numero'] ?? '';
    final codigo = ocrData['Código'] ?? '';
    final fecha = ocrData['Fecha'] ?? ocrData['Fecha Emisión'] ?? '';
    double? total;
    if (ocrData['Total'] != null) {
      total = double.tryParse(
        ocrData['Total']!.replaceAll(',', '').replaceAll(' ', ''),
      );
    }
    final moneda = ocrData['Moneda'] ?? 'PEN';
    final rucCliente = ocrData['RUC Cliente'] ?? '';

    return FacturaData(
      ruc: ruc.isEmpty ? null : ruc,
      tipoComprobante: tipo.isEmpty ? null : tipo,
      serie: serie.isEmpty ? null : serie,
      numero: numero.isEmpty ? null : numero,
      codigo: codigo.isEmpty ? null : codigo,
      fechaEmision: fecha.isEmpty ? null : fecha,
      total: total,
      moneda: moneda,
      rucCliente: rucCliente.isEmpty ? null : rucCliente,
      rawData: ocrData['raw_text'] ?? ocrData.toString(),
      format: BarcodeFormat.unknown,
    );
  }

  @override
  Widget build(BuildContext context) {
    final factura = _facturaFromOcr();

    return FacturaModalPeruEvid(
      facturaData: factura,
      selectedFile: evidenciaFile,
      politicaSeleccionada: politicaSeleccionada,
      onSave: onSave,
      onCancel: onCancel,
    );
  }
}
