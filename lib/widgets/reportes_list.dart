// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import '../models/reporte_model.dart';
import '../screens/qr_scanner_screen.dart';
import '../screens/document_scanner_screen.dart';
import '../services/factura_ia.dart';
import 'package:intl/intl.dart';
import 'dart:io';

enum EstadoReporte { todos, borrador, enviado }

class ReportesList extends StatefulWidget {
  final List<Reporte> reportes;
  final Future<void> Function() onRefresh;
  final bool isLoading;
  final void Function(Reporte)? onTap;

  const ReportesList({
    super.key,
    required this.reportes,
    required this.onRefresh,
    this.isLoading = false,
    this.onTap,
  });

  @override
  State<ReportesList> createState() => _ReportesListState();
}

class _ReportesListState extends State<ReportesList> {
  // Función para abrir el escáner QR
  void _abrirEscaneadorQR() async {
    try {
      final String? resultado = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const QRScannerScreen()),
      );

      if (resultado != null && mounted) {
        // Aquí puedes manejar el resultado del código QR escaneado
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Código escaneado: $resultado'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Copiar',
              textColor: Colors.white,
              onPressed: () {
                // Aquí podrías copiar al portapapeles si quieres
                print('Código QR: $resultado');
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir escáner: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Función para escanear documentos con IA
  void _escanearDocumento() async {
    try {
      // Navegar a una pantalla de captura de documentos
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const DocumentScannerScreen()),
      );

      if (result != null && mounted) {
        // Si result es un File (imagen capturada), procesarlo con IA
        if (result is File) {
          _procesarFacturaConIA(result);
        } else {
          // Comportamiento original
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Documento escaneado exitosamente'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
              action: SnackBarAction(
                label: 'Ver',
                textColor: Colors.white,
                onPressed: () {
                  print('Documento escaneado: $result');
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al escanear documento: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Función para procesar factura con IA
  void _procesarFacturaConIA(File imagenFactura) async {
    // Mostrar indicador de procesamiento
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 16),
            Text('🤖 Procesando factura con IA...'),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 3),
      ),
    );

    try {
      // Extraer datos con IA
      final datosExtraidos = await FacturaIA.extraerDatos(imagenFactura);

      if (datosExtraidos.isNotEmpty && !datosExtraidos.containsKey('Error')) {
        _mostrarDatosExtraidos(datosExtraidos);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudieron extraer datos de la factura'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error procesando con IA: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Función para mostrar los datos extraídos
  void _mostrarDatosExtraidos(Map<String, String> datos) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.psychology, color: Colors.green),
              SizedBox(width: 8),
              Text('🤖 Datos Extraídos por IA'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Campos detectados para el modal peruano:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 12),
                ...datos.entries
                    .map(
                      (entry) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 80,
                              child: Text(
                                '${entry.key}:',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                entry.value,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info, color: Colors.blue, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Estos datos se pueden usar automáticamente en el modal de factura peruana',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                // Aquí puedes agregar lógica para usar los datos en el modal
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '✅ ${datos.length} campos extraídos listos para usar',
                    ),
                    backgroundColor: Colors.green,
                    action: SnackBarAction(
                      label: 'Abrir Modal',
                      textColor: Colors.white,
                      onPressed: () {
                        // TODO: Aquí puedes abrir el modal con los datos pre-llenados
                        print('Datos para modal: $datos');
                      },
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.assignment),
              label: const Text('Usar en Modal'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando reportes...'),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white, // COLOR DE FONDO DE REPORTE LIST
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            const TabBar(
              labelColor: Colors.indigo,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.indigo,
              tabs: [
                Tab(text: "Todos"),
                Tab(text: "Borradores"),
                Tab(text: "Enviados"),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildList(EstadoReporte.todos),
                  _buildList(EstadoReporte.borrador),
                  _buildList(EstadoReporte.enviado),
                ],
              ),
            ),
          ],
        ),
      ),

      // 👇 FAB expandible
      floatingActionButton: SpeedDial(
        icon: Icons.add,
        activeIcon: Icons.close,
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color.fromARGB(255, 31, 98, 213),
        overlayColor: Colors.black,
        overlayOpacity: 0.5,
        spacing: 12,
        spaceBetweenChildren: 8,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.document_scanner, color: Colors.white),
            backgroundColor: Colors.green,
            label: 'Escanear + IA',
            onTap: _escanearDocumento,
          ),

          SpeedDialChild(
            child: const Icon(Icons.qr_code_scanner, color: Colors.white),
            backgroundColor: Colors.blue,
            label: 'Lector de códigos',
            onTap: _abrirEscaneadorQR,
          ),
          SpeedDialChild(
            child: const Icon(Icons.note_add, color: Colors.white),
            backgroundColor: Colors.indigo,
            label: 'Crear gasto',
            onTap: () => print('Crear gasto seleccionado'),
          ),
        ],
      ),
    );
  }

  Widget _buildList(EstadoReporte filtro) {
    List<Reporte> data;

    switch (filtro) {
      case EstadoReporte.borrador:
        data = widget.reportes
            .where((r) => r.destino?.toUpperCase() == 'B')
            .toList();
        break;
      case EstadoReporte.enviado:
        data = widget.reportes
            .where((r) => r.destino?.toUpperCase() == 'E')
            .toList();
        break;
      case EstadoReporte.todos:
        data = widget.reportes;
        break;
    }

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: data.isEmpty
          ? ListView(
              children: const [
                SizedBox(height: 100),
                Center(
                  child: Text(
                    "No hay reportes disponibles",
                    style: TextStyle(color: Colors.black, fontSize: 16),
                  ),
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: data.length,
              itemBuilder: (context, index) {
                final reporte = data[index];
                final fechaOriginal = DateTime.tryParse(reporte.fecha ?? '');
                final fechaCorta = fechaOriginal != null
                    ? DateFormat('yyyy/MM/dd').format(fechaOriginal)
                    : 'Fecha inválida';

                return GestureDetector(
                  onTap: widget.onTap != null
                      ? () => widget.onTap!(reporte)
                      : null,
                  child: Card(
                    color: Colors.white,
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header con número de reporte y estado
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${reporte.ruc} ',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                              ),
                              Text(
                                '${reporte.total} PEN',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.indigo,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${reporte.categoria} ',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black,
                                ),
                              ),
                              Chip(
                                label: Text(
                                  '${reporte.destino}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                  ),
                                ),
                                backgroundColor: _getEstadoColor(
                                  reporte.destino,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 1,
                                  vertical: 0,
                                ),
                                labelPadding: const EdgeInsets.symmetric(
                                  horizontal: 1,
                                ),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                fechaCorta,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 1),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Color? _getEstadoColor(String? estado) {
    switch (estado?.toUpperCase()) {
      case 'S':
        return Colors.green[400];
      case 'P':
        return Colors.orange[400];
      case 'E': // Enviado
        return Colors.blue[400];
      case 'B': // Borrador
        return Colors.grey[400];
      case 'C':
        return Colors.green[700];
      case 'F':
        return Colors.red[400];
      case 'SYNC':
        return Colors.teal[400];
      default:
        return Colors.grey[400];
    }
  }
}
