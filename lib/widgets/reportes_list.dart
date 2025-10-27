import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import '../models/reporte_model.dart';
import '../models/dropdown_option.dart';
import '../screens/qr_scanner_screen.dart';
import '../screens/document_scanner_screen.dart';
import '../services/factura_ia.dart';
import 'politica_api_selection_modal.dart';
import 'politica_test_modal.dart';
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
  EstadoReporte _filtroActual = EstadoReporte.todos;
  final Map<EstadoReporte, String> _filtroTitles = {
    EstadoReporte.todos: 'Todos los reportes',
    EstadoReporte.borrador: 'Borradores',
    EstadoReporte.enviado: 'Reportes enviados',
  };

  // ============ LÓGICA DE NEGOCIO ============

  void _abrirEscaneadorQR() async {
    try {
      final String? resultado = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const QRScannerScreen()),
      );

      if (resultado != null && mounted) {
        _mostrarSnackBar(
          mensaje: 'Código escaneado: $resultado',
          icono: Icons.qr_code_scanner,
          color: Colors.green,
          accion: SnackBarAction(
            label: 'Copiar',
            onPressed: () => _copiarAlPortapapeles(resultado),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _mostrarSnackBar(
          mensaje: 'Error al abrir escáner: $e',
          color: Colors.red,
        );
      }
    }
  }

  void _copiarAlPortapapeles(String texto) {
    // Implementar lógica de copiado
    print('Código QR copiado: $texto');
  }

  void _crearGasto() async {
    try {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => PoliticaTestModal(
          onPoliticaSelected: (politica) {
            Navigator.pop(context);
            _continuarConPolitica(politica);
          },
          onCancel: () => Navigator.pop(context),
        ),
      );
    } catch (e) {
      _mostrarSnackBar(
        mensaje: 'Error al abrir selección de política: $e',
        color: Colors.red,
      );
    }
  }

  void _continuarConPolitica(DropdownOption politica) {
    _mostrarSnackBar(
      mensaje: 'Política seleccionada: ${politica.value}',
      icono: Icons.check_circle,
      color: Colors.indigo,
      accion: SnackBarAction(
        label: 'Continuar',
        onPressed: () => _navegarSegunPolitica(politica),
      ),
    );
  }

  void _navegarSegunPolitica(DropdownOption politica) {
    // TODO: Implementar navegación específica según la política
    print('Navegando con política: ${politica.value}');
  }

  void _escanearDocumento() async {
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const DocumentScannerScreen()),
      );

      if (result is File && mounted) {
        _procesarFacturaConIA(result);
      }
    } catch (e) {
      _mostrarSnackBar(
        mensaje: 'Error al escanear documento: $e',
        color: Colors.red,
      );
    }
  }

  void _procesarFacturaConIA(File imagenFactura) async {
    _mostrarSnackBar(
      mensaje: 'Procesando factura con IA...',
      icono: Icons.psychology,
      color: Colors.blue,
      duracion: const Duration(seconds: 5),
    );

    try {
      final datosExtraidos = await FacturaIA.extraerDatos(imagenFactura);

      if (datosExtraidos.isNotEmpty && !datosExtraidos.containsKey('Error')) {
        _mostrarDatosExtraidos(datosExtraidos);
      } else {
        _mostrarSnackBar(
          mensaje: 'No se pudieron extraer datos de la factura',
          color: Colors.orange,
        );
      }
    } catch (e) {
      _mostrarSnackBar(
        mensaje: 'Error procesando con IA: $e',
        color: Colors.red,
      );
    }
  }

  void _mostrarDatosExtraidos(Map<String, String> datos) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.psychology, color: Colors.green),
              SizedBox(width: 8),
              Text('Datos Extraídos por IA'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Campos detectados:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...datos.entries.map((entry) => _buildDatoItem(entry)),
                const SizedBox(height: 8),
                _buildInfoBox(),
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
                _usarDatosEnModal(datos);
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

  Widget _buildDatoItem(MapEntry<String, String> entry) {
    return Container(
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
                color: Colors.green,
              ),
            ),
          ),
          Expanded(child: Text(entry.value)),
        ],
      ),
    );
  }

  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Row(
        children: [
          Icon(Icons.info, color: Colors.blue, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Estos datos se pueden usar automáticamente en el modal de factura',
              style: TextStyle(fontSize: 12, color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  void _usarDatosEnModal(Map<String, String> datos) {
    _mostrarSnackBar(
      mensaje: '${datos.length} campos extraídos listos para usar',
      icono: Icons.check_circle,
      color: Colors.green,
      accion: SnackBarAction(
        label: 'Abrir Modal',
        onPressed: () {
          // TODO: Abrir modal con los datos
        },
      ),
    );
  }

  void _mostrarSnackBar({
    required String mensaje,
    IconData? icono,
    required Color color,
    SnackBarAction? accion,
    Duration duracion = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icono != null) ...[
              Icon(icono, color: Colors.white),
              const SizedBox(width: 8),
            ],
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: color,
        duration: duracion,
        action: accion,
      ),
    );
  }

  // ============ LÓGICA DE FILTRADO ============

  List<Reporte> _filtrarReportes(EstadoReporte filtro) {
    switch (filtro) {
      case EstadoReporte.borrador:
        return widget.reportes
            .where((r) => r.destino?.toUpperCase() == 'B')
            .toList();
      case EstadoReporte.enviado:
        return widget.reportes
            .where((r) => r.destino?.toUpperCase() == 'E')
            .toList();
      case EstadoReporte.todos:
      default:
        return widget.reportes;
    }
  }

  // ============ UI PRINCIPAL ============

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(_filtroTitles[_filtroActual]!),
        backgroundColor: Colors.white,
        elevation: 1,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: Colors.indigo,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.indigo,
              indicatorSize: TabBarIndicatorSize.tab,
              onTap: (index) {
                setState(() {
                  _filtroActual = EstadoReporte.values[index];
                });
              },
              tabs: const [
                Tab(text: "Todos"),
                Tab(text: "Borradores"),
                Tab(text: "Enviados"),
              ],
            ),
          ),
        ),
      ),
      body: _buildBody(),
      floatingActionButton: _buildSpeedDial(),
    );
  }

  Widget _buildBody() {
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

    return TabBarView(
      children: [
        _buildListaReportes(EstadoReporte.todos),
        _buildListaReportes(EstadoReporte.borrador),
        _buildListaReportes(EstadoReporte.enviado),
      ],
    );
  }

  Widget _buildListaReportes(EstadoReporte filtro) {
    final reportesFiltrados = _filtrarReportes(filtro);

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      backgroundColor: Colors.white,
      color: Colors.indigo,
      child: reportesFiltrados.isEmpty
          ? _buildEstadoVacio(filtro)
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: reportesFiltrados.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                return ReporteCard(
                  reporte: reportesFiltrados[index],
                  onTap: widget.onTap != null
                      ? () => widget.onTap!(reportesFiltrados[index])
                      : null,
                );
              },
            ),
    );
  }

  Widget _buildEstadoVacio(EstadoReporte filtro) {
    final Map<EstadoReporte, Map<String, dynamic>> emptyStates = {
      EstadoReporte.todos: {
        'icon': Icons.receipt_long,
        'title': 'No hay reportes disponibles',
        'subtitle': 'Crea tu primer gasto usando el botón +',
      },
      EstadoReporte.borrador: {
        'icon': Icons.drafts,
        'title': 'No hay borradores',
        'subtitle': 'Los gastos en borrador aparecerán aquí',
      },
      EstadoReporte.enviado: {
        'icon': Icons.send,
        'title': 'No hay reportes enviados',
        'subtitle': 'Los reportes enviados aparecerán aquí',
      },
    };

    final state = emptyStates[filtro]!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              state['icon'] as IconData,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 24),
            Text(
              state['title'] as String,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              state['subtitle'] as String,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  SpeedDial _buildSpeedDial() {
    return SpeedDial(
      icon: Icons.add,
      activeIcon: Icons.close,
      iconTheme: const IconThemeData(color: Colors.white),
      backgroundColor: Colors.indigo,
      activeBackgroundColor: Colors.indigo.shade700,
      overlayColor: Colors.black54,
      overlayOpacity: 0.4,
      spacing: 12,
      spaceBetweenChildren: 12,
      children: [
        SpeedDialChild(
          child: const Icon(Icons.document_scanner, color: Colors.white),
          backgroundColor: Colors.green.shade600,
          label: 'Escanear + IA',
          labelStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
          onTap: _escanearDocumento,
        ),
        SpeedDialChild(
          child: const Icon(Icons.qr_code_scanner, color: Colors.white),
          backgroundColor: Colors.blue.shade600,
          label: 'Lector de códigos',
          labelStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
          onTap: _abrirEscaneadorQR,
        ),
        SpeedDialChild(
          child: const Icon(Icons.note_add, color: Colors.white),
          backgroundColor: Colors.indigo.shade600,
          label: 'Crear gasto',
          labelStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
          onTap: _crearGasto,
        ),
      ],
    );
  }
}

