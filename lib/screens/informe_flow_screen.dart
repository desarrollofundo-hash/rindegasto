import 'package:flutter/material.dart';
import '../models/dropdown_option.dart';
import '../models/reporte_model.dart';
import '../services/api_service.dart';
import '../services/user_service.dart';

/// Pantalla de flujo para crear un nuevo informe paso a paso
class InformeFlowScreen extends StatefulWidget {
  final String tituloInforme;
  final DropdownOption politicaSeleccionada;

  const InformeFlowScreen({
    super.key,
    required this.tituloInforme,
    required this.politicaSeleccionada,
  });

  @override
  State<InformeFlowScreen> createState() => _InformeFlowScreenState();
}

class _InformeFlowScreenState extends State<InformeFlowScreen> {
  List<Reporte> _facturasDisponibles = [];
  List<Reporte> _facturasFiltradas = [];
  List<Reporte> _facturasSeleccionadas = [];
  bool _showSuccessMessage = true;
  bool _isLoadingFacturas = true;
  String? _errorFacturas;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadFacturas();
    // Mostrar mensaje de éxito por unos segundos
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showSuccessMessage = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _apiService.dispose();
    super.dispose();
  }

  Future<void> _loadFacturas() async {
    setState(() {
      _isLoadingFacturas = true;
      _errorFacturas = null;
    });

    try {
      // Cargar todas las facturas del usuario
      final todasLasFacturas = await _apiService.getReportesRendicionGasto(
        id: '1',
        idrend: '1',
        user: UserService().currentUserCode,
      );

      // Filtrar facturas por la política seleccionada
      final facturasFiltradas = todasLasFacturas.where((factura) {
        return factura.politica == widget.politicaSeleccionada.value;
      }).toList();

      setState(() {
        _facturasDisponibles = facturasFiltradas;
        _facturasFiltradas = facturasFiltradas;
        _isLoadingFacturas = false;
      });
    } catch (e) {
      setState(() {
        _errorFacturas = e.toString();
        _isLoadingFacturas = false;
      });
    }
  }

  void _filtrarFacturas(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      if (_searchQuery.isEmpty) {
        _facturasFiltradas = _facturasDisponibles;
      } else {
        _facturasFiltradas = _facturasDisponibles.where((factura) {
          // Filtrar por monto
          final monto = factura.total?.toString().toLowerCase() ?? '';
          // Filtrar por fecha
          final fecha = factura.fecha?.toLowerCase() ?? '';
          // Filtrar por número de factura/serie
          final numeroFactura = '${factura.serie ?? ''}-${factura.numero ?? ''}'
              .toLowerCase();
          // Filtrar por empresa/proveedor
          final empresa = factura.proveedor?.toLowerCase() ?? '';
          // Filtrar por categoría
          final categoria = factura.categoria?.toLowerCase() ?? '';
          // Filtrar por tipo de comprobante
          final tipoComprobante = factura.tipocomprobante?.toLowerCase() ?? '';

          return monto.contains(_searchQuery) ||
              fecha.contains(_searchQuery) ||
              numeroFactura.contains(_searchQuery) ||
              empresa.contains(_searchQuery) ||
              categoria.contains(_searchQuery) ||
              tipoComprobante.contains(_searchQuery);
        }).toList();
      }
    });
  }

  void _crearInforme() {
    // Retornar éxito con las facturas seleccionadas
    Navigator.of(context).pop(true);
  }

  Widget _buildNoResultsFound() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 48,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Sin resultados',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
                children: [
                  const TextSpan(
                    text: 'No se encontraron facturas que coincidan con ',
                  ),
                  TextSpan(
                    text: '"$_searchQuery"',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                _searchController.clear();
                _filtrarFacturas('');
              },
              icon: const Icon(Icons.clear_all),
              label: const Text('Limpiar búsqueda'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              // Header personalizado
              _buildCustomHeader(),

              // Información de la política
              _buildPoliticaInfo(),

              // Contenido principal
              Expanded(child: _buildMainContent()),
            ],
          ),

          /*  // Mensaje de éxito flotante
          if (_showSuccessMessage) _buildSuccessMessage(), */
        ],
      ),
    );
  }

  Widget _buildCustomHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 16),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
          ),
          Expanded(
            child: Text(
              'Nuevo informe',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPoliticaInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.lightBlue.shade50,
      child: Text(
        widget.politicaSeleccionada.value,
        style: TextStyle(
          color: Colors.blue.shade700,
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildMainContent() {
    return _buildAgregarGastosStep();
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _searchQuery.isNotEmpty
                ? Colors.blue.shade300
                : Colors.grey.shade300,
            width: _searchQuery.isNotEmpty ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _searchQuery.isNotEmpty
                  ? Colors.blue.shade100.withOpacity(0.5)
                  : Colors.grey.shade200.withOpacity(0.8),
              blurRadius: _searchQuery.isNotEmpty ? 8 : 4,
              offset: const Offset(0, 2),
              spreadRadius: _searchQuery.isNotEmpty ? 1 : 0,
            ),
          ],
        ),
        child: Row(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                _searchQuery.isNotEmpty ? Icons.search : Icons.search_outlined,
                key: ValueKey(_searchQuery.isNotEmpty),
                color: _searchQuery.isNotEmpty
                    ? Colors.blue.shade600
                    : Colors.grey.shade400,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: _filtrarFacturas,
                decoration: InputDecoration(
                  hintText:
                      'Buscar por monto, fecha, factura, empresa, categoría...',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                cursorColor: Colors.blue.shade600,
                cursorHeight: 20,
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _searchQuery.isNotEmpty
                  ? Container(
                      key: const ValueKey('clear_button'),
                      margin: const EdgeInsets.only(left: 8),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            _searchController.clear();
                            _filtrarFacturas('');
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              color: Colors.grey.shade600,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(key: ValueKey('empty')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgregarGastosStep() {
    return Container(
      color: Colors.grey.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Text(
              'Gastos',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.blue,
              ),
            ),
          ),
          _buildSearchBar(),
          Expanded(child: _buildFacturasContent()),
        ],
      ),
    );
  }

  Widget _buildFacturasContent() {
    if (_isLoadingFacturas) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Cargando facturas...',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_errorFacturas != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              'Error al cargar facturas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorFacturas!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red.shade600),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadFacturas,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (_facturasDisponibles.isEmpty) {
      return _buildEmptyFacturasState();
    }

    return _buildFacturasList();
  }

  Widget _buildEmptyFacturasState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ilustración de estado vacío
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Icono de factura
                Container(
                  width: 60,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                // Icono de interrogación
                Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.help_outline,
                    color: Colors.grey,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Sin facturas disponibles 👀',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No hay facturas disponibles para la política "${widget.politicaSeleccionada.value}".',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _loadFacturas,
            icon: const Icon(Icons.refresh),
            label: const Text('Recargar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFacturasList() {
    final totalSeleccionado = _facturasSeleccionadas.fold<double>(
      0.0,
      (sum, factura) => sum + (factura.total ?? 0.0),
    );

    return Column(
      children: [
        // Header con información de selección
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: _searchQuery.isNotEmpty
                ? LinearGradient(
                    colors: [Colors.blue.shade50, Colors.blue.shade100],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : LinearGradient(
                    colors: [Colors.blue.shade50, Colors.blue.shade50],
                  ),
            border: Border(
              bottom: BorderSide(
                color: _searchQuery.isNotEmpty
                    ? Colors.blue.shade200
                    : Colors.blue.shade100,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  _searchQuery.isNotEmpty
                      ? Icons.filter_list
                      : Icons.info_outline,
                  key: ValueKey(_searchQuery.isNotEmpty),
                  color: Colors.blue.shade600,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _searchQuery.isNotEmpty
                      ? Column(
                          key: const ValueKey('search_info'),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Resultados de búsqueda: "${_searchQuery}"',
                              style: TextStyle(
                                color: Colors.blue.shade800,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_facturasFiltradas.length} de ${_facturasDisponibles.length} facturas • ${_facturasSeleccionadas.length} seleccionadas',
                              style: TextStyle(
                                color: Colors.blue.shade600,
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          key: const ValueKey('default_info'),
                          'Selecciona las facturas (${_facturasSeleccionadas.length} )',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
              ),
              if (_searchQuery.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_facturasFiltradas.length}',
                    style: TextStyle(
                      color: Colors.blue.shade800,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Lista de facturas
        Expanded(
          child: _facturasFiltradas.isEmpty && _searchQuery.isNotEmpty
              ? _buildNoResultsFound()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _facturasFiltradas.length,
                  itemBuilder: (context, index) {
                    final factura = _facturasFiltradas[index];
                    final isSelected = _facturasSeleccionadas.contains(factura);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: isSelected ? 4 : 1,
                      color: isSelected ? Colors.blue.shade50 : Colors.white,
                      child: CheckboxListTile(
                        value: isSelected,
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              _facturasSeleccionadas.add(factura);
                            } else {
                              _facturasSeleccionadas.remove(factura);
                            }
                          });
                        },
                        title: Text(
                          '${factura.ruc ?? 'SIN RUC'} ',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? Colors.blue.shade700
                                : Colors.black87,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${factura.categoria ?? 'Sin categoría'}'),
                            Text(
                              '${factura.fecha ?? ''}',
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.blue.shade600
                                    : Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        secondary: Container(
                          width: 80,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.blue.shade100
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              'S/. ${factura.total?.toStringAsFixed(2) ?? '0.00'}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.blue.shade700
                                    : Colors.grey.shade700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: Colors.blue,
                      ),
                    );
                  },
                ),
        ),

        // Total y botones
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade300)),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Total
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total seleccionado:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          'S/. ${totalSeleccionado.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _facturasSeleccionadas.isNotEmpty
                                ? Colors.green.shade700
                                : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Botones
              Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: Colors.grey.shade400),
                          foregroundColor: Colors.grey.shade700,
                        ),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _facturasSeleccionadas.isEmpty
                            ? null
                            : _crearInforme,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _facturasSeleccionadas.isNotEmpty
                              ? Colors.green
                              : Colors.grey,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          disabledBackgroundColor: Colors.grey[300],
                          disabledForegroundColor: Colors.grey[600],
                        ),
                        child: const Text(
                          'Crear Informe',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /* 
  Widget _buildSuccessMessage() {
    return Positioned(
      bottom: 100,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Informe creado correctamente.',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _showSuccessMessage = false;
                    });
                  },
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.orange),
                      foregroundColor: Colors.orange,
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _showSuccessMessage = false;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Continuar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  } */
}
