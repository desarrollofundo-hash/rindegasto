import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../models/reporte_model.dart';
import '../models/categoria_model.dart';
import '../models/dropdown_option.dart';
import '../services/api_service.dart';
import '../services/company_service.dart';
import '../screens/home_screen.dart';

class EditReporteModal extends StatefulWidget {
  final Reporte reporte;
  final Function(Reporte)? onSave;

  const EditReporteModal({super.key, required this.reporte, this.onSave});

  @override
  State<EditReporteModal> createState() => _EditReporteModalState();
}

class _EditReporteModalState extends State<EditReporteModal> {
  // Controladores para cada campo
  late TextEditingController _politicaController;
  late TextEditingController _categoriaController;
  late TextEditingController _tipoGastoController;
  late TextEditingController _rucController;
  late TextEditingController _proveedorController;
  late TextEditingController _tipoComprobanteController;
  late TextEditingController _serieController;
  late TextEditingController _numeroController;
  late TextEditingController _fechaController;
  late TextEditingController _totalController;
  late TextEditingController _monedaController;
  late TextEditingController _rucClienteController;
  late TextEditingController _glosaController;
  late TextEditingController _obsController;
  late TextEditingController _igvController;
  late TextEditingController _fechaEmisionController;
  late TextEditingController _notaController;

  // Variables para manejo de imagen
  File? _selectedImage;
  File?
  _selectedFile; // Archivo seleccionado (si se implementa selección de archivos)
  File? _selectedFileType; // Tipo de archivo seleccionado (si se implementa)
  File? _selectedFileName; // Nombre del archivo seleccionado (si se implementa)

  String? _apiEvidencia; // URL de la evidencia que viene de la API
  final ImagePicker _picker = ImagePicker();
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  bool _isEditMode = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Servicios para cargar datos

  // Listas para dropdowns
  List<DropdownOption> _politicas = [];
  List<CategoriaModel> _categoriasGeneral = [];
  List<DropdownOption> _tiposGasto = [];

  // Variables de estado para carga
  bool _isLoadingPoliticas = false;
  bool _isLoadingCategorias = false;
  bool _isLoadingTiposGasto = false;

  // Variables para errores
  String? _errorCategorias;
  String? _errorTiposGasto;

  // Valores seleccionados para dropdowns
  String? _selectedPolitica;

