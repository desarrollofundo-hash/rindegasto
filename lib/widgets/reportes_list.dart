// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import '../models/reporte_model.dart';
import '../screens/qr_scanner_screen.dart';
import '../screens/document_scanner_screen.dart';
import 'package:intl/intl.dart';

enum EstadoReporte { todos, borrador, enviado }

class ReportesList extends StatefulWidget {
  final List<Reporte> reportes;
  final Future<void> Function() onRefresh;
  final bool isLoading;

  const ReportesList({
    super.key,
    required this.reportes,
    required this.onRefresh,
    this.isLoading = false,
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

  // Función para escanear documentos
  void _escanearDocumento() async {
    try {
      // Navegar a una pantalla de captura de documentos
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const DocumentScannerScreen()),
      );

      if (result != null && mounted) {
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
        backgroundColor: Colors.indigo,
        overlayColor: Colors.black,
        overlayOpacity: 0.5,
        spacing: 12,
        spaceBetweenChildren: 8,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.document_scanner, color: Colors.white),
            backgroundColor: Colors.green,
            label: 'Escanear',
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

                return Card(
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
                              backgroundColor: _getEstadoColor(reporte.destino),
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
