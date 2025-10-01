import 'package:flutter/material.dart';

/// Modal para seleccionar política antes de mostrar la factura
class PoliticaSelectionModal extends StatefulWidget {
  final Function(String) onPoliticaSelected;
  final VoidCallback onCancel;

  const PoliticaSelectionModal({
    super.key,
    required this.onPoliticaSelected,
    required this.onCancel,
  });

  @override
  State<PoliticaSelectionModal> createState() => _PoliticaSelectionModalState();
}

class _PoliticaSelectionModalState extends State<PoliticaSelectionModal> {
  String? _selectedPolitica;

  // Lista de políticas disponibles (puedes modificar estas según tus necesidades)
  final List<String> _politicas = ['General', 'Gasto de Movilidad'];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle del modal
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Título
          Row(
            children: [
              Icon(
                Icons.policy,
                color: Theme.of(context).primaryColor,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                'Seleccionar Política',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Selecciona la política aplicable para esta factura',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),

          // Lista de políticas
          Expanded(
            child: ListView.builder(
              itemCount: _politicas.length,
              itemBuilder: (context, index) {
                final politica = _politicas[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: RadioListTile<String>(
                    title: Text(
                      politica,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    value: politica,
                    groupValue: _selectedPolitica,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedPolitica = value;
                        });
                      }
                    },
                    activeColor: Theme.of(context).primaryColor,
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Botones de acción
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
                  onPressed: _selectedPolitica != null
                      ? () {
                          widget.onPoliticaSelected(_selectedPolitica!);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    'Continuar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
