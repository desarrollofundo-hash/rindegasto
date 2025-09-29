import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/factura_data.dart';
import '../models/categoria_model.dart';
import '../services/categoria_service.dart';

/// Widget modal personalizado para mostrar y editar datos de factura peruana
class FacturaModalPeru extends StatefulWidget {
  final FacturaData facturaData;
  final String politicaSeleccionada;
  final Function(FacturaData, String?) onSave;
  final VoidCallback onCancel;

  const FacturaModalPeru({
    Key? key,
    required this.facturaData,
    required this.politicaSeleccionada,
    required this.onSave,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<FacturaModalPeru> createState() => _FacturaModalPeruState();
}

class _FacturaModalPeruState extends State<FacturaModalPeru> {
  // Controladores para cada campo
  late TextEditingController _politicaController;
  late TextEditingController _categoriaController;
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

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  bool _isLoadingCategorias = false;
  List<CategoriaModel> _categoriasGeneral = [];
  String? _errorCategorias;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadCategorias();
  }

  /// Cargar categorías desde la API
  Future<void> _loadCategorias() async {
    if (!_politicaController.text.toLowerCase().contains('general')) {
      return; // Solo cargar para política GENERAL
    }

    setState(() {
      _isLoadingCategorias = true;
      _errorCategorias = null;
    });

    try {
      final categorias = await CategoriaService.getCategoriasGeneral();
      setState(() {
        _categoriasGeneral = categorias;
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
    _categoriaController = TextEditingController(text: '');
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
      text: widget.facturaData.total?.toStringAsFixed(2) ?? '',
    );
    _monedaController = TextEditingController(
      text: widget.facturaData.moneda ?? 'PEN',
    );
    _rucClienteController = TextEditingController(
      text: widget.facturaData.rucCliente ?? '',
    );
    _notaController = TextEditingController(text: '');
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  /// Dispose de todos los controladores
  void _disposeControllers() {
    _politicaController.dispose();
    _categoriaController.dispose();
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
                  _buildNotesSection(),
                  const SizedBox(height: 12),
                  _buildRawDataSection(),
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
          colors: [Colors.red.shade700, Colors.red.shade400],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt_long, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Factura Electrónica - Perú',
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
                const Icon(Icons.receipt, color: Colors.red),
                const SizedBox(width: 8),
                const Text(
                  'Adjuntar Factura',
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
                      backgroundColor: Colors.red,
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
                    Icon(Icons.receipt_outlined, color: Colors.grey, size: 40),
                    SizedBox(height: 8),
                    Text(
                      'Sin imagen de factura',
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Datos Generales',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        const SizedBox(height: 16),
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
    );
  }

  /// Construir la sección de categoría
  Widget _buildCategorySection() {
    // Determinar las categorías disponibles según la política
    List<DropdownMenuItem<String>> items = [];

    if (_politicaController.text.toLowerCase().contains('movilidad')) {
      // Para política de movilidad, mantener las opciones hardcodeadas
      items = const [];
    } else if (_politicaController.text.toLowerCase().contains('general')) {
      // Para política GENERAL, usar datos de la API
      if (_isLoadingCategorias) {
        return const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Categoría',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8),
            Center(child: CircularProgressIndicator()),
            SizedBox(height: 8),
            Text(
              'Cargando categorías...',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        );
      }

      if (_errorCategorias != null) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Categoría',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
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
            ),
          ],
        );
      }

      // Convertir categorías de la API a DropdownMenuItems
      items = _categoriasGeneral
          .map(
            (categoria) => DropdownMenuItem<String>(
              value: categoria.categoria,
              child: Text(_formatCategoriaName(categoria.categoria)),
            ),
          )
          .toList();

      // Si no hay categorías, mostrar mensaje
      if (items.isEmpty) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Categoría',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
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
            ),
          ],
        );
      }
    } else {
      // Para otras políticas, usar categorías por defecto
      items = const [];
    }

    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'Categoría',
        prefixIcon: Icon(Icons.category),
        border: OutlineInputBorder(),
      ),
      initialValue:
          _categoriaController.text.isNotEmpty &&
              items.any((item) => item.value == _categoriaController.text)
          ? _categoriaController.text
          : null,
      items: items,
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _categoriaController.text = value;
          });
        }
      },
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

  /// Construir la sección de datos de la factura

  Widget _buildFacturaDataSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Datos de la Factura',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        const SizedBox(height: 16),

        // Primera fila: RUC y Tipo Comprobante
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                _rucController,
                'RUC Emisor',
                Icons.business,
                TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                _tipoComprobanteController,
                'Tipo Comprobante',
                Icons.description,
                TextInputType.text,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Segunda fila: Serie y Número
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                _serieController,
                'Serie',
                Icons.tag,
                TextInputType.text,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                _numeroController,
                'Número',
                Icons.confirmation_number,
                TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Tercera fila: Código y Fecha
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                _igvController,
                'IGV',
                Icons.code,
                TextInputType.text,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                _fechaEmisionController,
                'Fecha Emisión',
                Icons.calendar_today,
                TextInputType.datetime,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Cuarta fila: Total y Moneda
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                _totalController,
                'Total',
                Icons.attach_money,
                TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                _monedaController,
                'Moneda',
                Icons.currency_exchange,
                TextInputType.text,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Quinta fila: RUC Cliente
        _buildTextField(
          _rucClienteController,
          'RUC Cliente',
          Icons.person,
          TextInputType.number,
        ),
      ],
    );
  }

  /// Construir la sección de notas
  Widget _buildNotesSection() {
    return _buildTextField(
      _notaController,
      'Nota',
      Icons.comment,
      TextInputType.text,
    );
  }

  /// Construir la sección de datos raw
  Widget _buildRawDataSection() {
    return ExpansionTile(
      title: const Text('Datos Originales del QR'),
      leading: const Icon(Icons.qr_code),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: SelectableText(
            widget.facturaData.rawData,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
          ),
        ),
      ],
    );
  }

  /// Construir los botones de acción
  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: widget.onCancel,
              icon: const Icon(Icons.cancel),
              label: const Text('Cancelar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 244, 54, 54),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _saveFactura,
              icon: const Icon(Icons.save),
              label: const Text('Guardar Factura'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 19, 126, 32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Construir un campo de texto personalizado
  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon,
    TextInputType keyboardType,
  ) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }
}
