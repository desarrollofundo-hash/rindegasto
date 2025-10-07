import 'package:flutter/material.dart';
import '../models/reporte_informe_model.dart';
import '../models/reporte_informe_detalle.dart';
import '../services/api_service.dart';
import 'editar_informe_modal.dart';

class InformeDetalleModal extends StatefulWidget {
  final ReporteInforme informe;

  const InformeDetalleModal({super.key, required this.informe});

  @override
  State<InformeDetalleModal> createState() => _InformeDetalleModalState();
}

class _InformeDetalleModalState extends State<InformeDetalleModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ReporteInformeDetalle> _detalles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDetalles();
  }

  Future<void> _loadDetalles() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('🚀 Iniciando carga de detalles...');
      print('📊 Informe ID: ${widget.informe.idInf}');
      print('📊 Informe Total: ${widget.informe.total}');
      print('📊 Informe Cantidad: ${widget.informe.cantidad}');

      // Intentar llamar al API primero
      final apiService = ApiService();
      List<ReporteInforme> reportesInforme = [];

      /*  try {
        reportesInforme = await apiService.getReportesRendicionInforme_Detalle(
          idrend: widget.informe.idInf.toString(),
        );
        print('🔍 API Response: ${reportesInforme.length} items received');
      } catch (apiError) {
        print('⚠️ API Error: $apiError');
        // Si el API falla, crear datos mock basados en el informe
        print('� Creando datos mock para testing...');
      }
 */
      List<ReporteInformeDetalle> detallesConvertidos = [];

      if (reportesInforme.isNotEmpty) {
        // Usar datos reales del API
        detallesConvertidos = reportesInforme.map((reporte) {
          return ReporteInformeDetalle(
            id: reporte.idInf,
            idinf: widget.informe.idInf,
            idrend: reporte.idInf,
            iduser: reporte.idUser,
            obs: reporte.obs,
            estadoactual: reporte.estadoActual,
            estado: reporte.estado,
            feccre: reporte.fecCre,
            politica: reporte.politica,
            categoria: 'GENERAL',
            tipogasto: 'GASTO',
            ruc: reporte.ruc,
            proveedor: reporte.ruc != null && reporte.ruc!.isNotEmpty
                ? 'Empresa RUC: ${reporte.ruc}'
                : 'Proveedor no especificado',
            tipocombrobante: 'FACTURA',
            serie: '',
            numero: '',
            igv: 0.0,
            fecha: reporte.fecCre,
            total: reporte.total,
            moneda: 'PEN',
            ruccliente: reporte.ruc,
            motivoviaje: '',
            lugarorigen: '',
            lugardestino: '',
            tipomovilidad: '',
          );
        }).toList();
      } else {
        // Crear datos mock para prueba
        for (int i = 0; i < widget.informe.cantidad; i++) {
          detallesConvertidos.add(
            ReporteInformeDetalle(
              id: widget.informe.idInf + i,
              idinf: widget.informe.idInf,
              idrend: widget.informe.idInf,
              iduser: widget.informe.idUser,
              obs: 'Gasto ${i + 1}',
              estadoactual: widget.informe.estadoActual,
              estado: widget.informe.estado,
              feccre: widget.informe.fecCre,
              politica: widget.informe.politica,
              categoria: 'GENERAL',
              tipogasto: 'GASTO',
              ruc: widget.informe.ruc,
              proveedor:
                  widget.informe.ruc != null && widget.informe.ruc!.isNotEmpty
                  ? 'Proveedor ${i + 1} - RUC: ${widget.informe.ruc}'
                  : 'Proveedor ${i + 1}',
              tipocombrobante: 'FACTURA',
              serie: 'F001',
              numero: '${1000 + i}',
              igv: (widget.informe.total / widget.informe.cantidad) * 0.18,
              fecha: widget.informe.fecCre,
              total: widget.informe.total / widget.informe.cantidad,
              moneda: 'PEN',
              ruccliente: widget.informe.ruc,
              motivoviaje: '',
              lugarorigen: '',
              lugardestino: '',
              tipomovilidad: '',
            ),
          );
        }
      }

      setState(() {
        _detalles = detallesConvertidos;
        _isLoading = false;
      });

      print('✅ State updated - Detalles cargados: ${_detalles.length} items');
      print('📊 Loading state: $_isLoading');
      print('📋 Empty check: ${_detalles.isEmpty}');
    } catch (e) {
      print('❌ Error general al cargar detalles: $e');
      print('🔍 Error type: ${e.runtimeType}');
      print('🔍 Stack trace: ${StackTrace.current}');
      setState(() {
        _detalles = [];
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.only(top: 100), // Solo margen superior
      clipBehavior: Clip.antiAliasWithSaveLayer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: SizedBox(
        width: double.maxFinite,
        height: double
            .maxFinite, // Usa toda la altura disponible desde el margen superior
        child: Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0.5,
            leading: IconButton(
              icon: const Icon(Icons.more_horiz, color: Colors.grey),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text(
              'Detalle informe',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          body: Column(
            children: [
              // Cabecera ultra compacta
              Container(
                width: double.infinity,
                color: const Color(0xFF1976D2),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // COLUMNA IZQUIERDA
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // PRIMERA FILA: Nombre del informe + ID
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      widget.informe.titulo ??
                                          'Sin título asignado',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                              ),

                              const SizedBox(height: 8),

                              // SEGUNDA FILA: Fecha
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    color: Colors.white.withOpacity(0.8),
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _formatDate(widget.informe.fecCre),
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  Text(
                                    '|',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.6),
                                      fontSize: 24,
                                      fontWeight: FontWeight.w300,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),

                                    child: Text(
                                      '#${widget.informe.idInf}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 6),

                              // TERCERA FILA: Política
                              Row(
                                children: [
                                  Icon(
                                    Icons.policy,
                                    color: Colors.white.withOpacity(0.8),
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    widget.informe.politica ?? 'General',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 16),

                        // COLUMNA DERECHA
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Monto
                            Text(
                              'S/ ${widget.informe.total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),

                            const SizedBox(height: 4),

                            // Estado del informe
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(
                                  widget.informe.estadoActual,
                                ).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: _getStatusColor(
                                    widget.informe.estadoActual,
                                  ),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                widget.informe.estadoActual ?? 'Borrador',
                                style: TextStyle(
                                  color: _getStatusColor(
                                    widget.informe.estadoActual,
                                  ),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),

                            const SizedBox(height: 8),

                            // Gastos debajo
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),

                              child: Text(
                                '${widget.informe.cantidad} ${widget.informe.cantidad == 1 ? 'gasto' : 'gastos'}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Tabs mejoradas
              Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  labelColor: Colors.blue,
                  unselectedLabelColor: Colors.grey[600],
                  indicatorColor: Colors.blue,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: [
                    Tab(text: 'Gastos (${widget.informe.cantidad})'),
                    const Tab(text: 'Detalle'),
                  ],
                ),
              ),

              // Contenido de las tabs
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab de Gastos
                    Container(
                      color: Colors.grey[50],
                      child: Builder(
                        builder: (context) {
                          print(
                            '📱 Building Gastos Tab - Loading: $_isLoading, Items: ${_detalles.length}',
                          );

                          if (_isLoading) {
                            return const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.blue,
                                ),
                              ),
                            );
                          }

                          if (_detalles.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.receipt_long,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No hay gastos en este informe',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _loadDetalles,
                                    child: const Text('Recargar'),
                                  ),
                                ],
                              ),
                            );
                          }

                          return RefreshIndicator(
                            onRefresh: _loadDetalles,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: _detalles.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final detalle = _detalles[index];
                                print(
                                  '🏗️ Building card for item $index: ${detalle.proveedor}',
                                );
                                return _buildGastoCard(detalle);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    // Tab de Detalle
                    Container(
                      color: Colors.grey[50],
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDetailSection('Información General', [
                              _buildDetailRow(
                                'ID Informe',
                                '#${widget.informe.idInf}',
                              ),
                              _buildDetailRow(
                                'Usuario',
                                widget.informe.idUser.toString(),
                              ),
                              _buildDetailRow(
                                'RUC',
                                widget.informe.ruc ?? 'N/A',
                              ),
                              _buildDetailRow(
                                'DNI',
                                widget.informe.dni ?? 'N/A',
                              ),
                            ]),
                            const SizedBox(height: 20),
                            _buildDetailSection('Estadísticas', [
                              _buildDetailRow(
                                'Total Gastos',
                                widget.informe.cantidad.toString(),
                              ),
                              _buildDetailRow(
                                'Aprobados',
                                '${widget.informe.cantidadAprobado} (${widget.informe.totalAprobado.toStringAsFixed(2)} PEN)',
                              ),
                              _buildDetailRow(
                                'Desaprobados',
                                '${widget.informe.cantidadDesaprobado} (${widget.informe.totalDesaprobado.toStringAsFixed(2)} PEN)',
                              ),
                            ]),
                            if (widget.informe.nota != null &&
                                widget.informe.nota!.isNotEmpty) ...[
                              const SizedBox(height: 20),
                              _buildDetailSection('Observaciones', [
                                Text(
                                  widget.informe.nota!,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ]),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Botones de acción mejorados
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(20),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      // Botón Editar
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => EditarInformeModal(
                                  informe: widget.informe,
                                  gastos: _detalles,
                                ),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Colors.blue,
                              width: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'Editar informe',
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Botón Enviar
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            // Aquí puedes agregar lógica para enviar
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 2,
                          ),
                          child: const Text(
                            'Enviar informe',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGastoCard(ReporteInformeDetalle detalle) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Imagen placeholder
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.receipt_long, color: Colors.grey[600], size: 24),
          ),
          const SizedBox(width: 16),

          // Información del gasto
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detalle.ruc ?? 'Proveedor no especificado',
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 0),
                Text(
                  detalle.categoria != null && detalle.categoria!.isNotEmpty
                      ? '${detalle.categoria}'
                      : 'Sin categoría',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                Text(
                  _formatDate(detalle.fecha),
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          // Monto y estado
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${detalle.total.toStringAsFixed(2)} ${detalle.moneda ?? 'PEN'}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(detalle.estadoactual).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  detalle.estadoactual ?? 'Sin estado',
                  style: TextStyle(
                    fontSize: 12,
                    color: _getStatusColor(detalle.estadoactual),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return '----';
    }

    try {
      // Si viene como timestamp ISO (2025-10-06T11:14:39.492431), extraer solo la fecha
      if (dateString.contains('T')) {
        final datePart = dateString.split('T')[0];
        return datePart; // Ya está en formato YYYY-MM-DD
      }

      // Si viene en formato AÑO,MES,DIA (separado por comas)
      if (dateString.contains(',')) {
        final parts = dateString.split(',');
        if (parts.length == 3) {
          final year = parts[0].trim();
          final month = parts[1].trim().padLeft(2, '0');
          final day = parts[2].trim().padLeft(2, '0');
          return '$year-$month-$day';
        }
      }

      // Si viene en formato DD/MM/YYYY, convertir a YYYY-MM-DD
      if (dateString.contains('/')) {
        final parts = dateString.split('/');
        if (parts.length == 3) {
          final day = parts[0].padLeft(2, '0');
          final month = parts[1].padLeft(2, '0');
          final year = parts[2];
          return '$year-$month-$day';
        }
      }

      // Si ya está en formato ISO simple (YYYY-MM-DD), devolverlo tal como está
      if (dateString.contains('-') &&
          dateString.length >= 8 &&
          dateString.length <= 10) {
        return dateString;
      }

      return dateString;
    } catch (e) {
      return '----';
    }
  }

  Color _getStatusColor(String? estado) {
    switch (estado?.toLowerCase()) {
      case 'aprobado':
      case 'completado':
        return Colors.green;
      case 'borrador':
      case 'pendiente':
        return Colors.orange;
      case 'rechazado':
      case 'cancelado':
        return Colors.red;
      case 'en revision':
      case 'en proceso':
        return Colors.blue;
      default:
        return const Color.fromARGB(255, 255, 254, 254);
    }
  }
}
