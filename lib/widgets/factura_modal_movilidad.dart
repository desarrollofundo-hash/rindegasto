import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../models/factura_data.dart';
import '../models/categoria_model.dart';
import '../services/categoria_service.dart';
import '../screens/home_screen.dart';

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

  // Variables para validación de campos obligatorios
  bool _isFormValid = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadCategorias();
    _addValidationListeners();
  }

  /// Agregar listeners para validación en tiempo real
  void _addValidationListeners() {
    _rucController.addListener(_validateForm);
    _tipoComprobanteController.addListener(_validateForm);
    _serieController.addListener(_validateForm);
    _numeroController.addListener(_validateForm);
    _fechaEmisionController.addListener(_validateForm);
    _totalController.addListener(_validateForm);
    _origenController.addListener(_validateForm);
    _destinoController.addListener(_validateForm);
    _motivoViajeController.addListener(_validateForm);
    _categoriaController.addListener(_validateForm);
  }

  /// Validar si todos los campos obligatorios están llenos
  void _validateForm() {
    final isValid =
        _rucController.text.trim().isNotEmpty &&
        _tipoComprobanteController.text.trim().isNotEmpty &&
        _serieController.text.trim().isNotEmpty &&
        _numeroController.text.trim().isNotEmpty &&
        _fechaEmisionController.text.trim().isNotEmpty &&
        _totalController.text.trim().isNotEmpty &&
        _origenController.text.trim().isNotEmpty &&
        _destinoController.text.trim().isNotEmpty &&
        _motivoViajeController.text.trim().isNotEmpty &&
        _categoriaController.text.trim().isNotEmpty &&
        _selectedImage != null;

    if (_isFormValid != isValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
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
    // Remover listeners antes de dispose
    _rucController.removeListener(_validateForm);
    _tipoComprobanteController.removeListener(_validateForm);
    _serieController.removeListener(_validateForm);
    _numeroController.removeListener(_validateForm);
    _fechaEmisionController.removeListener(_validateForm);
    _totalController.removeListener(_validateForm);
    _origenController.removeListener(_validateForm);
    _destinoController.removeListener(_validateForm);
    _motivoViajeController.removeListener(_validateForm);
    _categoriaController.removeListener(_validateForm);

    // Dispose de los controladores
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
        _validateForm(); // Validar formulario después de agregar imagen
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

  /// Guardar factura mediante API
  Future<void> _saveFacturaAPI() async {
    print('🚀 Iniciando guardado de factura...');

    // Validar campos obligatorios antes de continuar
    if (!_isFormValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Por favor complete todos los campos obligatorios'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      // Formatear fecha para SQL Server (solo fecha, sin hora)
      String fechaSQL = "";
      if (_fechaEmisionController.text.isNotEmpty) {
        try {
          // Intentar parsear la fecha del QR
          final fecha = DateTime.parse(_fechaEmisionController.text);
          fechaSQL =
              "${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}";
        } catch (e) {
          // Si falla, usar fecha actual
          final fecha = DateTime.now();
          fechaSQL =
              "${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}";
        }
      } else {
        final fecha = DateTime.now();
        fechaSQL =
            "${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}";
      }

      final body = {
        "idUser": 1,
        "dni": "74736808",
        "politica": _politicaController.text.length > 80
            ? _politicaController.text.substring(0, 80)
            : _politicaController.text,
        "categoria": _categoriaController.text.isEmpty
            ? "MOVILIDAD"
            : (_categoriaController.text.length > 80
                  ? _categoriaController.text.substring(0, 80)
                  : _categoriaController.text),
        "ruc": _rucController.text.isEmpty
            ? ""
            : (_rucController.text.length > 80
                  ? _rucController.text.substring(0, 80)
                  : _rucController.text),
        "proveedor": "PROVEEDOR DE EJEMPLO",
        "tipoCombrobante": _tipoComprobanteController.text.isEmpty
            ? ""
            : (_tipoComprobanteController.text.length > 180
                  ? _tipoComprobanteController.text.substring(0, 180)
                  : _tipoComprobanteController.text),
        "serie": _serieController.text.isEmpty
            ? ""
            : (_serieController.text.length > 80
                  ? _serieController.text.substring(0, 80)
                  : _serieController.text),
        "numero": _numeroController.text.isEmpty
            ? ""
            : (_numeroController.text.length > 80
                  ? _numeroController.text.substring(0, 80)
                  : _numeroController.text),
        "igv": double.tryParse(_igvController.text) ?? 0.0,
        "fecha": fechaSQL,
        "total": double.tryParse(_totalController.text) ?? 0.0,
        "moneda": _monedaController.text.isEmpty
            ? "PEN"
            : (_monedaController.text.length > 80
                  ? _monedaController.text.substring(0, 80)
                  : _monedaController.text),
        "rucCliente": _rucClienteController.text.isEmpty
            ? ""
            : (_rucClienteController.text.length > 80
                  ? _rucClienteController.text.substring(0, 80)
                  : _rucClienteController.text),
        "desEmp": "",
        "desSed": "",
        "idCuenta": "",
        "consumidor": "",
        "regimen": "",
        "destino": "BORRADOR",
        "glosa": _notaController.text.length > 480
            ? _notaController.text.substring(0, 480)
            : _notaController.text,
        "motivoViaje": _motivoViajeController.text.length > 50
            ? _motivoViajeController.text.substring(0, 50)
            : _motivoViajeController.text,
        "lugarOrigen": _origenController.text.length > 50
            ? _origenController.text.substring(0, 50)
            : _origenController.text,
        "lugarDestino": _destinoController.text.length > 50
            ? _destinoController.text.substring(0, 50)
            : _destinoController.text,
        "tipoMovilidad": _tipoTransporteController.text.length > 50
            ? _tipoTransporteController.text.substring(0, 50)
            : _tipoTransporteController.text,
        "obs": _notaController.text.length > 1000
            ? _notaController.text.substring(0, 1000)
            : _notaController.text,
        "estado": "S", // Solo 1 carácter como requiere la BD
        "fecCre": DateTime.now().toIso8601String(),
        "useReg": 1, // Campo obligatorio
        "hostname": "FLUTTER", // Campo obligatorio, máximo 50 caracteres
        "fecEdit": DateTime.now().toIso8601String(),
        "useEdit": 0,
        "useElim": 0,
      };

      print('📦 Datos a enviar: ${json.encode([body])}');
      print(
        '🌐 URL: http://190.119.200.124:45490/saveupdate/saverendiciongasto',
      );

      final response = await http
          .post(
            Uri.parse(
              'http://190.119.200.124:45490/saveupdate/saverendiciongasto',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode([body]),
          )
          .timeout(const Duration(seconds: 30));

      print('📊 Status Code: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');
      print('📋 Response Headers: ${response.headers}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Verificar si la respuesta contiene errores
        if (response.body.contains('Error') ||
            response.body.contains('error')) {
          throw Exception('Error del servidor: ${response.body}');
        }

        print('✅ Guardado exitoso');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Factura guardada exitosamente'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          // Cerrar el modal y navegar a la pantalla de gastos
          Navigator.of(context).pop(); // Cerrar modal
          Navigator.of(context).pop(); // Cerrar pantalla QR si existe

          // Navegar a HomeScreen con índice 0 (pestaña de Gastos)
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false, // Remover todas las rutas anteriores
          );
        }
      } else {
        print('❌ Error del servidor: ${response.statusCode}');
        throw Exception(
          'Error del servidor: ${response.statusCode}\nRespuesta: ${response.body}',
        );
      }
    } catch (e) {
      print('💥 Error capturado: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al guardar: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Reintentar',
              textColor: Colors.white,
              onPressed: () => _saveFacturaAPI(),
            ),
          ),
        );
      }
    } finally {
      print('🔄 Finalizando proceso...');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
      child: Form(
        key: _formKey,
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
                const Text(
                  ' *',
                  style: TextStyle(color: Colors.red, fontSize: 16),
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
                  border: Border.all(
                    color: _selectedImage == null
                        ? Colors.red.shade300
                        : Colors.grey.shade300,
                    width: _selectedImage == null ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_a_photo,
                      size: 40,
                      color: _selectedImage == null ? Colors.red : Colors.grey,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Agregar imagen de la factura (Obligatorio)',
                      style: TextStyle(
                        color: _selectedImage == null
                            ? Colors.red
                            : Colors.grey,
                        fontWeight: _selectedImage == null
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
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
                  labelText: 'Seleccionar Categoría *',
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
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Categoría es obligatoria';
                  }
                  return null;
                },
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _categoriaController.text = value;
                    });
                    _validateForm(); // Validar cuando cambie la categoría
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
                      labelText: 'RUC Emisor *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.business_center),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'RUC Emisor es obligatorio';
                      }
                      return null;
                    },
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
                      labelText: 'Tipo Comprobante *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Tipo Comprobante es obligatorio';
                      }
                      return null;
                    },
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
                      labelText: 'Fecha Emisión *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Fecha Emisión es obligatoria';
                      }
                      return null;
                    },
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
                      labelText: 'Serie *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.tag),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Serie es obligatoria';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _numeroController,
                    decoration: const InputDecoration(
                      labelText: 'Número *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.numbers),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Número es obligatorio';
                      }
                      return null;
                    },
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
                      labelText: 'Total *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Total es obligatorio';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Ingrese un número válido';
                      }
                      return null;
                    },
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
                      labelText: 'Origen *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.my_location),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Origen es obligatorio';
                      }
                      return null;
                    },
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
                      labelText: 'Destino *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Destino es obligatorio';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _motivoViajeController,
              decoration: const InputDecoration(
                labelText: 'Motivo del Viaje *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Motivo del Viaje es obligatorio';
                }
                return null;
              },
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
      child: Column(
        children: [
          // Mensaje de campos obligatorios
          if (!_isFormValid)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange.shade600),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Por favor complete todos los campos obligatorios (*) e incluya una imagen',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Row(
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
                  onPressed: _isLoading || !_isFormValid
                      ? null
                      : _saveFacturaAPI,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: _isFormValid ? Colors.blue : Colors.grey,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    disabledForegroundColor: Colors.grey[600],
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          _isFormValid
                              ? 'Guardar Gasto'
                              : 'Complete los campos obligatorios',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