// ============ WIDGET SEPARADO PARA EL CARD ============

class ReporteCard extends StatelessWidget {
  final Reporte reporte;
  final VoidCallback? onTap;

  const ReporteCard({super.key, required this.reporte, this.onTap});

  @override
  Widget build(BuildContext context) {
    final fechaOriginal = DateTime.tryParse(reporte.fecha ?? '');
    final fechaFormateada = fechaOriginal != null
        ? DateFormat('dd/MM/yyyy').format(fechaOriginal)
        : 'Fecha inválida';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con RUC y monto
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      reporte.ruc ?? 'Sin RUC',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${reporte.total} PEN',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Colors.indigo,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Categoría y estado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      reporte.categoria ?? 'Sin categoría',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildEstadoChip(reporte.destino),
                ],
              ),
              const SizedBox(height: 8),

              // Fecha
              Text(
                fechaFormateada,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEstadoChip(String? estado) {
    final estadoInfo = _getEstadoInfo(estado);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: estadoInfo.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        estadoInfo.texto,
        style: const TextStyle(
          fontSize: 11,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  _EstadoInfo _getEstadoInfo(String? estado) {
    switch (estado?.toUpperCase()) {
      case 'S':
        return _EstadoInfo('Sincronizado', Colors.green);
      case 'P':
        return _EstadoInfo('Pendiente', Colors.orange);
      case 'E':
        return _EstadoInfo('Enviado', Colors.blue);
      case 'B':
        return _EstadoInfo('Borrador', Colors.grey);
      case 'C':
        return _EstadoInfo('Completado', Colors.green.shade700);
      case 'F':
        return _EstadoInfo('Fallido', Colors.red);
      case 'SYNC':
        return _EstadoInfo('Sincronizando', Colors.teal);
      default:
        return _EstadoInfo('Desconocido', Colors.grey);
    }
  }
}

class _EstadoInfo {
  final String texto;
  final Color color;

  _EstadoInfo(this.texto, this.color);
}
