import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:intl/intl.dart';
import '../models/dropdown_option.dart';
import '../services/api_service.dart';
import '../services/user_service.dart';
import '../services/company_service.dart';
import '../screens/home_screen.dart';

/// Modal para crear nuevo gasto de movilidad después de seleccionar política
class NuevoGastoMovilidad extends StatefulWidget {
  final DropdownOption politicaSeleccionada;
  final VoidCallback onCancel;
  final Function(Map<String, dynamic>) onSave;

  const NuevoGastoMovilidad({
    super.key,
    required this.politicaSeleccionada,
    required this.onCancel,
    required this.onSave,
  });

  @override
  State<NuevoGastoMovilidad> createState() => _NuevoGastoMovilidadState();
}

class _NuevoGastoMovilidadState extends State<NuevoGastoMovilidad> {
  final ApiService _apiService = ApiService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controladores principales
  late TextEditingController _proveedorController;
  late TextEditingController _fechaController;
  late TextEditingController _totalController;
  late TextEditingController _monedaController;
  late TextEditingController _rucController;
  late TextEditingController _serieFacturaController;
  late TextEditingController _numeroFacturaController;
  late TextEditingController _tipoDocumentoController;
  late TextEditingController _numeroDocumentoController;
  late TextEditingController _notaController;
  late TextEditingController _rucClienteController;

  // Controladores específicos de movilidad
  late TextEditingController _origenController;
  late TextEditingController _destinoController;
  late TextEditingController _motivoViajeController;
  late TextEditingController _tipoTransporteController;

  // Variables para dropdowns

  // Estados de carga
  bool _isLoading = false;
  bool _isLoadingCategorias = false;
  bool _isLoadingTiposGasto = false;
  bool _isScanning = false;

  // Variables para el lector SUNAT
  bool _hasScannedData = false;

  // Datos para dropdowns
  List<DropdownOption> _categoriasMovilidad = [];
  List<DropdownOption> _tiposGasto = [];

  // Errores
  String? _error;

  // Variables para dropdowns seleccionados
  DropdownOption? _selectedCategoria;
  DropdownOption? _selectedTipoGasto;

