import 'package:flutter/material.dart';
import '../models/dropdown_option.dart';
import '../services/api_service.dart';
import 'nuevo_gasto_modal.dart';
import 'nuevo_gasto_movilidad.dart';

/// Modal para seleccionar política extrayendo datos únicos de la API de categorías
class PoliticaTestModal extends StatefulWidget {
  final Function(DropdownOption) onPoliticaSelected;
  final VoidCallback onCancel;

  const PoliticaTestModal({
    super.key,
    required this.onPoliticaSelected,
    required this.onCancel,
  });

  @override
  State<PoliticaTestModal> createState() => _PoliticaTestModalState();
}

class _PoliticaTestModalState extends State<PoliticaTestModal> {
  final ApiService _apiService = ApiService();
  List<DropdownOption> _politicas = [];
  DropdownOption? _selectedPolitica;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPoliticas();
  }

  Future<void> _loadPoliticas() async {
    print('🚀 Cargando políticas desde API de categorías...');
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      // Obtenemos todas las categorías y extraemos las políticas únicas
      final categorias = await _apiService.getRendicionCategorias(
        politica: 'todos',
      );
      print('✅ Categorías obtenidas: ${categorias.length}');

      // Extraer políticas únicas
      final Map<String, DropdownOption> politicasMap = {};
      for (var categoria in categorias) {
        if (categoria.metadata != null &&
            categoria.metadata!['politica'] != null) {
          final politicaNombre = categoria.metadata!['politica'].toString();
          final politicaId = politicasMap.length + 1; // ID incremental

          if (!politicasMap.containsKey(politicaNombre)) {
            politicasMap[politicaNombre] = DropdownOption(
              id: politicaId.toString(),
              value: politicaNombre,
              metadata: {'estado': 'S'}, // Asumimos que están activas
            );
          }
        }
      }

      final politicasUnicas = politicasMap.values.toList();
      print('✅ Políticas únicas extraídas: ${politicasUnicas.length}');
      for (var politica in politicasUnicas) {
        print('  - ${politica.value} (ID: ${politica.id})');
      }

      if (mounted) {
        setState(() {
          _politicas = politicasUnicas;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error cargando políticas: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _onContinuar() {
    if (_selectedPolitica != null) {
      // En lugar de llamar al callback, abrir el modal apropiado según el tipo de política
      Navigator.pop(context); // Cerrar el modal actual

      // Verificar si es política de movilidad
      final isMovilidadPolicy = _selectedPolitica!.value.toUpperCase().contains(
        'MOVILIDAD',
      );

      if (isMovilidadPolicy) {
        // Abrir modal específico de movilidad
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => NuevoGastoMovilidad(
            politicaSeleccionada: _selectedPolitica!,
            onCancel: () {
              Navigator.pop(context);
            },
            onSave: (gastoData) {
              Navigator.pop(context);
              print('🚗 Gasto de movilidad guardado: $gastoData');
              widget.onPoliticaSelected(_selectedPolitica!);
            },
          ),
        );
      } else {
        // Abrir modal general
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => NuevoGastoModal(
            politicaSeleccionada: _selectedPolitica!,
            onCancel: () {
              Navigator.pop(context);
            },
            onSave: (gastoData) {
              Navigator.pop(context);
              print('💼 Gasto general guardado: $gastoData');
              widget.onPoliticaSelected(_selectedPolitica!);
            },
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.4,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle del modal
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo.shade700, Colors.indigo.shade400],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.policy, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Seleccionar Política',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Políticas extraídas de categorías API',
                        style: TextStyle(fontSize: 12, color: Colors.white70),
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
          ),

          // Contenido
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _buildContent(),
            ),
          ),

          // Botones
          Container(
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
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selectedPolitica != null ? _onContinuar : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Continuar'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    // Estado de carga
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.indigo),
            SizedBox(height: 16),
            Text(
              'Cargando políticas...',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Estado de error
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              'Error al cargar políticas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red.shade600),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadPoliticas,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    // Estado sin políticas
    if (_politicas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No hay políticas disponibles',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No se encontraron políticas activas en el sistema',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadPoliticas,
              icon: const Icon(Icons.refresh),
              label: const Text('Recargar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    // Contenido con políticas cargadas
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Selecciona una política',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),

        // Dropdown con políticas de la API
        DropdownButtonFormField<DropdownOption>(
          value: _selectedPolitica,
          decoration: InputDecoration(
            labelText: 'Política *',
            prefixIcon: const Icon(Icons.policy, color: Colors.indigo),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          hint: const Text('Seleccionar política...'),
          isExpanded: true,
          items: _politicas.map((politica) {
            return DropdownMenuItem<DropdownOption>(
              value: politica,
              child: Text(politica.value),
            );
          }).toList(),
          onChanged: (value) {
            if (mounted) {
              setState(() {
                _selectedPolitica = value;
              });
            }
          },
        ),

        const SizedBox(height: 16),

        // Información sobre políticas disponibles
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Se extrajeron ${_politicas.length} política${_politicas.length != 1 ? 's' : ''} única${_politicas.length != 1 ? 's' : ''} de la API de categorías',
                  style: TextStyle(color: Colors.blue.shade700, fontSize: 12),
                ),
              ),
            ],
          ),
        ),

        // Info selección
        if (_selectedPolitica != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.indigo.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.indigo.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Política seleccionada:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedPolitica!.value,
                  style: TextStyle(
                    color: Colors.indigo.shade700,
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                if (_selectedPolitica!.metadata != null)
                  Text(
                    'ID: ${_selectedPolitica!.id}',
                    style: TextStyle(
                      color: Colors.indigo.shade600,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
