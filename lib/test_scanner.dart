import 'package:flutter/material.dart';
import 'screens/document_scanner_screen.dart';

class TestDocumentScannerApp extends StatelessWidget {
  const TestDocumentScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test Document Scanner',
      home: Scaffold(
        appBar: AppBar(title: const Text('Test Scanner')),
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DocumentScannerScreen(),
                ),
              );

              if (result != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Resultado: $result'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Abrir Escáner de Documentos'),
          ),
        ),
      ),
    );
  }
}
