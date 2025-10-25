// ignore_for_file: avoid_print
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import '../models/reporte_model.dart';
import '../models/dropdown_option.dart';
import '../models/estado_reporte.dart';
import '../screens/qr_scanner_screen.dart';
import '../services/factura_ia.dart';
import '../services/ocr_service.dart';
import '../models/factura_data_ocr.dart';
import '../widgets/politica_selector_modal.dart';
import '../widgets/factura_modal_peru_ocr.dart';
import '../widgets/nuevo_gasto_modal.dart';
import '../widgets/nuevo_gasto_movilidad.dart';
// NOTE: ya no abrimos `factura_modal_peru_ocr_extractor.dart` desde aquí.

class ReportesListController {
  // Abre el escáner QR y muestra SnackBar con resultado
  Future<void> abrirEscaneadorQR(
    BuildContext context,
    bool Function() mounted,
  ) async {
    try {
      final String? resultado = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const QRScannerScreen()),
      );

      if (resultado != null && mounted()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Código escaneado: $resultado'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Copiar',
              textColor: Colors.white,
              onPressed: () {
                print('Código QR: $resultado');
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir escáner: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Mostrar modal de política y continuar con la selección
  Future<void> escanerIA(BuildContext context, bool Function() mounted) async {
    try {
      // Mostrar modal de políticas y obtener la selección
      final seleccion = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => PoliticaSelectionModal(
          onPoliticaSelected: (politica) {
            Navigator.of(ctx).pop(politica);
          },
          onCancel: () {
            Navigator.of(ctx).pop(null);
          },
        ),
      );

      if (seleccion == null) return; // usuario canceló

      if (!mounted()) return;

      // Después de seleccionar la política, mostrar opciones de fuente
      // (Tomar foto, Elegir de galería, Seleccionar documento)
      final sourceSelection = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) {
          return Container(
            height: MediaQuery.of(ctx).size.height * 0.28,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Agregar documento',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: Colors.indigo),
                  title: const Text('Tomar foto'),
                  onTap: () => Navigator.of(ctx).pop('camera'),
                ),
                ListTile(
                  leading: const Icon(Icons.photo, color: Colors.indigo),
                  title: const Text('Elegir foto'),
                  onTap: () => Navigator.of(ctx).pop('gallery'),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.insert_drive_file,
                    color: Colors.indigo,
                  ),
                  title: const Text('Seleccionar documento (PDF)'),
                  onTap: () => Navigator.of(ctx).pop('document'),
                ),
              ],
            ),
          );
        },
      );
      //antes de la previsualizacion  añadir esta funcionalidad
      //despues que tome la foto buscar en la foto el codigo qr y mostrar los campos que tiene ese codigo qr en un modal simple ,solo has eso y no modiques nada mas

      if (sourceSelection == null) return; // usuario canceló el selector

      if (!mounted()) return;

      if (sourceSelection == 'camera' || sourceSelection == 'gallery') {
        final picker = ImagePicker();
        final source = sourceSelection == 'camera'
            ? ImageSource.camera
            : ImageSource.gallery;
        try {
          final xfile = await picker.pickImage(
            source: source,
            imageQuality: 85,
          );
          if (xfile == null) return; // usuario no seleccionó imagen
          final file = File(xfile.path);

          // Mostrar previsualización y confirmar
          final confirmed = await _mostrarPrevisualizacionImagen(context, file);
          if (confirmed == true) {
            // Procesar con IA pasando la política seleccionada
            await procesarFacturaConIA(context, file, seleccion);
          }
        } catch (e) {
          if (mounted()) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al capturar/seleccionar imagen: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else if (sourceSelection == 'document') {
        try {
          final result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['pdf'],
          );
          if (result == null) return; // cancelado
          final path = result.files.single.path;
          if (path == null) return;
          final file = File(path);

          final confirmed = await _mostrarPrevisualizacionDocumento(
            context,
            file,
          );
          if (confirmed == true) {
            // Por ahora mantenemos comportamiento previo: no procesamos PDFs
            if (mounted()) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Documento seleccionado'),
                  backgroundColor: Colors.indigo,
                ),
              );
            }
          }
        } catch (e) {
          if (mounted()) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al seleccionar documento: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir selección de política: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Mostrar modal de política y continuar con la selección
  Future<void> crearGasto(BuildContext context, bool Function() mounted) async {
    try {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => PoliticaSelectionModal(
          onPoliticaSelected: (politica) {
            Navigator.of(context).pop();
          },
          onCancel: () {
            Navigator.of(context).pop();
          },
        ),
      );
    } catch (e) {
      if (mounted()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir selección de política: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void continuarConPolitica(
    BuildContext context,
    DropdownOption politica,
    bool Function() mounted,
  ) {
    if (mounted()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Política seleccionada: ${politica.value}')),
            ],
          ),
          backgroundColor: Colors.indigo,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Continuar',
            textColor: Colors.white,
            onPressed: () {
              navegarSegunPolitica(context, politica);
            },
          ),
        ),
      );
    }
  }

  /// Navegar y abrir modal según la política seleccionada
  void navegarSegunPolitica(BuildContext context, DropdownOption politica) {
    final key = politica.value.toUpperCase();
    switch (key) {
      case 'GENERAL':
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (ctx) => NuevoGastoModal(
            politicaSeleccionada: politica,
            onCancel: () => Navigator.of(ctx).pop(),
            onSave: (data) {
              Navigator.of(ctx).pop();
              // opcional: manejar resultado saved data si es necesario
            },
          ),
        );
        break;
      case 'GASTOS DE MOVILIDAD':
      case 'MOVILIDAD':
      case 'GASTOS MOVILIDAD':
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (ctx) => NuevoGastoMovilidad(
            politicaSeleccionada: politica,
            onCancel: () => Navigator.of(ctx).pop(),
            onSave: (data) {
              Navigator.of(ctx).pop();
            },
          ),
        );
        break;
      default:
        // Para políticas no contempladas, mostrar mensaje
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Política no implementada: ${politica.value}'),
            backgroundColor: Colors.orange,
          ),
        );
        break;
    }
  }

  // Muestra un modal para elegir fuente (tomar foto, elegir foto, documento), luego previsualizar
  Future<void> mostrarModalCaptura(
    BuildContext context,
    DropdownOption politica,
    bool Function() mounted,
  ) async {
    try {
      final selection = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) {
          return Container(
            height: MediaQuery.of(ctx).size.height * 0.28,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Agregar documento',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: Colors.indigo),
                  title: const Text('Tomar foto'),
                  onTap: () => Navigator.of(ctx).pop('camera'),
                ),
                ListTile(
                  leading: const Icon(Icons.photo, color: Colors.indigo),
                  title: const Text('Elegir foto'),
                  onTap: () => Navigator.of(ctx).pop('gallery'),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.insert_drive_file,
                    color: Colors.indigo,
                  ),
                  title: const Text('Seleccionar documento (PDF)'),
                  onTap: () => Navigator.of(ctx).pop('document'),
                ),
              ],
            ),
          );
        },
      );

      if (selection == null) return; // user cancelled

      if (!mounted()) return;

      if (selection == 'camera' || selection == 'gallery') {
        final picker = ImagePicker();
        final source = selection == 'camera'
            ? ImageSource.camera
            : ImageSource.gallery;
        try {
          final xfile = await picker.pickImage(
            source: source,
            imageQuality: 85,
          );
          if (xfile == null) return;
          final file = File(xfile.path);

          // Mostrar previsualización y confirmar
          final confirmed = await _mostrarPrevisualizacionImagen(context, file);
          if (confirmed == true) {
            // Procesar con IA (o la acción que corresponda) usando política por defecto
            await procesarFacturaConIA(context, file, 'GENERAL');
          }
        } catch (e) {
          if (mounted()) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al seleccionar imagen: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else if (selection == 'document') {
        try {
          final result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['pdf'],
          );
          if (result == null) return;
          final path = result.files.single.path;
          if (path == null) return;
          final file = File(path);

          final confirmed = await _mostrarPrevisualizacionDocumento(
            context,
            file,
          );
          if (confirmed == true) {
            // Por ahora, solo mostramos un mensaje; si se requiere procesar PDFs, implementar aquí
            if (mounted()) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Documento seleccionado'),
                  backgroundColor: Colors.indigo,
                ),
              );
            }
          }
        } catch (e) {
          if (mounted()) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al seleccionar documento: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error en selector de captura: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Muestra un diálogo con previsualización de imagen y devuelve true si el usuario confirma
  Future<bool?> _mostrarPrevisualizacionImagen(
    BuildContext context,
    File file,
  ) async {
    // Antes de mostrar la previsualización, ejecutar el script Python que
    // analiza la imagen (`analizar_qr.py`) y capturar su salida.
    String analisis = '';
    try {
      // Ruta al script dentro del workspace
      final scriptPath = Platform.isWindows
          ? r'c:\rindegasto\tools\analizar_qr.py'
          : '/c/rindegasto/tools/analizar_qr.py';

      // Nota: en dispositivos móviles (Android/iOS) no existe un intérprete
      // Python accesible desde el sandbox de la aplicación, por lo que
      // intentar ejecutar `python` provocará errores como
      // "/system/bin/sh: python: inaccessible or not found".
      // Aquí damos un fallback amigable para el usuario en esos entornos.
      if (Platform.isAndroid || Platform.isIOS) {
        analisis =
            'Análisis QR no disponible en este dispositivo: no es posible ejecutar Python desde la aplicación.\nUsa el escáner QR integrado (Abrir Escáner) o habilita una solución nativa/servidor para procesar la imagen.';
      } else {
        // Ejecutar Python pasando la ruta de la imagen como argumento (si el
        // script lo soporta). Usamos runInShell para mayor compatibilidad en
        // entornos Windows.
        final result = await Process.run('python', [
          scriptPath,
          file.path,
        ], runInShell: true);

        if (result.exitCode == 0) {
          analisis = result.stdout.toString().trim();
        } else {
          // Si hubo error, intentamos leer stdout/stderr para mostrar algo
          final out = result.stdout.toString().trim();
          final err = result.stderr.toString().trim();

          // Si detectamos mensajes típicos de 'python not found' devolvemos
          // un texto más claro para el usuario en lugar del stderr críptico.
          final errLower = err.toLowerCase();
          if (errLower.contains('inaccessible') ||
              errLower.contains('not found') ||
              errLower.contains('python:')) {
            analisis =
                'Análisis QR no disponible en este entorno: intérprete Python no accesible.';
            if (out.isNotEmpty) analisis += '\n\nSalida:\n' + out;
            if (err.isNotEmpty) analisis += '\n\nError:\n' + err;
          } else {
            analisis =
                (out.isNotEmpty ? out : '') +
                (err.isNotEmpty ? '\n' + err : '');
            analisis = analisis.trim();
          }
        }
      }
    } catch (e) {
      // Si falla la ejecución del proceso no interrumpimos el flujo; dejamos
      // `analisis` vacío para que solo se muestre la previsualización.
      analisis = '';
    }

    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Previsualización'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mostrar texto simple con el resultado del análisis (si existe)
                  if (analisis.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        'Análisis QR:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: SelectableText(
                        analisis,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                  Image.file(file),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  // Muestra previsualización simple para documento (PDF)
  Future<bool?> _mostrarPrevisualizacionDocumento(
    BuildContext context,
    File file,
  ) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Previsualización de documento'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.insert_drive_file,
                size: 64,
                color: Colors.indigo,
              ),
              const SizedBox(height: 8),
              Text(file.path.split(Platform.pathSeparator).last),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  // Escanear documento y procesar con IA si es un File
  Future<void> escanearDocumento(
    BuildContext context,
    bool Function() mounted,
  ) async {
    try {
      // Antes: navegábamos a DocumentScannerScreen. Ahora capturamos imagen
      // directamente con image_picker para evitar dependencia en la pantalla.
      try {
        final picker = ImagePicker();
        final xfile = await picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
        );
        if (xfile != null && mounted()) {
          final file = File(xfile.path);
          await procesarFacturaConIA(context, file, 'GENERAL');
        }
      } catch (e) {
        if (mounted()) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al capturar imagen: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al escanear documento: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> procesarFacturaConIA(
    BuildContext context,
    File imagenFactura,
    String politicaSeleccionada, // nueva política a usar al abrir modal
  ) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 16),
            Text('🤖 Procesando factura con IA...'),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 3),
      ),
    );

    try {
      // Comprimir la imagen para que no supere 1MB antes de enviarla a OCR.space
      File imageToSend = imagenFactura;
      try {
        final originalSize = await imagenFactura.length();
        debugPrint(
          'Imagen original: ${imagenFactura.path} -> ${originalSize} bytes',
        );

        if (originalSize > 1024 * 1024) {
          // Intentar comprimir decrementando la calidad
          int quality = 85;
          File? compressed;
          while (quality >= 20) {
            try {
              final targetPath = imagenFactura.path.replaceFirstMapped(
                RegExp(r'(\.[^.]+)$'),
                (m) => '_cmp_q${quality}${m[0]}',
              );
              final resultBytes = await FlutterImageCompress.compressWithFile(
                imagenFactura.path,
                quality: quality,
                format: CompressFormat.jpeg,
              );
              if (resultBytes != null) {
                compressed = await File(targetPath).writeAsBytes(resultBytes);
                final newSize = await compressed.length();
                debugPrint('Compresión q=$quality -> $newSize bytes');
                if (newSize <= 1024 * 1024) {
                  imageToSend = compressed;
                  break;
                }
              }
            } catch (e) {
              debugPrint('Error al comprimir q=$quality: $e');
            }
            quality -= 10;
          }
          // Si no se logró comprimir por calidad, usar la última comprimida si existe
          if (imageToSend == imagenFactura && compressed != null)
            imageToSend = compressed;
        }
      } catch (e) {
        debugPrint('No se pudo calcular/comprimir imagen: $e');
      }

      // Intentar primero el OCR local (procesarFactura) y mapear el resultado
      // a una estructura similar a la que usa el resto del flujo. Si falla,
      // se hace fallback a OcrSpaceService.parseImage.
      Map<String, dynamic> ocrResult;
      try {
        final facturaOcr = await procesarFactura(imageToSend.path);
        debugPrint('Factura OCR: ${facturaOcr.toString()}');

        ocrResult = {
          'ParsedResults': [
            {'ParsedText': facturaOcr.toString()},
          ],
          'FacturaOcrData': {
            'rucEmisor': facturaOcr.rucEmisor ?? '',
            'razonSocialEmisor': facturaOcr.razonSocialEmisor ?? '',
            'tipoComprobante': facturaOcr.tipoComprobante ?? '',
            'serie': facturaOcr.serie ?? '',
            'numero': facturaOcr.numero ?? '',
            'fecha': facturaOcr.fecha ?? '',
            'subtotal': facturaOcr.subtotal ?? '',
            'igv': facturaOcr.igv ?? '',
            'total': facturaOcr.total ?? '',
            'moneda': facturaOcr.moneda ?? '',
            'rucCliente': facturaOcr.rucCliente ?? '',
            'razonSocialCliente': facturaOcr.razonSocialCliente ?? '',
          },
        };
      } catch (e) {
        debugPrint('Error procesando con OCR local: $e');
        // No usamos el servicio externo como fallback aquí.
        // Devolvemos un resultado con clave Error para que el flujo
        // superior lo detecte y muestre el diálogo correspondiente.
        ocrResult = {'Error': e.toString()};
      }

      // Mostrar JSON crudo en un diálogo para inspección
      bool openedFromJsonDialog = false;
      try {
        final pretty = const JsonEncoder.withIndent('  ').convert(ocrResult);
        await showDialog(
          context: context,
          barrierDismissible: true,
          builder: (ctx) {
            return AlertDialog(
              title: const Text('Resultado OCR (JSON)'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(child: SelectableText(pretty)),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cerrar'),
                ),
              ],
            );
          },
        );

        // Después de cerrar el diálogo JSON, si el resultado contiene
        // una sección 'FacturaOcrData' la usamos para poblar el modal
        // inmediatamente y evitar abrirlo nuevamente más abajo.
        if (ocrResult.containsKey('FacturaOcrData')) {
          final f = ocrResult['FacturaOcrData'];
          if (f is Map) {
            final facturaFromJson = FacturaOcrData();
            facturaFromJson.rucEmisor = (f['rucEmisor'] as String?)?.trim();
            facturaFromJson.razonSocialEmisor =
                (f['razonSocialEmisor'] as String?)?.trim();
            facturaFromJson.tipoComprobante = (f['tipoComprobante'] as String?)
                ?.trim();
            facturaFromJson.serie = (f['serie'] as String?)?.trim();
            facturaFromJson.numero = (f['numero'] as String?)?.trim();
            facturaFromJson.fecha = (f['fecha'] as String?)?.trim();
            facturaFromJson.subtotal = (f['subtotal'] as String?)?.trim();
            facturaFromJson.igv = (f['igv'] as String?)?.trim();
            facturaFromJson.total = (f['total'] as String?)?.trim();
            facturaFromJson.moneda = (f['moneda'] as String?)?.trim();
            facturaFromJson.rucCliente = (f['rucCliente'] as String?)?.trim();
            facturaFromJson.razonSocialCliente =
                (f['razonSocialCliente'] as String?)?.trim();

            // Abrir modal sólo si al menos un campo está presente
            final hasAny = [
              facturaFromJson.rucEmisor,
              facturaFromJson.razonSocialEmisor,
              facturaFromJson.tipoComprobante,
              facturaFromJson.serie,
              facturaFromJson.numero,
              facturaFromJson.fecha,
              facturaFromJson.subtotal,
              facturaFromJson.igv,
              facturaFromJson.total,
              facturaFromJson.moneda,
              facturaFromJson.rucCliente,
              facturaFromJson.razonSocialCliente,
            ].any((v) => v != null && v.toString().trim().isNotEmpty);

            if (hasAny) {
              openedFromJsonDialog = true;
              final ocrMap = <String, String>{
                'RUC Emisor': facturaFromJson.rucEmisor ?? '',
                'Razón Social': facturaFromJson.razonSocialEmisor ?? '',
                'Tipo Comprobante': facturaFromJson.tipoComprobante ?? '',
                'Serie': facturaFromJson.serie ?? '',
                'Número': facturaFromJson.numero ?? '',
                'Fecha': facturaFromJson.fecha ?? '',
                'Subtotal': facturaFromJson.subtotal ?? '',
                'IGV': facturaFromJson.igv ?? '',
                'Total': facturaFromJson.total ?? '',
                'Moneda': facturaFromJson.moneda ?? '',
                'RUC Cliente': facturaFromJson.rucCliente ?? '',
                'Razón Social Cliente':
                    facturaFromJson.razonSocialCliente ?? '',
                'raw_text': facturaFromJson.toString(),
              };

              await showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => FacturaModalPeruOCR(
                  ocrData: ocrMap,
                  evidenciaFile: imagenFactura,
                  politicaSeleccionada: politicaSeleccionada,
                  onSave: (facturaData, _) {
                    Navigator.of(context).pop();
                  },
                  onCancel: () => Navigator.of(context).pop(),
                ),
              );
            }
          }
        }
      } catch (e) {
        debugPrint('No se pudo mostrar JSON OCR: $e');
      }
      String parsedText = '';
      if (ocrResult.containsKey('ParsedResults')) {
        final results = ocrResult['ParsedResults'];
        if (results is List && results.isNotEmpty) {
          final first = results[0];
          parsedText = (first['ParsedText'] ?? '').toString();
        }
      } else if (ocrResult.containsKey('Error')) {
        debugPrint('OCR Error: ${ocrResult['Error']}');
      }

      Map<String, String> datosExtraidos = {};

      if (parsedText.isNotEmpty) {
        // Usar el JSON completo (ParsedResults) para una extracción más robusta
        datosExtraidos = await FacturaIA.extraerDatosDesdeParsedResults(
          ocrResult,
        );

        // Si el extractor no logró identificar campos pero sí hay texto OCR,
        // abrimos el modal con el texto bruto para que el usuario pueda
        // revisar/editar manualmente. Esto evita el mensaje genérico.
        if (datosExtraidos.isEmpty) {
          datosExtraidos = {'raw_text': parsedText};
          // Mensaje corto para debug/UX
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Texto OCR detectado, abriendo modal para revisión',
              ),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Si OCR.space no entrega texto, informar y no procesar con otro motor
        final err =
            ocrResult['Error'] ??
            'OCR.space no devolvió texto para esta imagen';
        datosExtraidos = {'Error': err.toString()};
      }

      if (!openedFromJsonDialog &&
          datosExtraidos.isNotEmpty &&
          !datosExtraidos.containsKey('Error')) {
        // Abrir modal prellenado con los datos extraídos por OCR (nuevo extractor)
        // Convertir el mapa `datosExtraidos` a `FacturaOcrData` y pasar el modelo
        String? getVal(String key, [String? alt]) {
          final v =
              datosExtraidos[key] ?? (alt != null ? datosExtraidos[alt] : null);
          if (v == null) return null;
          final t = v.trim();
          return t.isEmpty ? null : t;
        }

        final facturaModel = FacturaOcrData();
        facturaModel.rucEmisor = getVal('rucEmisor', 'RUC Emisor');
        facturaModel.razonSocialEmisor = getVal(
          'razonSocialEmisor',
          'Razón Social',
        );
        facturaModel.tipoComprobante = getVal(
          'tipoComprobante',
          'Tipo Comprobante',
        );
        facturaModel.serie = getVal('serie', 'Serie');
        facturaModel.numero = getVal('numero', 'Número');
        facturaModel.fecha = getVal('fecha', 'Fecha');
        facturaModel.subtotal = getVal('subtotal', 'Subtotal');
        facturaModel.igv = getVal('igv', 'IGV');
        facturaModel.total = getVal('total', 'Total');
        facturaModel.moneda = getVal('moneda', 'Moneda');
        facturaModel.rucCliente = getVal('rucCliente', 'RUC Cliente');
        facturaModel.razonSocialCliente = getVal(
          'razonSocialCliente',
          'Razón Social Cliente',
        );

        final ocrMap = <String, String>{
          'RUC Emisor': facturaModel.rucEmisor ?? '',
          'Razón Social': facturaModel.razonSocialEmisor ?? '',
          'Tipo Comprobante': facturaModel.tipoComprobante ?? '',
          'Serie': facturaModel.serie ?? '',
          'Número': facturaModel.numero ?? '',
          'Fecha': facturaModel.fecha ?? '',
          'Subtotal': facturaModel.subtotal ?? '',
          'IGV': facturaModel.igv ?? '',
          'Total': facturaModel.total ?? '',
          'Moneda': facturaModel.moneda ?? '',
          'RUC Cliente': facturaModel.rucCliente ?? '',
          'Razón Social Cliente': facturaModel.razonSocialCliente ?? '',
          'raw_text': facturaModel.toString(),
        };

        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => FacturaModalPeruOCR(
            ocrData: ocrMap,
            evidenciaFile: imagenFactura,
            politicaSeleccionada: politicaSeleccionada,
            onSave: (facturaData, _) {
              // El modal nuevo llama onSave con la factura creada.
              Navigator.of(context).pop();
            },
            onCancel: () => Navigator.of(context).pop(),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error procesando con IA: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void mostrarDatosExtraidos(BuildContext context, Map<String, String> datos) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.psychology, color: Colors.green),
              SizedBox(width: 8),
              Text('🤖 Datos Extraídos por IA'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Campos detectados para el modal peruano:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 12),
                ...datos.entries
                    .map(
                      (entry) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 80,
                              child: Text(
                                '${entry.key}:',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                entry.value,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info, color: Colors.blue, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Estos datos se pueden usar automáticamente en el modal de factura peruana',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '✅ ${datos.length} campos extraídos listos para usar',
                    ),
                    backgroundColor: Colors.green,
                    action: SnackBarAction(
                      label: 'Abrir Modal',
                      textColor: Colors.white,
                      onPressed: () {},
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.assignment),
              label: const Text('Usar en Modal'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  // Filtrar reportes por estado
  List<Reporte> filtrarReportes(List<Reporte> reportes, EstadoReporte filtro) {
    // Helper para detectar estado del reporte en diferentes campos/formatos
    bool isBorrador(Reporte r) {
      final candidates = [r.destino, r.obs, r.glosa];
      for (final v in candidates) {
        if (v == null) continue;
        final s = v.trim().toUpperCase();
        if (s == 'B' || s == 'BORRADOR' || s.contains('BORRADOR')) return true;
      }
      return false;
    }

    // Nota: el filtro de 'enviado' ahora usa !isBorrador, por lo que
    // no se necesita una función separada isEnviado.

    switch (filtro) {
      case EstadoReporte.borrador:
        return reportes.where((r) => isBorrador(r)).toList();
      case EstadoReporte.enviado:
        // Incluir cualquier reporte que NO sea borrador. Esto agrupa
        // estados como 'ENVIADO', 'EN INFORME', 'APROBADO', etc.
        return reportes.where((r) => !isBorrador(r)).toList();
      case EstadoReporte.todos:
        return reportes;
    }
  }

  Color? getEstadoColor(String? estado) {
    if (estado == null) return Colors.grey[400];

    final s = estado.trim().toUpperCase();

    // Estados específicos por texto completo
    if (s.contains('EN INFORME')) return Colors.yellow[800];
    if (s.contains('BORRADOR') || s == 'B') return Colors.grey[500];
    if (s.contains('ENVIADO') || s == 'E') return Colors.blue[400];
    if (s.contains('PENDIENTE') || s == 'P' || s.contains('POR'))
      return Colors.orange[400];
    if (s.contains('APROBADO') || s == 'C' || s.contains('COMPLET'))
      return Colors.green[600];
    if (s.contains('RECHAZADO') || s.contains('RECHAZ')) return Colors.red[600];
    if (s.contains('ANULADO') || s.contains('CANCEL'))
      return Colors.redAccent[100];
    if (s.contains('SYNC') || s == 'S') return Colors.teal[400];

    // Fallback
    return Colors.grey[400];
  }
}