  // Archivo seleccionado
  File? _selectedImage;
  File? _selectedFile;
  String? _selectedFileType;
  String? _selectedFileName;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadCategorias();
    _loadTiposGasto();
  }

  void _initializeControllers() {
    _proveedorController = TextEditingController();
    _fechaController = TextEditingController(
      text: DateTime.now().toLocal().toString().split(' ')[0],
    );
    _totalController = TextEditingController();
    _monedaController = TextEditingController(text: 'PEN');
    _rucController = TextEditingController();
    _serieFacturaController = TextEditingController();
    _numeroFacturaController = TextEditingController();
    _tipoDocumentoController = TextEditingController();
    _numeroDocumentoController = TextEditingController();
    _notaController = TextEditingController();

    // RUC Cliente (siempre el RUC de la empresa que registra el gasto)
    _rucClienteController = TextEditingController(
      text: CompanyService().currentCompany?.ruc ?? '',
    );

    // Campos específicos de movilidad
    _origenController = TextEditingController();
    _destinoController = TextEditingController();
    _motivoViajeController = TextEditingController();
    _tipoTransporteController = TextEditingController(text: 'Taxi');
  }

  @override
  void dispose() {
    _proveedorController.dispose();
    _fechaController.dispose();
    _totalController.dispose();
    _monedaController.dispose();
    _rucController.dispose();
    _serieFacturaController.dispose();
    _numeroFacturaController.dispose();
    _tipoDocumentoController.dispose();
    _numeroDocumentoController.dispose();
    _notaController.dispose();
    _origenController.dispose();
    _destinoController.dispose();
    _motivoViajeController.dispose();
    _tipoTransporteController.dispose();
    _rucClienteController.dispose();
    super.dispose();
  }

  Future<void> _loadCategorias() async {
    setState(() {
      _isLoadingCategorias = true;
      _error = null;
    });

    try {
      final categorias = await _apiService.getRendicionCategorias(
        politica: widget.politicaSeleccionada.value,
      );

      setState(() {
        _categoriasMovilidad = categorias;
        _isLoadingCategorias = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoadingCategorias = false;
      });
    }
  }

  Future<void> _loadTiposGasto() async {
    setState(() {
      _isLoadingTiposGasto = true;
      _error = null;
    });

    try {
      final tiposGasto = await _apiService.getTiposGasto();

      setState(() {
        _tiposGasto = tiposGasto;
        _isLoadingTiposGasto = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoadingTiposGasto = false;
      });
    }
  }

  Future<void> _pickFile() async {
    final selectedOption = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Seleccionar evidencia'),
          content: const Text('¿Qué tipo de archivo desea agregar?'),
          actions: [
            TextButton.icon(
              onPressed: () => Navigator.pop(context, 'camera'),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Tomar Foto'),
            ),
            TextButton.icon(
              onPressed: () => Navigator.pop(context, 'gallery'),
              icon: const Icon(Icons.photo_library),
              label: const Text('Galería'),
            ),
            TextButton.icon(
              onPressed: () => Navigator.pop(context, 'file'),
              icon: const Icon(Icons.attach_file),
              label: const Text('Archivo'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );

    if (selectedOption != null) {
      setState(() => _isLoading = true);

      try {
        if (selectedOption == 'camera') {
          final XFile? image = await _picker.pickImage(
            source: ImageSource.camera,
          );
          if (image != null) {
            setState(() {
              _selectedImage = File(image.path);
              _selectedFile = null;
              _selectedFileType = 'image';
              _selectedFileName = image.name;
            });
          }
        } else if (selectedOption == 'gallery') {
          final XFile? image = await _picker.pickImage(
            source: ImageSource.gallery,
          );
          if (image != null) {
            setState(() {
              _selectedImage = File(image.path);
              _selectedFile = null;
              _selectedFileType = 'image';
              _selectedFileName = image.name;
            });
          }
        } else if (selectedOption == 'file') {
          final result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
          );
          if (result != null && result.files.single.path != null) {
            setState(() {
              _selectedFile = File(result.files.single.path!);
              _selectedImage = null;
              _selectedFileType = result.files.single.extension;
              _selectedFileName = result.files.single.name;
            });
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar archivo: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _onGuardar() async {
    print('🚀 Iniciando guardado de gasto de movilidad...');

    if (!_formKey.currentState!.validate()) {
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
      if (_fechaController.text.isNotEmpty) {
        try {
          // Intentar parsear la fecha
          final fecha = DateTime.parse(_fechaController.text);
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
        "idUser": UserService().currentUserCode,
        "dni": UserService().currentUserDni,
        "politica": widget.politicaSeleccionada.value.length > 80
            ? widget.politicaSeleccionada.value.substring(0, 80)
            : widget.politicaSeleccionada.value,
        "categoria":
            _selectedCategoria?.value == null ||
                _selectedCategoria!.value.isEmpty
            ? "MOVILIDAD"
            : (_selectedCategoria!.value.length > 80
                  ? _selectedCategoria!.value.substring(0, 80)
                  : _selectedCategoria!.value),
        "tipoGasto":
            _selectedTipoGasto?.value == null ||
                _selectedTipoGasto!.value.isEmpty
            ? "GASTO DE MOVILIDAD"
            : (_selectedTipoGasto!.value.length > 80
                  ? _selectedTipoGasto!.value.substring(0, 80)
                  : _selectedTipoGasto!.value),
        "ruc": _rucController.text.isEmpty
            ? ""
            : (_rucController.text.length > 80
                  ? _rucController.text.substring(0, 80)
                  : _rucController.text),
        "proveedor": _proveedorController.text.isEmpty
            ? "PROVEEDOR DE EJEMPLO"
            : (_proveedorController.text.length > 80
                  ? _proveedorController.text.substring(0, 80)
                  : _proveedorController.text),
        "tipoCombrobante": _tipoDocumentoController.text.isEmpty
            ? ""
            : (_tipoDocumentoController.text.length > 180
                  ? _tipoDocumentoController.text.substring(0, 180)
                  : _tipoDocumentoController.text),
        "serie": _serieFacturaController.text.isEmpty
            ? ""
            : (_serieFacturaController.text.length > 80
                  ? _serieFacturaController.text.substring(0, 80)
                  : _serieFacturaController.text),
        "numero": _numeroFacturaController.text.isEmpty
            ? ""
            : (_numeroFacturaController.text.length > 80
                  ? _numeroFacturaController.text.substring(0, 80)
                  : _numeroFacturaController.text),
        "igv": 0.0, // No tenemos campo IGV en este modal
        "fecha": fechaSQL,
        "total": double.tryParse(_totalController.text) ?? 0.0,
        "moneda": _monedaController.text.isEmpty
            ? "PEN"
            : (_monedaController.text.length > 80
                  ? _monedaController.text.substring(0, 80)
                  : _monedaController.text),
        "rucCliente": _rucClienteController.text.isNotEmpty
            ? _rucClienteController.text
            : (CompanyService().currentCompany?.ruc ?? ''),
        "desEmp": CompanyService().currentCompany?.empresa ?? '',
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
        "useReg": UserService().currentUserCode, // Campo obligatorio
        "hostname": "FLUTTER", // Campo obligatorio, máximo 50 caracteres
        "fecEdit": DateTime.now().toIso8601String(),
        "useEdit": 0,
        "useElim": 0,
      };

      // ✅ Proceder con el guardado
      print('✅ Procediendo a guardar...');
      final idRend = await _apiService.saveRendicionGasto(body);

      if (idRend == null) {
        throw Exception(
          'No se pudo guardar la factura principal o no se obtuvo el ID autogenerado',
        );
      }

      debugPrint('🆔 ID autogenerado obtenido: $idRend');
      debugPrint('📋 Preparando datos de evidencia con el ID generado...');
      final facturaDataEvidencia = {
        "idRend": idRend, // ✅ Usar el ID autogenerado del API principal
        "evidencia": _selectedFile != null
            ? base64Encode(_selectedFile!.readAsBytesSync())
            : (_selectedImage != null
                  ? base64Encode(_selectedImage!.readAsBytesSync())
                  : ""),
        "obs": _notaController.text.length > 1000
            ? _notaController.text.substring(0, 1000)
            : _notaController.text,
        "estado": "S", // Solo 1 carácter como requiere la BD
        "fecCre": DateTime.now().toIso8601String(),
        "useReg": UserService().currentUserCode, // Campo obligatorio
        "hostname": "FLUTTER", // Campo obligatorio, máximo 50 caracteres
        "fecEdit": DateTime.now().toIso8601String(),
        "useEdit": 0,
        "useElim": 0,
      };

      final successEvidencia = await _apiService.saveRendicionGastoEvidencia(
        facturaDataEvidencia,
      );

      if (successEvidencia && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Gasto de movilidad guardado exitosamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Cerrar el modal y navegar a la pantalla de gastos
        Navigator.of(context).pop(); // Cerrar modal

        // Navegar a HomeScreen con índice 0 (pestaña de Gastos)
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false, // Remover todas las rutas anteriores
        );
      }
    } catch (e) {
      print('💥 Error capturado: $e');

      // Cerrar diálogo de carga si está abierto
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      if (mounted) {
        // Extraer mensaje del servidor para mostrar en alerta
        final serverMessage = _extractServerMessage(e.toString());

        // Verificar si es una factura duplicada
        if (serverMessage.toLowerCase().contains('duplicad') ||
            serverMessage.toLowerCase().contains('ya existe') ||
            serverMessage.toLowerCase().contains('registrada')) {
          _showFacturaDuplicadaDialog(serverMessage);
        } else {
          _showErrorDialog(serverMessage);
        }
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
      height: MediaQuery.of(context).size.height * 0.9,
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
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildArchivoSection(),
                    const SizedBox(height: 16),
                    _buildLectorSunatSection(),
                    const SizedBox(height: 16),
                    _buildDatosGeneralesSection(),
                    const SizedBox(height: 16),
                    _buildDatosPersonalizadosSection(),
                    const SizedBox(height: 16),
                    _buildMovilidadSection(),
                    const SizedBox(height: 24),
                    _buildActions(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

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
                  'Nuevo Gasto - Movilidad',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Política: ${widget.politicaSeleccionada.value}',
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: widget.onCancel,
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildDatosGeneralesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Datos Generales',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _proveedorController,
              decoration: const InputDecoration(
                labelText: 'Proveedor *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Proveedor es obligatorio';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _fechaController,
                    decoration: const InputDecoration(
                      labelText: 'Fecha *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        _fechaController.text = date.toLocal().toString().split(
                          ' ',
                        )[0];
                      }
                    },
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Fecha es obligatoria';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _totalController,
                    decoration: const InputDecoration(
                      labelText: 'Total *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Total es obligatorio';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Ingrese un monto válido';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _monedaController.text.isEmpty
                  ? 'PEN'
                  : _monedaController.text,
              decoration: const InputDecoration(
                labelText: 'Moneda *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.monetization_on),
              ),
              items: const [
                DropdownMenuItem(value: 'PEN', child: Text('PEN - Soles')),
                DropdownMenuItem(value: 'USD', child: Text('USD - Dólares')),
                DropdownMenuItem(value: 'EUR', child: Text('EUR - Euros')),
              ],
              onChanged: (value) {
                _monedaController.text = value ?? 'PEN';
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatosPersonalizadosSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.settings, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Datos Personalizados',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Categoría
            if (_isLoadingCategorias)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Cargando categorías...'),
                  ],
                ),
              )
            else if (_error != null)
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
                        'Error: $_error',
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
                        'No hay categorías disponibles para movilidad',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              )
            else
              DropdownButtonFormField<DropdownOption>(
                decoration: const InputDecoration(
                  labelText: 'Categoría *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                value: _selectedCategoria,
                items: _categoriasMovilidad.map((categoria) {
                  return DropdownMenuItem<DropdownOption>(
                    value: categoria,
                    child: Text(categoria.value),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategoria = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Categoría es obligatoria';
                  }
                  return null;
                },
              ),

            const SizedBox(height: 16),

            // Tipo de Gasto
            if (_isLoadingTiposGasto)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Cargando tipos de gasto...'),
                  ],
                ),
              )
            else if (_error != null)
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
                        'Error: $_error',
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                    TextButton(
                      onPressed: _loadTiposGasto,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              )
            else
              DropdownButtonFormField<DropdownOption>(
                decoration: const InputDecoration(
                  labelText: 'Tipo Gasto *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.receipt),
                ),
                value: _selectedTipoGasto,
                items: _tiposGasto.map((tipo) {
                  return DropdownMenuItem<DropdownOption>(
                    value: tipo,
                    child: Text(tipo.value),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedTipoGasto = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Tipo Gasto es obligatorio';
                  }
                  return null;
                },
              ),

            const SizedBox(height: 16),

            // RUC Proveedor
            TextFormField(
              controller: _rucController,
              decoration: const InputDecoration(
                labelText: 'RUC Proveedor *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'RUC es obligatorio';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // RUC Cliente
            TextFormField(
              controller: _rucClienteController,
              enabled: false, // Campo no editable
              decoration: InputDecoration(
                labelText: 'RUC Cliente',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: Icon(Icons.info_outline, color: Colors.grey[600]),
                helperText: 'RUC de la empresa seleccionada',
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),

            const SizedBox(height: 16),

            // Serie y Número de Factura
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _serieFacturaController,
                    decoration: const InputDecoration(
                      labelText: 'Serie *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.receipt_long),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Serie es obligatorio';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _numeroFacturaController,
                    decoration: const InputDecoration(
                      labelText: 'Número *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.confirmation_number),
                    ),
                    keyboardType: TextInputType.number,
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

            const SizedBox(height: 16),

            // Tipo de Documento y Número de Documento
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _tipoDocumentoController,
                    decoration: const InputDecoration(
                      labelText: 'Tipo Documento *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                      hintText: 'Se llena automáticamente desde QR',
                    ),
                    readOnly: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Tipo Documento es obligatorio';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Nota
            TextFormField(
              controller: _notaController,
              decoration: const InputDecoration(
                labelText: 'Nota',
                hintText: 'Observaciones o comentarios',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note_add),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

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
            TextFormField(
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
            const SizedBox(height: 12),
            TextFormField(
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
              value: _tipoTransporteController.text.isEmpty
                  ? 'Taxi'
                  : _tipoTransporteController.text,
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
                _tipoTransporteController.text = value ?? 'Taxi';
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArchivoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.attach_file, color: Colors.blue),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Adjuntar Evidencia',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _pickFile,
                  icon: Icon(
                    (_selectedImage == null && _selectedFile == null)
                        ? Icons.add
                        : Icons.edit,
                    size: 16,
                  ),
                  label: Text(
                    (_selectedImage == null && _selectedFile == null)
                        ? 'Seleccionar'
                        : 'Cambiar',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade50,
              ),
              child: (_selectedImage != null || _selectedFile != null)
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _selectedFileType == 'image'
                              ? Icons.image
                              : Icons.picture_as_pdf,
                          size: 48,
                          color: Colors.green.shade600,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _selectedFileName ?? 'Archivo seleccionado',
                          style: const TextStyle(fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Archivo adjuntado correctamente',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.green.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_upload,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No hay archivo seleccionado',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Use el botón "Seleccionar" para agregar evidencia',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construir la sección del lector de código SUNAT
  Widget _buildLectorSunatSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.qr_code_scanner, color: Colors.blue),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Lector de Código SUNAT',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isScanning ? null : _scanQRCode,
                  icon: Icon(
                    _isScanning ? Icons.hourglass_empty : Icons.qr_code_scanner,
                    size: 16,
                  ),
                  label: Text(_isScanning ? 'Escaneando...' : 'Escanear QR'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _hasScannedData
                    ? Colors.green.shade50
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _hasScannedData
                      ? Colors.green.shade200
                      : Colors.grey.shade300,
                ),
              ),
              child: _hasScannedData
                  ? Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green.shade600,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Código QR procesado correctamente',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Los datos han sido extraídos y aplicados a los campos correspondientes',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: _clearScannedData,
                          icon: const Icon(Icons.clear, size: 16),
                          label: const Text('Limpiar Datos'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.orange,
                            textStyle: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.grey.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Escanee el código QR de la factura para llenar automáticamente los campos',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
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

  /// Método para escanear código QR
  Future<void> _scanQRCode() async {
    setState(() {
      _isScanning = true;
    });

    try {
      // Navegar a la pantalla de escáner
      final qrData = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (context) => _QRScannerScreen()),
      );

      if (qrData != null && qrData.isNotEmpty) {
        _processQRData(qrData);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al escanear QR: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  /// Procesar los datos del QR y llenar los campos
  void _processQRData(String qrData) {
    try {
      setState(() {
        _hasScannedData = true;
      });

      // Parsear el QR de SUNAT (formato típico separado por |)
      final parts = qrData.split('|');

      if (parts.length >= 6) {
        // Formato típico de QR SUNAT:
        // RUC|Tipo|Serie|Número|IGV|Total|Fecha|TipoDoc|DocReceptor

        // RUC del emisor
        if (parts[0].isNotEmpty) {
          _rucController.text = parts[0];
        }

        // Tipo de comprobante
        if (parts[1].isNotEmpty) {
          String tipoDoc = parts[1];
          switch (tipoDoc) {
            case '01':
              _tipoDocumentoController.text = 'Factura';
              break;
            case '03':
              _tipoDocumentoController.text = 'Boleta';
              break;
            case '08':
              _tipoDocumentoController.text = 'Nota de Débito';
              break;
            default:
              _tipoDocumentoController.text = 'Otro';
          }
        }

        // Serie
        if (parts[2].isNotEmpty) {
          _serieFacturaController.text = parts[2];
        }

        // Número de factura
        if (parts[3].isNotEmpty) {
          _numeroFacturaController.text = parts[3];
        }

        // Número de documento (combinado para compatibilidad)
        if (parts[2].isNotEmpty && parts[3].isNotEmpty) {
          _numeroDocumentoController.text = '${parts[2]}-${parts[3]}';
        }

        // Total
        if (parts[5].isNotEmpty) {
          _totalController.text = parts[5];
        }

        // Fecha (si está disponible)
        if (parts.length > 6 && parts[6].isNotEmpty) {
          final fechaNormalizada = _normalizarFecha(parts[6]);
          _fechaController.text = fechaNormalizada;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Datos del QR aplicados correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Formato de QR no válido');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al procesar QR: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _hasScannedData = false;
      });
    }
  }

  /// Limpiar los datos escaneados
  void _clearScannedData() {
    setState(() {
      _hasScannedData = false;

      // Limpiar los campos que se llenaron automáticamente
      _rucController.clear();
      _serieFacturaController.clear();
      _numeroFacturaController.clear();
      _tipoDocumentoController.clear();
      _numeroDocumentoController.clear();
      _totalController.clear();
      _fechaController.text = DateTime.now().toLocal().toString().split(' ')[0];
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Datos del QR limpiados'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          if (_selectedImage == null && _selectedFile == null)
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
                      'Por favor complete todos los campos obligatorios (*) e incluya un archivo de evidencia',
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
                    side: BorderSide(color: Colors.grey.shade400),
                  ),
                  child: const Text('Cancelar', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _onGuardar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
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
                      : const Text(
                          'Guardar Gasto',
                          style: TextStyle(
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

  /// Normaliza diferentes formatos de fecha al formato ISO (YYYY-MM-DD)
  String _normalizarFecha(String fechaOriginal) {
    try {
      // Limpiar la fecha de espacios y caracteres especiales
      String fechaLimpia = fechaOriginal.trim();

      // Lista de formatos de fecha comunes que pueden venir en QR de facturas
      final formatosPosibles = [
        'yyyy-MM-dd', // 2024-10-03 (ISO estándar)
        'dd/MM/yyyy', // 03/10/2024 (formato peruano común)
        'dd-MM-yyyy', // 03-10-2024
        'yyyy/MM/dd', // 2024/10/03
        'MM/dd/yyyy', // 10/03/2024 (formato americano)
        'dd.MM.yyyy', // 03.10.2024 (formato europeo)
        'yyyyMMdd', // 20241003 (formato sin separadores)
        'dd/MM/yy', // 03/10/24 (año de 2 dígitos)
        'yyyy-M-d', // 2024-10-3 (sin ceros a la izquierda)
        'dd/M/yyyy', // 03/10/2024
        'd/MM/yyyy', // 3/10/2024
        'd/M/yyyy', // 3/10/2024
      ];

      DateTime? fechaParseada;

      // Intentar parsear con cada formato
      for (String formato in formatosPosibles) {
        try {
          fechaParseada = DateFormat(formato).parseStrict(fechaLimpia);
          debugPrint('✅ Fecha parseada exitosamente con formato: $formato');
          debugPrint(
            '📅 Fecha original: $fechaOriginal → Fecha parseada: $fechaParseada',
          );
          break;
        } catch (e) {
          // Continuar con el siguiente formato
          continue;
        }
      }

      // Si no se pudo parsear con ningún formato, intentar con parseo flexible
      if (fechaParseada == null) {
        try {
          // Intentar detectar automáticamente el formato
          fechaParseada = DateTime.parse(fechaLimpia);
          debugPrint('✅ Fecha parseada con DateTime.parse automático');
        } catch (e) {
          // Intentar con algunos patrones especiales
          try {
            // Remover caracteres no numéricos y intentar formato YYYYMMDD
            String soloNumeros = fechaLimpia.replaceAll(RegExp(r'[^0-9]'), '');
            if (soloNumeros.length == 8) {
              String year = soloNumeros.substring(0, 4);
              String month = soloNumeros.substring(4, 6);
              String day = soloNumeros.substring(6, 8);
              fechaParseada = DateTime.parse('$year-$month-$day');
              debugPrint('✅ Fecha parseada desde números: $soloNumeros');
            }
          } catch (e2) {
            debugPrint('❌ No se pudo parsear la fecha: $fechaOriginal');
          }
        }
      }

      if (fechaParseada != null) {
        // Validar que la fecha sea razonable (no muy antigua ni muy futura)
        final ahora = DateTime.now();
        final hace5Anos = ahora.subtract(const Duration(days: 365 * 5));
        final en1Ano = ahora.add(const Duration(days: 365));

        if (fechaParseada.isBefore(hace5Anos) ||
            fechaParseada.isAfter(en1Ano)) {
          debugPrint('⚠️ Fecha fuera del rango razonable: $fechaParseada');
          // Si la fecha está fuera del rango, usar fecha actual
          return DateFormat('yyyy-MM-dd').format(ahora);
        }

        // Convertir al formato ISO estándar
        String fechaISO = DateFormat('yyyy-MM-dd').format(fechaParseada);
        debugPrint('🎯 Fecha normalizada: $fechaOriginal → $fechaISO');
        return fechaISO;
      }

      // Si todo falla, usar la fecha actual
      debugPrint('🔄 Usando fecha actual como fallback para: $fechaOriginal');
      return DateFormat('yyyy-MM-dd').format(DateTime.now());
    } catch (e) {
      debugPrint('💥 Error en _normalizarFecha: $e');
      // En caso de cualquier error, usar fecha actual
      return DateFormat('yyyy-MM-dd').format(DateTime.now());
    }
  }

  /// Muestra un diálogo específico para facturas duplicadas
  void _showFacturaDuplicadaDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.receipt_long,
                  color: Colors.orange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Factura Ya Registrada',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Esta factura ya ha sido registrada previamente en el sistema.',
                        style: TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (message.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    message,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar diálogo de error
                // Usar un Future.delayed para asegurar que el contexto esté disponible
                Future.delayed(const Duration(milliseconds: 100), () {
                  // Cerrar el modal principal
                  if (mounted && Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                });
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Entendido',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Muestra un diálogo de error general
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Error del Servidor',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
          content: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withOpacity(0.2)),
            ),
            child: Text(
              message,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar diálogo de error
                // Para errores generales, no cerramos automáticamente el modal
                // para permitir al usuario corregir el problema
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Cerrar',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Extraer mensaje del error del servidor
  String _extractServerMessage(String errorString) {
    try {
      // Buscar si el error contiene JSON con mensaje
      final regex = RegExp(r'\{.*"message".*?:.*?"([^"]+)".*\}');
      final match = regex.firstMatch(errorString);

      if (match != null && match.group(1) != null) {
        return match.group(1)!;
      }

      // Si no encuentra JSON, usar el mensaje completo pero limitado
      if (errorString.length > 200) {
        return errorString.substring(0, 200) + '...';
      }

      return errorString;
    } catch (e) {
      return 'Error al procesar la respuesta del servidor';
    }
  }
}

/// Pantalla del escáner QR para códigos SUNAT
class _QRScannerScreen extends StatefulWidget {
  @override
  State<_QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<_QRScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Escanear Código QR'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => cameraController.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Cámara escáner
          MobileScanner(controller: cameraController, onDetect: _onQRDetected),

          // Overlay con marco de escaneo
          const QrScannerOverlay(
            borderColor: Colors.blue,
            borderWidth: 10,
            cutOutSize: 250,
          ),

          // Instrucciones
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Enfoque el código QR de la factura SUNAT\npara extraer los datos automáticamente',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Indicador de procesamiento
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.blue),
                    SizedBox(height: 16),
                    Text(
                      'Procesando código QR...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _onQRDetected(BarcodeCapture capture) {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? qrData = barcodes.first.rawValue;
      if (qrData != null && qrData.isNotEmpty) {
        setState(() {
          _isProcessing = true;
        });

        // Pequeño delay para mostrar el indicador de procesamiento
        Future.delayed(const Duration(milliseconds: 500), () {
          Navigator.pop(context, qrData);
        });
      }
    }
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
}

// Widget simple para overlay del escáner QR
class QrScannerOverlay extends StatelessWidget {
  final double cutOutSize;
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;

  const QrScannerOverlay({
    Key? key,
    this.cutOutSize = 250,
    this.borderColor = Colors.blue,
    this.borderWidth = 3.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: QrScannerPainter(
        cutOutSize: cutOutSize,
        borderColor: borderColor,
        borderWidth: borderWidth,
        overlayColor: overlayColor,
      ),
    );
  }
}

class QrScannerPainter extends CustomPainter {
  final double cutOutSize;
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;

  QrScannerPainter({
    required this.cutOutSize,
    required this.borderColor,
    required this.borderWidth,
    required this.overlayColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final cutOutRect = Rect.fromCenter(
      center: rect.center,
      width: cutOutSize,
      height: cutOutSize,
    );

    // Dibujar overlay con cut-out
    final backgroundPath = Path()
      ..addRect(rect)
      ..addRect(cutOutRect)
      ..fillType = PathFillType.evenOdd;

    final backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    canvas.drawPath(backgroundPath, backgroundPaint);

    // Dibujar esquinas del marco
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final cornerLength = 30.0;
    final path = Path();

    // Esquina superior izquierda
    path.moveTo(cutOutRect.left, cutOutRect.top + cornerLength);
    path.lineTo(cutOutRect.left, cutOutRect.top);
    path.lineTo(cutOutRect.left + cornerLength, cutOutRect.top);

    // Esquina superior derecha
    path.moveTo(cutOutRect.right - cornerLength, cutOutRect.top);
    path.lineTo(cutOutRect.right, cutOutRect.top);
    path.lineTo(cutOutRect.right, cutOutRect.top + cornerLength);

    // Esquina inferior derecha
    path.moveTo(cutOutRect.right, cutOutRect.bottom - cornerLength);
    path.lineTo(cutOutRect.right, cutOutRect.bottom);
    path.lineTo(cutOutRect.right - cornerLength, cutOutRect.bottom);

    // Esquina inferior izquierda
    path.moveTo(cutOutRect.left + cornerLength, cutOutRect.bottom);
    path.lineTo(cutOutRect.left, cutOutRect.bottom);
    path.lineTo(cutOutRect.left, cutOutRect.bottom - cornerLength);

    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
