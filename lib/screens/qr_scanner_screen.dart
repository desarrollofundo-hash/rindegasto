import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../controllers/qr_scanner_controller.dart';
import '../models/factura_data.dart';
import '../widgets/factura_modal_peru.dart';
import '../widgets/factura_modal_movilidad.dart';
import '../widgets/politica_selection_modal.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  QRScannerScreenState createState() => QRScannerScreenState();
}

class QRScannerScreenState extends State<QRScannerScreen> {
  late QRScannerController _controller;
  late MobileScannerController _mobileScannerController;
  bool _isModalOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = QRScannerController();
    _mobileScannerController = MobileScannerController();
    _controller.initializeScanner();
  }

  @override
  void dispose() {
    _controller.dispose();
    _mobileScannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture barcodeCapture) {
    if (_isModalOpen) return;

    final List<Barcode> barcodes = barcodeCapture.barcodes;
    for (final barcode in barcodes) {
      final String? code = barcode.rawValue;
      if (code != null && code.isNotEmpty) {
        _isModalOpen = true;
        HapticFeedback.vibrate();

        final facturaData = FacturaData.fromBarcode(
          Barcode(rawValue: code, format: BarcodeFormat.qrCode),
        );
        _showPoliticaSelectionModal(facturaData);
        break;
      }
    }
  }

  void _showPoliticaSelectionModal(FacturaData facturaData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PoliticaSelectionModal(
        onPoliticaSelected: (politica) {
          print('🔍 DEBUG: Política seleccionada: "$politica"');
          print('🔍 DEBUG: Cerrando modal de política...');
          Navigator.of(context).pop();
          print('🔍 DEBUG: Llamando _showFacturaModal...');
          _showFacturaModal(facturaData, politica);
        },
        onCancel: () {
          _isModalOpen = false;
          _controller.restartScanning();
        },
      ),
    );
  }

  void _showFacturaModal(FacturaData facturaData, String politicaSeleccionada) {
    showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) {
            print('🔍 DEBUG: Builder ejecutándose...');
            if (politicaSeleccionada.toLowerCase().contains('movilidad')) {
              print('🔵 DEBUG: Creando modal de MOVILIDAD (azul)');
              return FacturaModalMovilidad(
                facturaData: facturaData,
                politicaSeleccionada: politicaSeleccionada,
                onSave: (factura, imagePath) {
                  _controller.saveFactura(factura, imagePath);
                  _isModalOpen = false;
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Factura de movilidad guardada exitosamente',
                      ),
                      backgroundColor: Colors.blue,
                    ),
                  );
                },
                onCancel: () {
                  _isModalOpen = false;
                  _controller.restartScanning();
                },
              );
            } else {
              print(
                '🔴 DEBUG: Creando modal GENERAL (rojo) - FacturaModalPeru',
              );
              return FacturaModalPeru(
                facturaData: facturaData,
                politicaSeleccionada: politicaSeleccionada,
                onSave: (factura, imagePath) {
                  _controller.saveFactura(factura, imagePath);
                  _isModalOpen = false;
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Factura peruana guardada exitosamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                onCancel: () {
                  _isModalOpen = false;
                  _controller.restartScanning();
                },
              );
            }
          },
        )
        .then((_) {
          _isModalOpen = false;
          print('🔍 DEBUG: Modal de factura cerrado');
        })
        .catchError((error) {
          print('❌ DEBUG: Error en modal de factura: $error');
          _isModalOpen = false;
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escáner QR'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _mobileScannerController,
            onDetect: _onDetect,
          ),
          Container(
            decoration: ShapeDecoration(
              shape: QrScannerOverlayShape(
                borderColor: Colors.blue,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 8,
                cutOutSize: 250,
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Column(
                children: [
                  const Text(
                    'Coloque el código QR dentro del marco',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 1),
                          blurRadius: 3.0,
                          color: Colors.black45,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        onPressed: () => _mobileScannerController.toggleTorch(),
                        icon: const Icon(Icons.flash_on, color: Colors.white),
                      ),
                      IconButton(
                        onPressed: () =>
                            _mobileScannerController.switchCamera(),
                        icon: const Icon(
                          Icons.camera_front,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class QrScannerOverlayShape extends ShapeBorder {
  const QrScannerOverlayShape({
    this.borderColor = Colors.red,
    this.borderWidth = 3.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    double? cutOutSize,
    double? cutOutHeight,
    double? cutOutWidth,
    this.cutOutBottomOffset = 0,
  }) : cutOutWidth = cutOutWidth ?? cutOutSize ?? 250,
       cutOutHeight = cutOutHeight ?? cutOutSize ?? 250;

  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutWidth;
  final double cutOutHeight;
  final double cutOutBottomOffset;

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
    final borderWidthSize = width / 2;
    final height = rect.height;
    final borderHeightSize = height / 2;
    final cutOutWidth = this.cutOutWidth < width
        ? this.cutOutWidth
        : width - borderWidth;
    final cutOutHeight = this.cutOutHeight < height
        ? this.cutOutHeight
        : height - borderWidth;

    final backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    final boxPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final cutOutRect = Rect.fromLTWH(
      rect.left + (width - cutOutWidth) / 2,
      rect.top + (height - cutOutHeight) / 2 - cutOutBottomOffset,
      cutOutWidth,
      cutOutHeight,
    );

    canvas
      ..saveLayer(rect, backgroundPaint)
      ..drawRect(rect, backgroundPaint)
      ..drawRRect(
        RRect.fromRectAndRadius(cutOutRect, Radius.circular(borderRadius)),
        backgroundPaint..blendMode = BlendMode.clear,
      )
      ..restore();

    final borderOffset = borderWidth / 2;
    final borderLength = borderWidthSize > cutOutWidth / 2 + borderOffset
        ? borderWidthSize
        : cutOutWidth / 2 + borderOffset;
    final borderHeight = borderHeightSize > cutOutHeight / 2 + borderOffset
        ? borderHeightSize
        : cutOutHeight / 2 + borderOffset;

    final cutOutRect0 = Rect.fromLTWH(
      cutOutRect.left + borderOffset,
      cutOutRect.top + borderOffset,
      cutOutRect.width - borderWidth,
      cutOutRect.height - borderWidth,
    );

    canvas.drawPath(
      Path()
        ..moveTo(cutOutRect0.left, cutOutRect0.top + borderHeight)
        ..quadraticBezierTo(
          cutOutRect0.left,
          cutOutRect0.top,
          cutOutRect0.left + borderRadius,
          cutOutRect0.top,
        )
        ..lineTo(cutOutRect0.left + borderLength, cutOutRect0.top)
        ..moveTo(cutOutRect0.right - borderLength, cutOutRect0.top)
        ..lineTo(cutOutRect0.right - borderRadius, cutOutRect0.top)
        ..quadraticBezierTo(
          cutOutRect0.right,
          cutOutRect0.top,
          cutOutRect0.right,
          cutOutRect0.top + borderRadius,
        )
        ..lineTo(cutOutRect0.right, cutOutRect0.top + borderHeight)
        ..moveTo(cutOutRect0.right, cutOutRect0.bottom - borderHeight)
        ..lineTo(cutOutRect0.right, cutOutRect0.bottom - borderRadius)
        ..quadraticBezierTo(
          cutOutRect0.right,
          cutOutRect0.bottom,
          cutOutRect0.right - borderRadius,
          cutOutRect0.bottom,
        )
        ..lineTo(cutOutRect0.right - borderLength, cutOutRect0.bottom)
        ..moveTo(cutOutRect0.left + borderLength, cutOutRect0.bottom)
        ..lineTo(cutOutRect0.left + borderRadius, cutOutRect0.bottom)
        ..quadraticBezierTo(
          cutOutRect0.left,
          cutOutRect0.bottom,
          cutOutRect0.left,
          cutOutRect0.bottom - borderRadius,
        )
        ..lineTo(cutOutRect0.left, cutOutRect0.bottom - borderHeight)
        ..moveTo(cutOutRect0.left, cutOutRect0.top + borderHeight),
      boxPaint,
    );
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
