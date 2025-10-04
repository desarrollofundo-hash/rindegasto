import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../models/dropdown_option.dart';
import '../services/api_service.dart';
import '../services/user_service.dart';
import '../services/company_service.dart';

/// Modal para crear un nuevo gasto con todos los campos personalizados
class NuevoGastoModal extends StatefulWidget {
  final DropdownOption politicaSeleccionada;
  final VoidCallback onCancel;
  final Function(Map<String, dynamic>) onSave;

  const NuevoGastoModal({
    super.key,
    required this.politicaSeleccionada,
    required this.onCancel,
    required this.onSave,
  });

  @override
  State<NuevoGastoModal> createState() => _NuevoGastoModalState();
}

class _NuevoGastoModalState extends State<NuevoGastoModal> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  // Controladores para todos los campos
  late TextEditingController _proveedorController;
  late TextEditingController _fechaController;
  late TextEditingController _totalController;
  late TextEditingController _monedaController;
  late TextEditingController _categoriaController;
  late TextEditingController _tipoGastoController;
  late TextEditingController _rucProveedorController;
  late TextEditingController _serieFacturaController;
  late TextEditingController _numeroFacturaController;
  late TextEditingController _tipoDocumentoController;
  late TextEditingController _numeroDocumentoController;
  late TextEditingController _notaController;
  late TextEditingController _politicaController;
  late TextEditingController _rucController;
  late TextEditingController _tipoComprobanteController;
  late TextEditingController _serieController;
  late TextEditingController _numeroController;
  late TextEditingController _igvController;
  late TextEditingController _rucClienteController;

  // Variables para archivos
  File? _selectedImage;
  File? _selectedFile;
  String? _selectedFileType; // 'image' o 'pdf'
  String? _selectedFileName;
  final ImagePicker _picker = ImagePicker();

  // Variables para el lector SUNAT
  bool _isScanning = false;
  bool _hasScannedData = false;

  // Variables para dropdowns
  List<DropdownOption> _categorias = [];
  List<DropdownOption> _tiposGasto = [];
  DropdownOption? _selectedCategoria;
  DropdownOption? _selectedTipoGasto;
  String? _selectedMoneda;

  // Estados de carga
  bool _isLoading = false;
  bool _isLoadingCategorias = false;
  bool _isLoadingTiposGasto = false;
  String? _error;

  // Opciones para moneda
  final List<String> _monedas = ['PEN', 'USD', 'EUR'];

  String get fechaSQL =>
      DateFormat('yyyy-MM-dd').format(DateTime.parse(_fechaController.text));

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
      text: DateTime.now().toString().split(' ')[0], // Fecha actual por defecto
    );
    _totalController = TextEditingController();
    _monedaController = TextEditingController(text: 'PEN'); // PEN por defecto
    _categoriaController = TextEditingController();
    _tipoGastoController = TextEditingController();
    _rucProveedorController = TextEditingController();
    _serieFacturaController = TextEditingController();
    _numeroFacturaController = TextEditingController();
    _tipoDocumentoController = TextEditingController();
    _numeroDocumentoController = TextEditingController();
    _notaController = TextEditingController();

    // Controladores adicionales que faltaban
    _politicaController = TextEditingController(
      text: widget.politicaSeleccionada.value,
    );
    _rucController = TextEditingController();
    _tipoComprobanteController = TextEditingController();
    _serieController = TextEditingController();
    _numeroController = TextEditingController();
    _igvController = TextEditingController();

    // Inicializar RUC Cliente con el RUC de la empresa actual (no editable)
    // El RUC Cliente siempre debe ser el de la empresa que registra el gasto
    final companyService = CompanyService();
    final currentCompany = companyService.currentCompany;
    _rucClienteController = TextEditingController(
      text: currentCompany?.ruc ?? '',
    );

    // Configurar valores por defecto
    _selectedMoneda = 'PEN';
  }

  @override
  void dispose() {
    _proveedorController.dispose();
    _fechaController.dispose();
    _totalController.dispose();
    _monedaController.dispose();
    _categoriaController.dispose();
    _tipoGastoController.dispose();
    _rucProveedorController.dispose();
    _serieFacturaController.dispose();
    _numeroFacturaController.dispose();
    _tipoDocumentoController.dispose();
    _numeroDocumentoController.dispose();
    _notaController.dispose();

    // Dispose de controladores adicionales
    _politicaController.dispose();
    _rucController.dispose();
    _tipoComprobanteController.dispose();
    _serieController.dispose();
    _numeroController.dispose();
    _igvController.dispose();
    _rucClienteController.dispose();

    super.dispose();
  }

  /// Cargar categorías desde la API filtradas por la política seleccionada
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
        _categorias = categorias;
        _isLoadingCategorias = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoadingCategorias = false;
      });
    }
  }

  /// Cargar tipos de gasto desde la API
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

  /// Seleccionar archivo (imagen o PDF)
  Future<void> _pickImage() async {
    try {
      setState(() => _isLoading = true);

      // Mostrar opciones para seleccionar tipo de archivo
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
                onPressed: () => Navigator.pop(context, 'pdf'),
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Archivo PDF'),
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
        if (selectedOption == 'camera') {
          // Tomar foto con la cámara
          final XFile? image = await _picker.pickImage(
            source: ImageSource.camera,
            imageQuality: 85,
          );
          if (image != null) {
            setState(() {
              _selectedImage = File(image.path);
              _selectedFile = File(image.path);
              _selectedFileType = 'image';
              _selectedFileName = image.name;
            });
          }
        } else if (selectedOption == 'gallery') {
          // Seleccionar imagen de la galería
          final XFile? image = await _picker.pickImage(
            source: ImageSource.gallery,
            imageQuality: 85,
          );
          if (image != null) {
            setState(() {
              _selectedImage = File(image.path);
              _selectedFile = File(image.path);
              _selectedFileType = 'image';
              _selectedFileName = image.name;
            });
          }
        } else if (selectedOption == 'pdf') {
          // Seleccionar archivo PDF
          final result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['pdf'],
            allowMultiple: false,
          );

          if (result != null && result.files.isNotEmpty) {
            final file = File(result.files.first.path!);
            setState(() {
              _selectedImage = null; // Limpiar imagen si había una
              _selectedFile = file;
              _selectedFileType = 'pdf';
              _selectedFileName = result.files.first.name;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar archivo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Mostrar selector de fecha
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _fechaController.text = picked.toString().split(' ')[0];
      });
    }
  }

  /// Guarda el gasto utilizando la API
  Future<void> _guardarGasto() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Debe adjuntar una evidencia (imagen o PDF)'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      try {
        // Mostrar indicador de carga
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const Dialog(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 20),
                    Text("Guardando gasto..."),
                  ],
                ),
              ),
            );
          },
        );

        // Obtener datos del usuario y empresa
        final userService = UserService();
        final companyService = CompanyService();

        final currentUser = userService.currentUser;
        final currentCompany = companyService.currentCompany;

        if (currentUser == null || currentCompany == null) {
          throw Exception('Error: Usuario o empresa no seleccionados');
        }

        // Preparar datos del gasto según la estructura de la API
        final gastoData = <String, dynamic>{
          // Campos requeridos por la API según factura_modal_peru.dart
          "idUser": UserService().currentUserCode,
          "dni": UserService().currentUserDni,
          "politica": _politicaController.text.length > 80
              ? _politicaController.text.substring(0, 80)
              : _politicaController.text,
          "categoria": _categoriaController.text.isEmpty
              ? "GENERAL"
              : (_categoriaController.text.length > 80
                    ? _categoriaController.text.substring(0, 80)
                    : _categoriaController.text),

          "tipoGasto": _tipoGastoController.text.isEmpty
              ? "GASTO GENERAL"
              : (_tipoGastoController.text.length > 80
                    ? _tipoGastoController.text.substring(0, 80)
                    : _tipoGastoController.text),
          "ruc": _rucController.text.isEmpty
              ? ""
              : (_rucController.text.length > 80
                    ? _rucController.text.substring(0, 80)
                    : _rucController.text),
          "proveedor": "",
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
          "rucCliente": CompanyService().currentCompany?.ruc ?? "",
          "desEmp": CompanyService().currentCompany?.empresa ?? '',
          "desSed": "",
          "idCuenta": "",
          "consumidor": "",
          "regimen": "",
          "destino": "BORRADOR",
          "glosa": _notaController.text.length > 480
              ? _notaController.text.substring(0, 480)
              : _notaController.text,
          "motivoViaje": "",
          "lugarOrigen": "",
          "lugarDestino": "",
          "tipoMovilidad": "",
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

        // Validaciones específicas
        if (gastoData['total'] <= 0) {
          throw Exception('El monto debe ser mayor a 0');
        }

        if (gastoData['razon'].toString().length > 100) {
          gastoData['razon'] = gastoData['razon'].toString().substring(0, 100);
        }

        // Enviar a la API
        final apiService = ApiService();

        // 🚨 IMPORTANTE: Si saverendiciongastoevidencia es el que GENERA el idRend,
        // entonces necesitamos cambiar el orden de los APIs

        // ✅ PRIMER API: Guardar datos principales de la factura (genera idRend automáticamente)
        // Nota: Verificar cuál endpoint realmente genera el idRend autoincrementable
        final idRend = await apiService.saveRendicionGasto(gastoData);

        if (idRend == null) {
          throw Exception(
            'No se pudo guardar la factura principal o no se obtuvo el ID autogenerado',
          );
        }

        debugPrint('🆔 ID autogenerado obtenido: $idRend');
        debugPrint('📋 Preparando datos de evidencia con el ID generado...');

        // ✅ SEGUNDO API: Guardar evidencia/archivo usando el idRend del primer API
        if (_selectedFile != null) {
          try {
            // Convertir archivo a base64 para la API
            final bytes = await _selectedFile!.readAsBytes();
            final base64String = base64Encode(bytes);

            final facturaDataEvidencia = {
              "idRend": idRend, // ✅ Usar el ID autogenerado del API principal
              "evidencia": base64String,
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

            // Usar el nuevo servicio API para guardar la evidencia
            final successEvidencia = await apiService
                .saveRendicionGastoEvidencia(facturaDataEvidencia);

            if (!successEvidencia) {
              debugPrint('⚠️ Advertencia: No se pudo guardar la evidencia');
            }
          } catch (e) {
            debugPrint('⚠️ Error al guardar evidencia: $e');
            // No fallar todo por la evidencia
          }
        }

        // Cerrar diálogo de carga
        Navigator.of(context).pop();

        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Factura guardada exitosamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Cerrar el modal y navegar a la pantalla de gastos
        Navigator.of(context).pop(); // Cerrar modal
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop(); // Cerrar pantalla QR si existe
        }

        // Navegar a HomeScreen con índice 0 (pestaña de Gastos)
        // Nota: Asegúrate de importar HomeScreen si no está importado
        // Navigator.of(context).pushAndRemoveUntil(
        //   MaterialPageRoute(builder: (context) => const HomeScreen()),
        //   (route) => false, // Remover todas las rutas anteriores
        // );
      } catch (e) {
        // Cerrar diálogo de carga si está abierto
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }

        // Extraer mensaje del servidor para mostrar en alerta
        final serverMessage = _extractServerMessage(e.toString());
        _showServerAlert(serverMessage);
      } finally {
        debugPrint('🔄 Finalizando proceso...');
      }
    }
  }

  /// Extrae el mensaje del servidor de un error
  String _extractServerMessage(String errorMessage) {
    try {
      // Buscar patrones comunes de errores del servidor
      if (errorMessage.contains('Exception:')) {
        final parts = errorMessage.split('Exception:');
        if (parts.length > 1) {
          return parts[1].trim();
        }
      }

      if (errorMessage.contains('Error:')) {
        final parts = errorMessage.split('Error:');
        if (parts.length > 1) {
          return parts[1].trim();
        }
      }

      // Si no encuentra un patrón específico, devolver el mensaje completo
      return errorMessage;
    } catch (e) {
      return 'Error desconocido al procesar la solicitud';
    }
  }

  /// Verifica si el mensaje indica que la factura ya está registrada
  bool _isFacturaDuplicada(String message) {
    final messageLower = message.toLowerCase();
    return messageLower.contains('ya existe') ||
        messageLower.contains('duplicad') ||
        messageLower.contains('already exists') ||
        messageLower.contains('ya registrada') ||
        messageLower.contains('duplicate') ||
        messageLower.contains('constraint') ||
        messageLower.contains('primary key');
  }

  /// Muestra una alerta con el mensaje del servidor
  void _showServerAlert(String message) {
    final isDuplicate = _isFacturaDuplicada(message);

    if (isDuplicate) {
      _showFacturaDuplicadaDialog(message);
    } else {
      _showErrorDialog(message);
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
                'Entendido',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
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
                    _buildLectorSunatSection(),
                    const SizedBox(height: 20),
                    _buildDatosGeneralesSection(),
                    const SizedBox(height: 20),
                    _buildDatosPersonalizadosSection(),
                    const SizedBox(height: 20),
                    _buildNotasSection(),
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
          colors: [Colors.green.shade700, Colors.green.shade400],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.add_business, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nuevo Gasto',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Política: ${widget.politicaSeleccionada.value}',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
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

  /// Construir la sección de adjuntar archivos
  Widget _buildImageSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.attach_file, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  'Adjuntar Evidencia',
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
                      (_selectedImage == null && _selectedFile == null)
                          ? Icons.add
                          : Icons.edit,
                    ),
                    label: Text(
                      (_selectedImage == null && _selectedFile == null)
                          ? 'Agregar'
                          : 'Cambiar',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Mostrar archivo seleccionado
            if (_selectedFile != null)
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _selectedFileType == 'image'
                    ? Container(
                        height: 200,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(_selectedFile!, fit: BoxFit.cover),
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.picture_as_pdf,
                              color: Colors.green,
                              size: 40,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Archivo PDF seleccionado',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _selectedFileName ?? 'archivo.pdf',
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 12,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 24,
                            ),
                          ],
                        ),
                      ),
              )
            else
              Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  border: Border.all(color: Colors.red.shade300, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.attach_file, color: Colors.red, size: 40),
                    const SizedBox(height: 8),
                    const Text(
                      'Agregar evidencia (Obligatorio)',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Imagen o PDF',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
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

  /// Construir la sección de datos generales
  Widget _buildDatosGeneralesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Datos Generales',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 16),

        // Proveedor
        TextFormField(
          controller: _proveedorController,
          decoration: const InputDecoration(
            labelText: 'Proveedor',
            hintText: 'Indica el proveedor',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.business),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'El proveedor es obligatorio';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),

        // Fecha
        TextFormField(
          controller: _fechaController,
          decoration: const InputDecoration(
            labelText: 'Fecha',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.calendar_today),
            suffixIcon: Icon(Icons.arrow_drop_down),
          ),
          readOnly: true,
          onTap: _selectDate,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'La fecha es obligatoria';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),

        // Total y Moneda en la misma fila
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _totalController,
                decoration: const InputDecoration(
                  labelText: 'Total',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El total es obligatorio';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Ingrese un valor válido';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedMoneda,
                decoration: const InputDecoration(
                  labelText: 'Moneda',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.monetization_on),
                ),
                items: _monedas.map((moneda) {
                  return DropdownMenuItem<String>(
                    value: moneda,
                    child: Text(moneda),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedMoneda = value;
                    _monedaController.text = value ?? '';
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Seleccione una moneda';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // RUC Cliente (no editable, siempre el RUC de la empresa)
        TextFormField(
          controller: _rucClienteController,
          decoration: const InputDecoration(
            labelText: 'RUC Cliente (Empresa)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.business),
            suffixIcon: Icon(Icons.lock, color: Colors.grey),
          ),
          enabled: false, // Campo no editable
          style: const TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// Construir la sección de datos personalizados
  Widget _buildDatosPersonalizadosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Datos Personalizados',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 16),

        // Categoría
        _buildCategoriaSection(),
        const SizedBox(height: 12),

        // Tipo de Gasto
        _buildTipoGastoSection(),
        const SizedBox(height: 12),

        // RUC Proveedor
        TextFormField(
          controller: _rucProveedorController,
          decoration: const InputDecoration(
            labelText: 'RUC Proveedor',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.badge),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value != null && value.isNotEmpty && value.length != 11) {
              return 'El RUC debe tener 11 dígitos';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),

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
        const SizedBox(height: 12),

        // Tipo de documento (solo lectura, se llena desde QR)
        TextFormField(
          controller: _tipoDocumentoController,
          decoration: const InputDecoration(
            labelText: 'Tipo de documento *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.description),
            hintText: 'Se llena automáticamente desde QR',
          ),
          readOnly: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Tipo de documento es obligatorio';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),

        // Número de documento
        TextFormField(
          controller: _numeroDocumentoController,
          decoration: const InputDecoration(
            labelText: 'Número de documento',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.numbers),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'El número de documento es obligatorio';
            }
            return null;
          },
        ),
      ],
    );
  }

  /// Construir la sección de categoría
  Widget _buildCategoriaSection() {
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
        ],
      );
    }

    if (_error != null) {
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
              border: Border.all(color: Colors.red.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.error, color: Colors.red.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Error cargando categorías: $_error',
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return DropdownButtonFormField<DropdownOption>(
      value: _selectedCategoria,
      decoration: const InputDecoration(
        labelText: 'Categoría',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.category),
      ),
      isExpanded: true,
      items: _categorias.map((categoria) {
        return DropdownMenuItem<DropdownOption>(
          value: categoria,
          child: Text(categoria.value),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCategoria = value;
          _categoriaController.text = value?.value ?? '';
        });
      },
      validator: (value) {
        if (value == null) {
          return 'Seleccione una categoría';
        }
        return null;
      },
    );
  }

  /// Construir la sección de tipo de gasto
  Widget _buildTipoGastoSection() {
    if (_isLoadingTiposGasto) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tipo de Gasto',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 8),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (_error != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tipo de Gasto',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              border: Border.all(color: Colors.red.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.error, color: Colors.red.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Error cargando tipos de gasto: $_error',
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return DropdownButtonFormField<DropdownOption>(
      value: _selectedTipoGasto,
      decoration: const InputDecoration(
        labelText: 'Tipo de Gasto',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.account_balance_wallet),
      ),
      isExpanded: true,
      items: _tiposGasto.map((tipoGasto) {
        return DropdownMenuItem<DropdownOption>(
          value: tipoGasto,
          child: Text(tipoGasto.value),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedTipoGasto = value;
          _tipoGastoController.text = value?.value ?? '';
        });
      },
      validator: (value) {
        if (value == null) {
          return 'Seleccione un tipo de gasto';
        }
        return null;
      },
    );
  }

  /// Construir la sección de notas
  Widget _buildNotasSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _notaController,
          decoration: const InputDecoration(
            labelText: 'Nota',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.note),
          ),
          maxLines: 3,
          maxLength: 500,
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
            child: OutlinedButton(
              onPressed: widget.onCancel,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Colors.grey),
              ),
              child: const Text(
                'Cancelar',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _guardarGasto,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Guardar',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
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
          _rucProveedorController.text = parts[0];
        }

        // Tipo de comprobante
        if (parts[1].isNotEmpty) {
          String tipoDoc = parts[1];
          switch (tipoDoc) {
            case '01':
              _tipoDocumentoController.text = 'FACTURA';
              break;
            case '03':
              _tipoDocumentoController.text = 'BOLETA DE VENTA';
              break;
            case '08':
              _tipoDocumentoController.text = 'NOTA DE DÉBITO';
              break;
            default:
              _tipoDocumentoController.text = 'COMPROBANTE';
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

  /// Limpiar los datos escaneados
  void _clearScannedData() {
    setState(() {
      _hasScannedData = false;

      // Limpiar los campos que se llenaron automáticamente
      _rucProveedorController.clear();
      _serieFacturaController.clear();
      _numeroFacturaController.clear();
      _tipoDocumentoController.clear();
      _numeroDocumentoController.clear();
      _totalController.clear();
      _fechaController.text = DateTime.now().toString().split(' ')[0];
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Datos del QR limpiados'),
        backgroundColor: Colors.orange,
      ),
    );
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
          Container(
            decoration: ShapeDecoration(
              shape: QrScannerOverlayShape(
                borderColor: Colors.blue,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: 250,
              ),
            ),
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

/// Shape personalizado para el overlay del escáner QR
class QrScannerOverlayShape extends ShapeBorder {
  const QrScannerOverlayShape({
    this.borderColor = Colors.blue,
    this.borderWidth = 3.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    double? cutOutSize,
  }) : cutOutSize = cutOutSize ?? 250;

  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path getLeftTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top + borderRadius)
        ..quadraticBezierTo(
          rect.left,
          rect.top,
          rect.left + borderRadius,
          rect.top,
        )
        ..lineTo(rect.right, rect.top);
    }

    return getLeftTopPath(rect)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..lineTo(rect.left, rect.top);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final height = rect.height;
    final cutOutWidth = cutOutSize < width ? cutOutSize : width - borderWidth;
    final cutOutHeight = cutOutSize < height
        ? cutOutSize
        : height - borderWidth;

    final backgroundPath = Path()
      ..addRect(rect)
      ..addOval(
        Rect.fromCenter(
          center: rect.center,
          width: cutOutWidth,
          height: cutOutHeight,
        ),
      )
      ..fillType = PathFillType.evenOdd;

    final backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    canvas.drawPath(backgroundPath, backgroundPaint);

    // Dibujar las esquinas del marco
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final path = Path();

    // Esquina superior izquierda
    path.moveTo(
      rect.center.dx - cutOutWidth / 2,
      rect.center.dy - cutOutHeight / 2 + borderLength,
    );
    path.lineTo(
      rect.center.dx - cutOutWidth / 2,
      rect.center.dy - cutOutHeight / 2,
    );
    path.lineTo(
      rect.center.dx - cutOutWidth / 2 + borderLength,
      rect.center.dy - cutOutHeight / 2,
    );

    // Esquina superior derecha
    path.moveTo(
      rect.center.dx + cutOutWidth / 2 - borderLength,
      rect.center.dy - cutOutHeight / 2,
    );
    path.lineTo(
      rect.center.dx + cutOutWidth / 2,
      rect.center.dy - cutOutHeight / 2,
    );
    path.lineTo(
      rect.center.dx + cutOutWidth / 2,
      rect.center.dy - cutOutHeight / 2 + borderLength,
    );

    // Esquina inferior derecha
    path.moveTo(
      rect.center.dx + cutOutWidth / 2,
      rect.center.dy + cutOutHeight / 2 - borderLength,
    );
    path.lineTo(
      rect.center.dx + cutOutWidth / 2,
      rect.center.dy + cutOutHeight / 2,
    );
    path.lineTo(
      rect.center.dx + cutOutWidth / 2 - borderLength,
      rect.center.dy + cutOutHeight / 2,
    );

    // Esquina inferior izquierda
    path.moveTo(
      rect.center.dx - cutOutWidth / 2 + borderLength,
      rect.center.dy + cutOutHeight / 2,
    );
    path.lineTo(
      rect.center.dx - cutOutWidth / 2,
      rect.center.dy + cutOutHeight / 2,
    );
    path.lineTo(
      rect.center.dx - cutOutWidth / 2,
      rect.center.dy + cutOutHeight / 2 - borderLength,
    );

    canvas.drawPath(path, borderPaint);
  }

  @override
  ShapeBorder scale(double t) {
    return QrScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth,
      overlayColor: overlayColor,
    );
  }
}
