// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import '../controllers/reportes_list_controller.dart';
import '../models/reporte_model.dart';
import '../models/estado_reporte.dart';
import 'package:intl/intl.dart';
import 'politica_selection_modal_scan.dart';

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
  final ReportesListController _controller = ReportesListController();
  // Función para abrir el escáner QR
  void _abrirEscaneadorQR() =>
      _controller.abrirEscaneadorQR(context, () => mounted);

  void _crearGasto() => _controller.crearGasto(context, () => mounted);

  void _escanerIA() => _controller.escanerIA(context, () => mounted);

  // Función para escanear documentos con IA (el botón está inactivo)

  // Nota: la lógica adicional (procesamiento IA, navegación de políticas, etc.)
  // fue movida al controlador `ReportesListController`.

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
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: Colors.indigo,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.indigo,
              indicatorSize: TabBarIndicatorSize.tab,
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
      controller: _tabController,
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
            label: 'Escanear IA',
            onTap: _escanerIA,
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
            onTap: _crearGasto,
          ),
        ],
      ),
    );
  }

  /* 
  Widget _buildList(EstadoReporte filtro) {
    final data = _controller.filtrarReportes(widget.reportes, filtro);

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
                                backgroundColor: _controller.getEstadoColor(
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
 */

  Widget _buildList(EstadoReporte filtro) {
    final data = _controller.filtrarReportes(widget.reportes, filtro);

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: data.isEmpty
          ? ListView(
              children: const [
                SizedBox(height: 120),
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.auto_graph_rounded,
                        size: 65,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 10),
                      Text(
                        "No hay facturas registradas",
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
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
                    ? DateFormat('dd/MM/yy').format(fechaOriginal)
                    : 'Fecha inválida';

                return GestureDetector(
                  onTap: widget.onTap != null
                      ? () => widget.onTap!(reporte)
                      : null,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12.withOpacity(0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // 🔹 Icono + información
                          Expanded(
                            child: Row(
                              children: [
                                // 🔸 Ícono decorativo fuera de lo común
                                const SizedBox(width: 5),

                                // 🔸 Datos principales
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        reporte.ruc ?? '',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: Color(0xFF1E293B),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.local_offer_rounded,
                                            size: 14,
                                            color: Colors.amberAccent.shade700,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              reporte.categoria ?? '',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.black54,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_month_rounded,
                                            size: 13,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            fechaCorta,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.black45,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // 🔹 Monto + estado
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.payments_rounded,
                                    color: Color(0xFF2563EB),
                                    size: 17,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${reporte.total} PEN',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: _controller.getEstadoColor(
                                    reporte.destino,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.blur_circular_rounded,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      reporte.destino ?? '',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  // El color del estado se obtiene desde el controlador.
}
