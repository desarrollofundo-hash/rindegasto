import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/factura_data.dart';
import '../models/categoria_model.dart';
import '../services/categoria_service.dart';

/// Widget modal personalizado para gastos de movilidad
class FacturaModalMovilidad extends StatefulWidget {
  final FacturaData facturaData;
  final String politicaSeleccionada;
  final Function(FacturaData, String?) onSave;
  final VoidCallback onCancel;

  const FacturaModalMovilidad({
    Key? key,
    required this.facturaData,
    required this.politicaSeleccionada,
    required this.onSave,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<FacturaModalMovilidad> createState() => _FacturaModalMovilidadState();
}

class _FacturaModalMovilidadState extends State<FacturaModalMovilidad> {
  // Controladores para cada campo específico de movilidad
  late TextEditingController _politicaController;
  late TextEditingController _rucController;
  late TextEditingController _tipoComprobanteController;
  late TextEditingController _serieController;
  late TextEditingController _numeroController;
  late TextEditingController _igvController;
  late TextEditingController _fechaEmisionController;
  late TextEditingController _totalController;
  late TextEditingController _monedaController;
  late TextEditingController _rucClienteController;
  late TextEditingController _notaController;

  // Campos específicos para movilidad
  late TextEditingController _origenController;
  late TextEditingController _destinoController;
  late TextEditingController _motivoViajeController;
  late TextEditingController _tipoTransporteController;
  late TextEditingController _categoriaController;

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  bool _isLoadingCategorias = false;
  List<CategoriaModel> _categoriasMovilidad = [];
  String? _errorCategorias;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadCategorias();
  }

  /// Cargar categorías desde la API para GASTOS DE MOVILIDAD
  Future<void> _loadCategorias() async {
    setState(() {
      _isLoadingCategorias = true;
      _errorCategorias = null;
    });

    try {
      final categorias = await CategoriaService.getCategoriasMovilidad();
      setState(() {
        _categoriasMovilidad = categorias;
        _isLoadingCategorias = false;
      });
    } catch (e) {
      setState(() {
        _errorCategorias = e.toString();
        _isLoadingCategorias = false;
      });
    }
  }

  /// Inicializar todos los controladores con los datos parseados del QR
  void _initializeControllers() {
    _politicaController = TextEditingController(
      text: widget.politicaSeleccionada,
    );
    _rucController = TextEditingController(text: widget.facturaData.ruc ?? '');
    _tipoComprobanteController = TextEditingController(
      text: widget.facturaData.tipoComprobante ?? '',
    );
    _serieController = TextEditingController(
      text: widget.facturaData.serie ?? '',
    );
    _numeroController = TextEditingController(
      text: widget.facturaData.numero ?? '',
    );
    _igvController = TextEditingController(
      text: widget.facturaData.codigo ?? '',
    );
    _fechaEmisionController = TextEditingController(
      text: widget.facturaData.fechaEmision ?? '',
    );
    _totalController = TextEditingController(
      text: widget.facturaData.total?.toString() ?? '',
    );
    _monedaController = TextEditingController(
      text: widget.facturaData.moneda ?? 'PEN',
    );
    _rucClienteController = TextEditingController(
      text: widget.facturaData.rucCliente ?? '',
    );
    _notaController = TextEditingController(text: '');

    // Campos específicos para movilidad
    _origenController = TextEditingController(text: '');
    _destinoController = TextEditingController(text: '');
    _motivoViajeController = TextEditingController(text: '');
    _tipoTransporteController = TextEditingController(text: 'Taxi');
    _categoriaController = TextEditingController(text: '');
  }

  @override
  void dispose() {
    _politicaController.dispose();
    _rucController.dispose();
    _tipoComprobanteController.dispose();
    _serieController.dispose();
    _numeroController.dispose();
    _igvController.dispose();
    _fechaEmisionController.dispose();
    _totalController.dispose();
    _monedaController.dispose();
    _rucClienteController.dispose();
    _notaController.dispose();
    _origenController.dispose();
    _destinoController.dispose();
    _motivoViajeController.dispose();
    _tipoTransporteController.dispose();
    _categoriaController.dispose();
    super.dispose();
  }

  /// Seleccionar imagen desde la cámara
  Future<void> _pickImage() async {
    try {
      setState(() => _isLoading = true);
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() => _selectedImage = File(image.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al capturar imagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Guardar los datos de la factura
  void _saveFactura() {
    final facturaData = FacturaData(
      ruc: _rucController.text.isEmpty ? null : _rucController.text,
      tipoComprobante: _tipoComprobanteController.text.isEmpty
          ? null
          : _tipoComprobanteController.text,
      serie: _serieController.text.isEmpty ? null : _serieController.text,
      numero: _numeroController.text.isEmpty ? null : _numeroController.text,
      codigo: _igvController.text.isEmpty ? null : _igvController.text,
      fechaEmision: _fechaEmisionController.text.isEmpty
          ? null
          : _fechaEmisionController.text,
      total: double.tryParse(_totalController.text),
      moneda: _monedaController.text.isEmpty ? 'PEN' : _monedaController.text,
      rucCliente: _rucClienteController.text.isEmpty
          ? null
          : _rucClienteController.text,
      rawData: widget.facturaData.rawData,
      format: widget.facturaData.format,
    );

    widget.onSave(facturaData, _selectedImage?.path);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImageSection(),
                  const SizedBox(height: 20),
                  _buildPolicySection(),
                  const SizedBox(height: 12),
                  _buildCategorySection(),
                  const SizedBox(height: 12),

                  _buildFacturaDataSection(),
                  const SizedBox(height: 20),
                  _buildMovilidadSection(),
                  const SizedBox(height: 12),
                  _buildNotesSection(),
                ],
              ),
            ),
          ),
          _buildActionButtons(),
        ],
      ),
    );
  }

  /// Construir el header del modal
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade400],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.directions_car, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gasto de Movilidad - Perú',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Datos extraídos del QR',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  /// Construir la sección de imagen
  Widget _buildImageSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.receipt, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Imagen de la Factura',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (_isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: Icon(
                      _selectedImage == null ? Icons.add_a_photo : Icons.edit,
                    ),
                    label: Text(_selectedImage == null ? 'Agregar' : 'Cambiar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_selectedImage != null)
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(_selectedImage!, fit: BoxFit.cover),
                ),
              )
            else
              Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'Agregar imagen de la factura',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Construir la sección de política
  Widget _buildPolicySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.policy, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Política',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _politicaController,
              enabled: false,
              decoration: const InputDecoration(
                labelText: 'Política Seleccionada',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.policy),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construir la sección de categoría para movilidad
  Widget _buildCategorySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.category, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Categoría',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isLoadingCategorias)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text(
                      'Cargando categorías...',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
            else if (_errorCategorias != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Error al cargar categorías: $_errorCategorias',
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                    TextButton(
                      onPressed: _loadCategorias,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              )
            else if (_categoriasMovilidad.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No hay categorías disponibles para esta política',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              )
            else
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Seleccionar Categoría',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                value:
                    _categoriaController.text.isNotEmpty &&
                        _categoriasMovilidad.any(
                          (cat) => cat.categoria == _categoriaController.text,
                        )
                    ? _categoriaController.text
                    : null,
                items: _categoriasMovilidad
                    .map(
                      (categoria) => DropdownMenuItem<String>(
                        value: categoria.categoria,
                        child: Text(_formatCategoriaName(categoria.categoria)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _categoriaController.text = value;
                    });
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  /// Formatear el nombre de la categoría para mostrar
  String _formatCategoriaName(String categoria) {
    return categoria
        .toLowerCase()
        .split(' ')
        .map(
          (word) => word.isNotEmpty
              ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
              : word,
        )
        .join(' ');
  }

  Widget _buildFacturaDataSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.receipt_long, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Datos de la Factura',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _rucController,
                    decoration: const InputDecoration(
                      labelText: 'RUC Emisor',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.business_center),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _tipoComprobanteController,
                    decoration: const InputDecoration(
                      labelText: 'Tipo Comprobante',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _rucClienteController,
                    decoration: const InputDecoration(
                      labelText: 'RUC Cliente',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _fechaEmisionController,
                    decoration: const InputDecoration(
                      labelText: 'Fecha Emisión',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _serieController,
                    decoration: const InputDecoration(
                      labelText: 'Serie',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.tag),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _numeroController,
                    decoration: const InputDecoration(
                      labelText: 'Número',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.numbers),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _totalController,
                    decoration: const InputDecoration(
                      labelText: 'Total',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                  ),
                ),

                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _monedaController,
                    decoration: const InputDecoration(
                      labelText: 'Moneda',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.monetization_on),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _igvController,
                    decoration: const InputDecoration(
                      labelText: 'IGV (%)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.percent),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Construir la sección específica de movilidad
  Widget _buildMovilidadSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.directions_car, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Detalles de Movilidad',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _origenController,
                    decoration: const InputDecoration(
                      labelText: 'Origen',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.my_location),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _destinoController,
                    decoration: const InputDecoration(
                      labelText: 'Destino',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _motivoViajeController,
              decoration: const InputDecoration(
                labelText: 'Motivo del Viaje',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _tipoTransporteController.text.isNotEmpty
                  ? _tipoTransporteController.text
                  : 'Taxi',
              decoration: const InputDecoration(
                labelText: 'Tipo de Transporte',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.directions_car),
              ),
              items: const [
                DropdownMenuItem(value: 'Taxi', child: Text('Taxi')),
                DropdownMenuItem(value: 'Uber', child: Text('Uber')),
                DropdownMenuItem(value: 'Bus', child: Text('Bus')),
                DropdownMenuItem(value: 'Metro', child: Text('Metro')),
                DropdownMenuItem(value: 'Avión', child: Text('Avión')),
                DropdownMenuItem(value: 'Otro', child: Text('Otro')),
              ],
              onChanged: (value) {
                setState(() {
                  _tipoTransporteController.text = value ?? 'Taxi';
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Construir la sección de datos de factura

  /// Construir la sección de notas
  Widget _buildNotesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.note_add, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Notas Adicionales',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notaController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Observaciones:',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construir los botones de acción
  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: widget.onCancel,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: Colors.grey[400]!),
              ),
              child: const Text(
                'Cancelar',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _saveFactura,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Guardar Gasto',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