  // Variables para validación de campos obligatorios
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeSelectedValues();
    _initializeEvidencia();
    _loadPoliticas();
    _loadCategorias(); // Carga todas las categorías inicialmente
    _loadTiposGasto();
    _addValidationListeners();
  }

  /// Inicializar la evidencia de la API
  void _initializeEvidencia() {
    print('🔍 Iniciando inicialización de evidencia...');
    print('🔍 widget.reporte.evidencia: ${widget.reporte.evidencia}');

    if (widget.reporte.evidencia != null) {
      print('🔍 Evidencia no es null');

      if (widget.reporte.evidencia!.isNotEmpty) {
        final evidencia = widget.reporte.evidencia!.trim();
        print('🔍 Evidencia después de trim: "$evidencia"');

        // Simplificar validación temporalmente para debugging
        if (evidencia.isNotEmpty) {
          _apiEvidencia = evidencia;
          print('✅ Evidencia asignada: $_apiEvidencia');
        } else {
          print('❌ Evidencia vacía después de trim');
          _apiEvidencia = null;
        }
      } else {
        print('❌ Evidencia está vacía');
        _apiEvidencia = null;
      }
    } else {
      print('❌ widget.reporte.evidencia es null');
      _apiEvidencia = null;
    }

    print('🔍 Estado final _apiEvidencia: $_apiEvidencia');
  }

  /// Validar si una URL es válida
  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.isAbsolute &&
          (uri.scheme == 'http' || uri.scheme == 'https') &&
          uri.host.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Verificar si una string es base64 válido
  bool _isBase64(String str) {
    try {
      print('🔍 Verificando si es base64...');
      print('🔍 Longitud: ${str.length}');
      print(
        '🔍 Primeros 20 chars: ${str.substring(0, str.length > 20 ? 20 : str.length)}',
      );

      // Verificar longitud mínima
      String cleanStr = str.trim();
      if (cleanStr.length < 4) {
        print('❌ Muy corto para ser base64');
        return false;
      }

      // Verificar si se ve como base64 (contiene caracteres típicos)
      bool looksLikeBase64 =
          cleanStr.contains('data:image') ||
          cleanStr.startsWith('/9j/') ||
          cleanStr.startsWith('iVBOR') ||
          cleanStr.startsWith('R0lGOD') ||
          cleanStr.length > 100; // Imagen base64 típicamente es larga

      print('🔍 Se ve como base64?: $looksLikeBase64');

      if (looksLikeBase64) {
        // Intentar decodificar
        base64Decode(cleanStr);
        print('✅ Decodificación exitosa - ES BASE64');
        return true;
      }

      print('❌ No se ve como base64');
      return false;
    } catch (e) {
      print('❌ Error al decodificar base64: $e');
      return false;
    }
  }

  /// Crear widget de imagen basado en el tipo de evidencia
  Widget _buildEvidenciaImage(String evidencia) {
    print('🖼️ Construyendo imagen de evidencia...');
    print('🖼️ Longitud de evidencia: ${evidencia.length}');

    if (_isBase64(evidencia)) {
      print('✅ Detectado como BASE64 - usando Image.memory');
      // Es base64, usar Image.memory
      try {
        final Uint8List bytes = base64Decode(evidencia);
        print('✅ Decodificación exitosa, bytes: ${bytes.length}');
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('🔴 Error mostrando imagen desde bytes: $error');
            return _buildErrorWidget('Error al mostrar imagen decodificada');
          },
        );
      } catch (e) {
        print('🔴 Error al decodificar base64 en buildImage: $e');
        return _buildErrorWidget('Error al decodificar imagen base64');
      }
    } else if (_isValidUrl(evidencia)) {
      print('✅ Detectado como URL - usando Image.network');
      // Es URL, usar Image.network
      return Image.network(
        evidencia,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return SizedBox(
            height: 200,
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          print('🔴 Error cargando imagen de URL: $error');
          return _buildErrorWidget('Error al cargar imagen desde URL');
        },
      );
    } else {
      // No es ni base64 ni URL válida
      return _buildErrorWidget('Formato de evidencia no válido');
    }
  }

  /// Widget de error para mostrar cuando hay problemas con la imagen
  Widget _buildErrorWidget(String message) {
    return SizedBox(
      height: 200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, color: Colors.red, size: 40),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Evidencia: ${_apiEvidencia?.substring(0, 50) ?? "N/A"}...',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Agregar listeners para validación en tiempo real
  void _addValidationListeners() {
    _rucController.addListener(_validateForm);
    _rucClienteController.addListener(_validateForm);
    _tipoComprobanteController.addListener(_validateForm);
    _serieController.addListener(_validateForm);
    _numeroController.addListener(_validateForm);
    _fechaEmisionController.addListener(_validateForm);
    _totalController.addListener(_validateForm);
    _categoriaController.addListener(_validateForm);
    _tipoGastoController.addListener(_validateForm);
  }

  /// Validar si el RUC del cliente (escaneado) coincide con la empresa seleccionada
  bool _isRucValid() {
    final rucClienteEscaneado = _rucClienteController.text.trim();
    final rucEmpresaSeleccionada = CompanyService().companyRuc;

    // Si no hay RUC del cliente escaneado o no hay empresa seleccionada, consideramos válido
    if (rucClienteEscaneado.isEmpty || rucEmpresaSeleccionada.isEmpty) {
      return true;
    }

    return rucClienteEscaneado == rucEmpresaSeleccionada;
  }

  /// Obtener mensaje de estado del RUC del cliente
  String _getRucStatusMessage() {
    final rucClienteEscaneado = _rucClienteController.text.trim();
    final rucEmpresaSeleccionada = CompanyService().companyRuc;
    final empresaSeleccionada = CompanyService().currentUserCompany;

    if (rucClienteEscaneado.isEmpty) {
      return '';
    }

    if (rucEmpresaSeleccionada.isEmpty) {
      return '⚠️ No hay empresa seleccionada';
    }

    if (rucClienteEscaneado == rucEmpresaSeleccionada) {
      return '✅ RUC cliente coincide con $empresaSeleccionada';
    } else {
      return '❌ RUC cliente no coincide con $empresaSeleccionada';
    }
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
        _categoriaController.text.trim().isNotEmpty &&
        _tipoGastoController.text.trim().isNotEmpty &&
        (_selectedImage != null ||
            (_apiEvidencia != null && _apiEvidencia!.isNotEmpty)) &&
        _isRucValid();

    if (_isFormValid != isValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }

  void _initializeSelectedValues() {
    // Para política se validará después de cargar desde API
    _selectedPolitica = widget.reporte.politica?.trim().isNotEmpty == true
        ? widget.reporte.politica
        : null;
    print('🔍 Política inicial: ${widget.reporte.politica}');
    print('🔍 Política seleccionada: $_selectedPolitica');

    // Para categoría y tipo de gasto, se validarán después de cargar desde API
    // Las variables se inicializan en los métodos correspondientes
  }

  /// Cargar políticas desde la API
  Future<void> _loadPoliticas() async {
    if (!mounted) return;
    setState(() {
      _isLoadingPoliticas = true;
    });

    try {
      final politicas = await _apiService.getRendicionPoliticas();
      print('🚀 Políticas cargadas: ${politicas.length}');
      for (var pol in politicas) {
        print('  - ${pol.value}');
      }
      if (!mounted) return;
      setState(() {
        _politicas = politicas;
        _isLoadingPoliticas = false;
        // No cambiar _selectedPolitica aquí, mantener el valor original para mostrarlo
        print('🎯 Política seleccionada mantenida: $_selectedPolitica');
      });
    } catch (e) {
      print('❌ Error cargando políticas: $e');
      if (!mounted) return;
      setState(() {
        _isLoadingPoliticas = false;
        // Mantener el valor original incluso si hay error
      });
    }
  }

  /// Cargar categorías desde la API
  Future<void> _loadCategorias({String? politicaFiltro}) async {
    if (!_politicaController.text.toLowerCase().contains('general') &&
        politicaFiltro == null) {
      return; // Solo cargar para política GENERAL
    }

    if (!mounted) return;
    setState(() {
      _isLoadingCategorias = true;
      _errorCategorias = null;
    });

    try {
      // Si hay una política específica, filtrar por ella; sino, obtener todas
      final categorias = await _apiService.getRendicionCategorias(
        politica: politicaFiltro ?? 'todos',
      );
      print(
        '🚀 Categorías cargadas: ${categorias.length} para política: ${politicaFiltro ?? "todas"}',
      );

      // Convertir DropdownOption a CategoriaModel para mantener compatibilidad
      final categoriasModelo = categorias
          .map(
            (cat) => CategoriaModel(
              id: cat.id,
              politica: politicaFiltro ?? '',
              categoria: cat.value,
              estado: 'S',
            ),
          )
          .toList();

      if (!mounted) return;
      setState(() {
        _categoriasGeneral = categoriasModelo;
        _isLoadingCategorias = false;
        // Mantener el valor original para mostrarlo
      });
    } catch (e) {
      print('❌ Error cargando categorías: $e');
      if (!mounted) return;
      setState(() {
        _errorCategorias = e.toString();
        _isLoadingCategorias = false;
        // Mantener el valor original incluso si hay error
      });
    }
  }

  /// Cargar tipos de gasto desde la API
  Future<void> _loadTiposGasto() async {
    if (!mounted) return;
    setState(() {
      _isLoadingTiposGasto = true;
      _errorTiposGasto = null;
    });

    try {
      final tiposGasto = await _apiService.getTiposGasto();
      if (!mounted) return;
      setState(() {
        _tiposGasto = tiposGasto;
        _isLoadingTiposGasto = false;
        // No cambiar _selectedTipoGasto aquí, mantener el valor original para mostrarlo
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorTiposGasto = e.toString();
        _isLoadingTiposGasto = false;
        // Mantener el valor original incluso si hay error
      });
    }
  }

  void _initializeControllers() {
    _politicaController = TextEditingController(
      text: widget.reporte.politica ?? '',
    );
    _categoriaController = TextEditingController(
      text: widget.reporte.categoria ?? '',
    );
    _tipoGastoController = TextEditingController(
      text: widget.reporte.tipogasto ?? '',
    );
    _rucController = TextEditingController(text: widget.reporte.ruc ?? '');
    _proveedorController = TextEditingController(
      text: widget.reporte.proveedor ?? '',
    );
    _tipoComprobanteController = TextEditingController(
      text: widget.reporte.tipocomprobante ?? '',
    );
    _serieController = TextEditingController(text: widget.reporte.serie ?? '');
    _numeroController = TextEditingController(
      text: widget.reporte.numero ?? '',
    );
    _fechaController = TextEditingController(text: widget.reporte.fecha ?? '');
    _totalController = TextEditingController(
      text: widget.reporte.total?.toString() ?? '',
    );
    _monedaController = TextEditingController(
      text: widget.reporte.moneda ?? 'PEN',
    );
    _rucClienteController = TextEditingController(
      text: widget.reporte.ruccliente ?? '',
    );
    _glosaController = TextEditingController(text: widget.reporte.glosa ?? '');
    _obsController = TextEditingController(text: widget.reporte.obs ?? '');

    // Nuevos controladores
    _igvController = TextEditingController(text: widget.reporte.serie ?? '');
    _fechaEmisionController = TextEditingController(
      text: widget.reporte.fecha ?? '',
    );
    _notaController = TextEditingController(text: widget.reporte.obs ?? '');
  }

  @override
  void dispose() {
    // Remover listeners antes de dispose
    _rucController.removeListener(_validateForm);
    _rucClienteController.removeListener(_validateForm);
    _tipoComprobanteController.removeListener(_validateForm);
    _serieController.removeListener(_validateForm);
    _numeroController.removeListener(_validateForm);
    _fechaEmisionController.removeListener(_validateForm);
    _totalController.removeListener(_validateForm);
    _categoriaController.removeListener(_validateForm);
    _tipoGastoController.removeListener(_validateForm);

    // Dispose de los controladores
    _politicaController.dispose();
    _categoriaController.dispose();
    _tipoGastoController.dispose();
    _rucController.dispose();
    _proveedorController.dispose();
    _tipoComprobanteController.dispose();
    _serieController.dispose();
    _numeroController.dispose();
    _fechaController.dispose();
    _totalController.dispose();
    _monedaController.dispose();
    _rucClienteController.dispose();
    _glosaController.dispose();
    _obsController.dispose();
    _igvController.dispose();
    _fechaEmisionController.dispose();
    _notaController.dispose();

    _apiService.dispose();
    super.dispose();
  }

  /// Convertir imagen a base64

  Future<String> _convertImageToBase64(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    return base64Encode(bytes);
  }

  /// Seleccionar imagen desde la cámara
  Future<void> _pickImage() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Seleccionar'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Tomar foto'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromCamera();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galería'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf),
                title: const Text('PDF'),
                onTap: () {
                  Navigator.pop(context);
                  _pickPDFFile();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickFromCamera() async {
    try {
      setState(() => _isLoading = true);

      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null && mounted) {
        final file = File(image.path);
        if (await file.exists()) {
          setState(() => _selectedImage = file);
          _validateForm();
          print('📷 Imagen capturada exitosamente: ${file.path}');
        } else {
          throw Exception('El archivo de imagen no se pudo crear');
        }
      }
    } catch (e) {
      print('🔴 Error al capturar imagen: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al capturar imagen: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      setState(() => _isLoading = true);

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null && mounted) {
        final file = File(image.path);
        if (await file.exists()) {
          setState(() => _selectedImage = file);
          _validateForm();
          print('🖼️ Imagen seleccionada de galería: ${file.path}');
        } else {
          throw Exception('El archivo de imagen no se pudo crear');
        }
      }
    } catch (e) {
      print('🔴 Error al seleccionar imagen de galería: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickPDFFile() async {
    try {
      setState(() => _isLoading = true);

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && mounted) {
        final file = File(result.files.single.path!);
        if (await file.exists()) {
          setState(
            () => _selectedImage = file,
          ); // Usamos _selectedImage para mantener compatibilidad
          _validateForm();
          print('📄 PDF seleccionado: ${file.path}');
        } else {
          throw Exception('El archivo PDF no se pudo acceder');
        }
      }
    } catch (e) {
      print('🔴 Error al seleccionar PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar PDF: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Mostrar alerta en medio de la pantalla con mensaje del servidor
  void _showServerAlert(String message) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.symmetric(horizontal: 40),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Error del Servidor',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.red,
                  ),
                  child: const Text('OK'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Extraer mensaje del servidor desde el error
  String _extractServerMessage(String error) {
    try {
      // Buscar patrones comunes de mensajes de error del servidor
      if (error.contains('Exception:')) {
        return error.split('Exception:').last.trim();
      }
      if (error.contains('Error:')) {
        return error.split('Error:').last.trim();
      }
      return error.length > 100 ? '${error.substring(0, 100)}...' : error;
    } catch (e) {
      return 'Error interno del servidor';
    }
  }

  /// Verificar si un archivo es PDF basado en su extensión
  bool _isPdfFile(String filePath) {
    return filePath.toLowerCase().endsWith('.pdf');
  }

  /// Construir la sección de imagen/evidencia
  Widget _buildImageSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(6),
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
                      onPressed: _isEditMode ? _pickImage : null,
                      icon: Icon(
                        (_selectedImage == null &&
                                (_apiEvidencia == null ||
                                    _apiEvidencia!.isEmpty))
                            ? Icons.add_a_photo
                            : Icons.edit,
                      ),
                      label: Text(
                        (_selectedImage == null &&
                                (_apiEvidencia == null ||
                                    _apiEvidencia!.isEmpty))
                            ? 'Seleccionar'
                            : 'Cambiar archivo',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isEditMode ? Colors.red : Colors.grey,
                        foregroundColor: Colors.white,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // Mostrar archivo: puede ser imagen o PDF
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
                    child: _isPdfFile(_selectedImage!.path)
                        ? Container(
                            color: Colors.grey.shade100,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.picture_as_pdf,
                                  size: 48,
                                  color: Colors.red,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'PDF: ${_selectedImage!.path.split('/').last}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : Image.file(_selectedImage!, fit: BoxFit.cover),
                  ),
                )
              else if (_apiEvidencia != null && _apiEvidencia!.isNotEmpty)
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildEvidenciaImage(_apiEvidencia!),
                  ),
                )
              else
                Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    border: Border.all(
                      color:
                          (_selectedImage == null &&
                              (_apiEvidencia == null || _apiEvidencia!.isEmpty))
                          ? Colors.red.shade300
                          : Colors.grey.shade300,
                      width:
                          (_selectedImage == null &&
                              (_apiEvidencia == null || _apiEvidencia!.isEmpty))
                          ? 2
                          : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_outlined,
                        color:
                            (_selectedImage == null &&
                                (_apiEvidencia == null ||
                                    _apiEvidencia!.isEmpty))
                            ? Colors.red
                            : Colors.grey,
                        size: 40,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Agregar evidencia (Obligatorio)',
                        style: TextStyle(
                          color:
                              (_selectedImage == null &&
                                  (_apiEvidencia == null ||
                                      _apiEvidencia!.isEmpty))
                              ? Colors.red
                              : Colors.grey,
                          fontWeight:
                              (_selectedImage == null &&
                                  (_apiEvidencia == null ||
                                      _apiEvidencia!.isEmpty))
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
      ),
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

    return AbsorbPointer(
      absorbing: !_isEditMode,
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: 'Categoría *',
          prefixIcon: Icon(Icons.category),
          border: OutlineInputBorder(),
          filled: true,
          fillColor: _isEditMode ? Colors.white : Colors.grey[100],
        ),
        value:
            _categoriaController.text.isNotEmpty &&
                items.any((item) => item.value == _categoriaController.text)
            ? _categoriaController.text
            : null,
        items: items,
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

  /// Construir la sección de tipo de gasto
  Widget _buildTipoGastoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tipo de Gasto',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),

        // Si está cargando, mostrar indicador
        if (_isLoadingTiposGasto)
          const Column(
            children: [
              Center(child: CircularProgressIndicator()),
              SizedBox(height: 8),
              Text(
                'Cargando tipos de gasto...',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          )
        else if (_errorTiposGasto != null)
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
                    'Error al cargar tipos de gasto: $_errorTiposGasto',
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
          AbsorbPointer(
            absorbing: !_isEditMode,
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Tipo de Gasto *',
                prefixIcon: Icon(Icons.attach_money),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: _isEditMode ? Colors.white : Colors.grey[100],
              ),
              value:
                  _tipoGastoController.text.isNotEmpty &&
                      _tiposGasto.any(
                        (tipo) => tipo.value == _tipoGastoController.text,
                      )
                  ? _tipoGastoController.text
                  : null,
              items: _tiposGasto
                  .map(
                    (tipo) => DropdownMenuItem<String>(
                      value: tipo.value,
                      child: Text(tipo.value),
                    ),
                  )
                  .toList(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Tipo de gasto es obligatorio';
                }
                return null;
              },
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _tipoGastoController.text = value;
                  });
                  _validateForm(); // Validar cuando cambie el tipo de gasto
                }
              },
            ),
          ),
      ],
    );
  }

  /// Construir la sección de datos raw
  Widget _buildRawDataSection() {
    return ExpansionTile(
      title: const Text('Datos Originales del Reporte'),
      leading: const Icon(Icons.receipt_long),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: SelectableText(
            'ID: ${widget.reporte.idrend}\n'
            'Política: ${widget.reporte.politica}\n'
            'Categoría: ${widget.reporte.categoria}\n'
            'RUC: ${widget.reporte.ruc}\n'
            'Proveedor: ${widget.reporte.proveedor}\n'
            'Serie: ${widget.reporte.serie}\n'
            'Número: ${widget.reporte.numero}\n'
            'Total: ${widget.reporte.total}\n'
            'Fecha: ${widget.reporte.fecha}\n'
            'Estado: ${widget.reporte.categoria}',
            style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
          ),
        ),
      ],
    );
  }

  /// Guardar factura mediante API
  Future<void> _updateFacturaAPI() async {
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

    // 🔍 VALIDACIÓN: RUC del cliente escaneado debe coincidir con empresa seleccionada
    final rucClienteEscaneado = _rucClienteController.text.trim();
    final rucEmpresaSeleccionada = CompanyService().companyRuc;

    if (rucClienteEscaneado.isNotEmpty && rucEmpresaSeleccionada.isNotEmpty) {
      if (rucClienteEscaneado != rucEmpresaSeleccionada) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '❌ RUC del cliente no coincide con la empresa seleccionada',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text('RUC cliente escaneado: $rucClienteEscaneado'),
                Text('RUC empresa: $rucEmpresaSeleccionada'),
                Text('Empresa: ${CompanyService().currentUserCompany}'),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
        return;
      }
    }

    try {
      if (mounted) setState(() => _isLoading = true);

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

      // 📋 DATOS PRINCIPALES DE LA FACTURA
      // Este objeto contiene toda la información principal de la factura
      // que será enviada al API que debe generar el idRend automáticamente
      final facturaData = {
        "idRend":
            widget.reporte.idrend, // Siempre 0 para que el API genere uno nuevo
        "idUser": widget.reporte.iduser,
        "dni": widget.reporte.dni,
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
        "rucCliente": _rucClienteController.text.isEmpty
            ? ""
            : (_rucClienteController.text.length > 80
                  ? _rucClienteController.text.substring(0, 80)
                  : _rucClienteController.text),
        "desEmp": CompanyService().currentCompany?.empresa ?? '',
        "desSed": "",
        "idCuenta": "",
        "consumidor": "",
        "regimen": "",
        "destino": "",
        "glosa": "",
        "motivoViaje": "",
        "lugarOrigen": "",
        "lugarDestino": "",
        "tipoMovilidad": "",
        "obs": _notaController.text.length > 1000
            ? _notaController.text.substring(0, 1000)
            : _notaController.text,
        "estado": "S", // Solo 1 carácter como requiere la BD
        "fecCre": DateTime.now().toIso8601String(),
        "useReg": widget.reporte.iduser, // Campo obligatorio
        "hostname": "FLUTTER", // Campo obligatorio, máximo 50 caracteres
        "fecEdit": DateTime.now().toIso8601String(),
        "useEdit": widget.reporte.iduser,
        "useElim": 0,
      };

      // 🚨 IMPORTANTE: Si saverendiciongastoevidencia es el que GENERA el idRend,
      // entonces necesitamos cambiar el orden de los APIs

      // ✅ PRIMER API: Guardar datos principales de la factura (genera idRend automáticamente)
      // Nota: Verificar cuál endpoint realmente genera el idRend autoincrementable
      await _apiService.saveupdateRendicionGasto(facturaData);

      //idRend del primer API
      final evidenciaString = _selectedImage != null
          ? await _convertImageToBase64(_selectedImage!)
          : (_apiEvidencia ?? "");

      print('📸 Enviando evidencia:');
      print('📸 _selectedImage != null: ${_selectedImage != null}');
      print('📸 _apiEvidencia: ${_apiEvidencia ?? "null"}');
      print('📸 evidenciaString length: ${evidenciaString.length}');
      print(
        '📸 evidenciaString preview: ${evidenciaString.substring(0, evidenciaString.length > 50 ? 50 : evidenciaString.length)}...',
      );

      final facturaDataEvidencia = {
        "idRend": widget
            .reporte
            .idrend, // ✅ Usar el ID autogenerado del API principal
        "evidencia": evidenciaString,
        "obs": _notaController.text.length > 1000
            ? _notaController.text.substring(0, 1000)
            : _notaController.text,
        "estado": "S", // Solo 1 carácter como requiere la BD
        "fecCre": DateTime.now().toIso8601String(),
        "useReg": widget.reporte.iduser, // Campo obligatorio
        "hostname": "FLUTTER", // Campo obligatorio, máximo 50 caracteres
        "fecEdit": DateTime.now().toIso8601String(),
        "useEdit": widget.reporte.iduser,
        "useElim": 0,
      };

      // Usar el nuevo servicio API para guardar la evidencia
      final successEvidencia = await _apiService.saveRendicionGastoEvidencia(
        facturaDataEvidencia,
      );

      print('📸 saveRendicionGastoEvidencia result: $successEvidencia');

      if (successEvidencia && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ FACTURA ACTUALIZADA'),
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
    } catch (e) {
      print('💥 Error capturado: $e');
      if (mounted) {
        // Extraer mensaje del servidor para mostrar en alerta
        final serverMessage = _extractServerMessage(e.toString());
        _showServerAlert(serverMessage);
      }
    } finally {
      print('🔄 Finalizando proceso...');
      if (mounted) {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text("Reporte actualizado correctamente"),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
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
                    const SizedBox(height: 20),
                    _buildCategorySection(),
                    const SizedBox(height: 20),
                    _buildTipoGastoSection(),
                    const SizedBox(height: 20),
                    _buildInvoiceDataSection(),
                    const SizedBox(height: 20),
                    _buildNotesSection(),
                    const SizedBox(height: 20),
                    _buildRawDataSection(),
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
                  'Editar Reporte',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Modifica los datos del reporte',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
          // Botón editar (solo icono)
          if (!_isEditMode)
            IconButton(
              onPressed: () {
                print('📝 Activando modo edición');
                print('Políticas disponibles: ${_politicas.length}');
                print('Política actual: $_selectedPolitica');
                setState(() {
                  _isEditMode = true;
                });
              },
              icon: const Icon(Icons.edit, color: Colors.white, size: 24),
              tooltip: 'Editar campos',
            ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
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

  /// Construir la sección de datos de la factura
  Widget _buildInvoiceDataSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Primera fila: RUC y Tipo de Comprobante
        _buildTextField(
          _rucController,
          'RUC ',
          Icons.business,
          TextInputType.number,
          isRequired: true,
          readOnly: true,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          _tipoComprobanteController,
          'Tipo Comprobante ',
          Icons.receipt_long,
          TextInputType.text,
          isRequired: true,
          readOnly: true,
        ),
        const SizedBox(height: 16),

        // Segunda fila: Serie y Número
        _buildTextField(
          _serieController,
          'Serie ',
          Icons.tag,
          TextInputType.text,
          isRequired: true,
          readOnly: true,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          _numeroController,
          'Número ',
          Icons.confirmation_number,
          TextInputType.number,
          isRequired: true,
          readOnly: true,
        ),
        const SizedBox(height: 16),

        // Tercera fila: IGV/Código y Fecha de Emisión
        _buildTextField(
          _igvController,
          'IGV/Código',
          Icons.percent,
          TextInputType.text,
          readOnly: true,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          _fechaEmisionController,
          'Fecha Emisión ',
          Icons.calendar_today,
          TextInputType.datetime,
          isRequired: true,
          readOnly: true,
        ),
        const SizedBox(height: 16),

        // Cuarta fila: Total y Moneda
        _buildTextField(
          _totalController,
          'Total ',
          Icons.attach_money,
          TextInputType.numberWithOptions(decimal: true),
          isRequired: true,
          readOnly: true,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          _monedaController,
          'Moneda *',
          Icons.monetization_on,
          TextInputType.text,
          readOnly: true,
        ),
        const SizedBox(height: 16),

        // Quinta fila: RUC Cliente (solo lectura)
        _buildTextField(
          _rucClienteController,
          'RUC Cliente * ',
          Icons.person,
          TextInputType.number,
          readOnly: true,
        ),

        // 🔍 Mensaje de validación del RUC Cliente
        if (_rucClienteController.text.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 4, bottom: 8),
            child: Row(
              children: [
                Icon(
                  _isRucValid() ? Icons.check_circle : Icons.error,
                  size: 16,
                  color: _isRucValid() ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _getRucStatusMessage(),
                    style: TextStyle(
                      fontSize: 12,
                      color: _isRucValid() ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Dropdown específico para políticas
  Widget _buildDropdownFieldPoliticas({
    required String label,
    required String? value,
    required ValueChanged<String?>? onChanged,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: _isEditMode ? Colors.white : Colors.grey[100],
            border: Border.all(color: Colors.grey[300]!, width: 1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: _isEditMode
              ? (_isLoadingPoliticas
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Text("Cargando políticas..."),
                          ],
                        ),
                      )
                    : _politicas.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          "No hay políticas disponibles",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      )
                    : DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value:
                              (value != null &&
                                  _politicas.any((pol) => pol.value == value))
                              ? value
                              : null,
                          isExpanded: true,
                          hint: Text(
                            hint,
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                          ),
                          items: _politicas.map((DropdownOption politica) {
                            return DropdownMenuItem<String>(
                              value: politica.value,
                              child: Text(
                                politica.value,
                                style: const TextStyle(fontSize: 14),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedPolitica = newValue;
                            });
                            onChanged?.call(newValue);

                            // Recargar categorías cuando cambie la política
                            if (newValue != null) {
                              _loadCategorias(politicaFiltro: newValue);
                              // Limpiar categoría seleccionada al cambiar política
                              setState(() {
                                // Variable eliminada
                              });
                            }
                          },
                        ),
                      ))
              : Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    value ?? hint,
                    style: TextStyle(
                      fontSize: 14,
                      color: value != null
                          ? Colors.grey[600]
                          : Colors.grey[400],
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  /// Dropdown específico para categorías
  Widget _buildDropdownFieldCategorias({
    required String label,
    required String? value,
    required ValueChanged<String?>? onChanged,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: _isEditMode ? Colors.white : Colors.grey[100],
            border: Border.all(color: Colors.grey[300]!, width: 1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: _isEditMode
              ? _isLoadingCategorias
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Text("Cargando categorías..."),
                          ],
                        ),
                      )
                    : DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value:
                              _isEditMode &&
                                  _categoriasGeneral.any(
                                    (cat) => cat.categoria == value,
                                  )
                              ? value
                              : null, // Solo validar en modo edición
                          isExpanded: true,
                          hint: Text(
                            hint,
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                          ),
                          items: _categoriasGeneral.map((
                            CategoriaModel categoria,
                          ) {
                            return DropdownMenuItem<String>(
                              value: categoria.categoria,
                              child: Text(
                                categoria.categoria,
                                style: const TextStyle(fontSize: 14),
                              ),
                            );
                          }).toList(),
                          onChanged: onChanged,
                        ),
                      )
              : Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    value ?? hint,
                    style: TextStyle(
                      fontSize: 14,
                      color: value != null
                          ? Colors.grey[600]
                          : Colors.grey[400],
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  /// Dropdown específico para tipos de gasto
  Widget _buildDropdownFieldTiposGasto({
    required String label,
    required String? value,
    required ValueChanged<String?>? onChanged,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: _isEditMode ? Colors.white : Colors.grey[100],
            border: Border.all(color: Colors.grey[300]!, width: 1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: _isEditMode
              ? (_isLoadingTiposGasto
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Text("Cargando tipos de gasto..."),
                          ],
                        ),
                      )
                    : DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value:
                              _isEditMode &&
                                  _tiposGasto.any((tipo) => tipo.value == value)
                              ? value
                              : null, // Solo validar en modo edición
                          isExpanded: true,
                          hint: Text(
                            hint,
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                          ),
                          items: _tiposGasto.map((DropdownOption tipo) {
                            return DropdownMenuItem<String>(
                              value: tipo.value,
                              child: Text(
                                tipo.value,
                                style: const TextStyle(fontSize: 14),
                              ),
                            );
                          }).toList(),
                          onChanged: onChanged,
                        ),
                      ))
              : Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    value ?? hint,
                    style: TextStyle(
                      fontSize: 14,
                      color: value != null
                          ? Colors.grey[600]
                          : Colors.grey[400],
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  /// Sección de datos de empresa
  Widget _buildCompanyDataSection() {
    return _buildSection(
      title: 'Datos de la Empresa',
      icon: Icons.business_outlined,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                _rucController,
                "RUC Empresa",
                Icons.business,
                TextInputType.text,
                isRequired: true,
                readOnly: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                _rucClienteController,
                "RUC Cliente",
                Icons.person,
                TextInputType.text,
                readOnly: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildTextField(
          _proveedorController,
          "Proveedor",
          Icons.store,
          TextInputType.text,
          isRequired: true,
        ),
      ],
    );
  }

  /// Sección de notas
  Widget _buildNotesSection() {
    return _buildTextField(
      _notaController,
      'Nota',
      Icons.comment,
      TextInputType.text,
    );
  }

  /// Constructor de sección genérica
  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: Colors.red[600]),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  /// Construir un campo de texto personalizado
  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon,
    TextInputType keyboardType, {
    bool isRequired = false,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: readOnly ? Colors.grey.shade100 : Colors.grey.shade50,
      ),
      validator: isRequired
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return '$label es obligatorio';
              }
              if (label == 'Total' && double.tryParse(value) == null) {
                return 'Ingrese un número válido';
              }
              return null;
            }
          : null,
    );
  }

  /// Construir los botones de acción
  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 50),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        children: [
          // Mensaje de campos obligatorios
          if (!_isFormValid)
            Container(
              padding: const EdgeInsets.all(6),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange.shade600),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Por favor complete todos los campos ',
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
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cancelar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 244, 54, 54),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading || !_isFormValid
                      ? null
                      : _updateFacturaAPI,
                  icon: _isLoading
                      ? const SizedBox(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(
                    _isLoading
                        ? 'Guardando...'
                        : _isFormValid
                        ? 'Guardar Reporte'
                        : 'Completar ',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isFormValid
                        ? const Color.fromARGB(255, 19, 126, 32)
                        : Colors.grey,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    disabledForegroundColor: Colors.grey[600],
                    padding: const EdgeInsets.symmetric(vertical: 6),
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
