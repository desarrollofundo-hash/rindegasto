import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class DocumentScannerScreen extends StatefulWidget {
  const DocumentScannerScreen({super.key});

  @override
  State<DocumentScannerScreen> createState() => _DocumentScannerScreenState();
}

class _DocumentScannerScreenState extends State<DocumentScannerScreen> {
  File? _image;
  final picker = ImagePicker();
  bool _isLoading = false;

  void _showDebug(String message) {
    print('DEBUG: $message');
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('DEBUG: $message')));
  }

  Future<void> _captureImage() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _showDebug('Iniciando captura de imagen...');

      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        _showDebug('Imagen capturada exitosamente: ${pickedFile.path}');
        setState(() {
          _image = File(pickedFile.path);
        });
      } else {
        _showDebug('No se selecciono ninguna imagen');
      }
    } on PlatformException catch (e) {
      _showDebug('Error de plataforma: ${e.code} - ${e.message}');

      String errorMessage = 'Error desconocido';
      if (e.code == 'camera_access_denied') {
        errorMessage = 'Acceso a la camara denegado. Verifica los permisos.';
      } else if (e.code == 'permission_denied') {
        errorMessage = 'Permisos denegados para acceder a la camara.';
      } else if (e.code == 'no_available_camera') {
        errorMessage = 'No hay camara disponible en este dispositivo.';
      } else {
        errorMessage = 'Error: ${e.message ?? 'Problema desconocido'}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      _showDebug('Error general: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error inesperado: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escaneador de Documentos'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _captureImage,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.camera_alt),
              label: Text(_isLoading ? 'Procesando...' : 'Tomar Foto'),
            ),
            const SizedBox(height: 24),

            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _image == null
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.document_scanner_outlined,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No hay imagen seleccionada',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(_image!, fit: BoxFit.contain),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
