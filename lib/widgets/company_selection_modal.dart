import 'package:flutter/material.dart';
import '../screens/home_screen.dart';

class CompanySelectionModal extends StatefulWidget {
  final String userName;

  const CompanySelectionModal({Key? key, required this.userName})
    : super(key: key);

  @override
  State<CompanySelectionModal> createState() => _CompanySelectionModalState();
}

class _CompanySelectionModalState extends State<CompanySelectionModal> {
  String? selectedCompany;

  // Lista de empresas disponibles - puedes modificar esta lista según tus necesidades
  final List<Map<String, String>> companies = [
    {'id': '1', 'name': 'AGRICOLA SANTA AZUL S.R.L'},
    {'id': '2', 'name': 'CORPORACION VERDE S.A.C'},
    {'id': '3', 'name': 'EMPRESA INDUSTRIAL LIMA S.R.L'},
    {'id': '4', 'name': 'SERVICIOS GENERALES DEL PERU S.A.C'},
    {'id': '5', 'name': 'TECNOLOGIA AVANZADA S.A.C'},
  ];

  void _continueToHome() {
    if (selectedCompany != null) {
      Navigator.of(context).pop(); // Cerrar el modal
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );

      // Mostrar mensaje de confirmación
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Empresa seleccionada: ${companies.firstWhere((c) => c['id'] == selectedCompany)['name']}',
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icono y título
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.business,
                size: 32,
                color: Colors.blue.shade700,
              ),
            ),
            const SizedBox(height: 16),

            Text(
              '¡Bienvenido ${widget.userName}!',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            Text(
              'Selecciona la empresa con la que vas a trabajar',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Lista desplegable de empresas
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedCompany,
                  hint: Text(
                    'Seleccione una empresa',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                  isExpanded: true,
                  icon: Icon(
                    Icons.arrow_drop_down,
                    color: Colors.blue.shade700,
                  ),
                  style: const TextStyle(color: Colors.black87, fontSize: 16),
                  items: companies.map((company) {
                    return DropdownMenuItem<String>(
                      value: company['id'],
                      child: Text(
                        company['name']!,
                        style: const TextStyle(fontSize: 14),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? value) {
                    setState(() {
                      selectedCompany = value;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Botones
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: Text(
                      'Cancelar',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: selectedCompany != null ? _continueToHome : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedCompany != null
                          ? Colors.blue.shade700
                          : Colors.grey.shade300,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: selectedCompany != null ? 2 : 0,
                    ),
                    child: const Text(
                      'Continuar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
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
}
