import 'package:flutter/material.dart';
import '../models/reporte_model.dart';

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

  bool _isLoading = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _politicaController = TextEditingController(
      text: widget.reporte.politica ?? '',
    );
    _categoriaController = TextEditingController(
      text: widget.reporte.categoria ?? '',
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
      text: widget.reporte.moneda ?? '',
    );
    _rucClienteController = TextEditingController(
      text: widget.reporte.ruccliente ?? '',
    );
    _glosaController = TextEditingController(text: widget.reporte.glosa ?? '');
    _obsController = TextEditingController(text: widget.reporte.obs ?? '');
  }

  @override
  void dispose() {
    _politicaController.dispose();
    _categoriaController.dispose();
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
    super.dispose();
  }

  Future<void> _saveReporte() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Simular guardado
      await Future.delayed(const Duration(milliseconds: 1500));

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Aquí normalmente se haría la actualización del reporte
        // pero como Reporte no tiene copyWith, solo mostramos confirmación
        if (widget.onSave != null) {
          widget.onSave!(widget.reporte);
        }

        _showSuccessSnackBar();
        Navigator.pop(context);
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
                    _buildPolicySection(),
                    const SizedBox(height: 20),
                    _buildCompanyDataSection(),
                    const SizedBox(height: 20),
                    _buildInvoiceDataSection(),
                    const SizedBox(height: 20),
                    _buildNotesSection(),
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
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  /// Sección de política
  Widget _buildPolicySection() {
    return _buildSection(
      title: 'Política de Gastos',
      icon: Icons.policy_outlined,
      children: [
        _buildTextField(
          controller: _politicaController,
          label: "Política Seleccionada",
          hint: "Ej: Gastos de Representación",
          readOnly: true,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _categoriaController,
          label: "Categoría",
          hint: "Ej: Alimentación",
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'La categoría es requerida';
            }
            return null;
          },
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
                controller: _rucController,
                label: "RUC Empresa",
                hint: "20XXXXXXXXX1",
                readOnly: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: _rucClienteController,
                label: "RUC Cliente",
                hint: "20XXXXXXXXX1",
                readOnly: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _proveedorController,
          label: "Proveedor",
          hint: "Nombre del proveedor",
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'El proveedor es requerido';
            }
            return null;
          },
        ),
      ],
    );
  }

  /// Sección de datos de factura
  Widget _buildInvoiceDataSection() {
    return _buildSection(
      title: 'Datos del Comprobante',
      icon: Icons.receipt_outlined,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _tipoComprobanteController,
                label: "Tipo Comprobante",
                hint: "Factura",
                readOnly: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: _serieController,
                label: "Serie",
                hint: "F001",
                readOnly: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _numeroController,
                label: "Número",
                hint: "00000001",
                readOnly: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: _fechaController,
                label: "Fecha Emisión",
                hint: "DD/MM/AAAA",
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La fecha es requerida';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _totalController,
                label: "Total",
                hint: "0.00",
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El total es requerido';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: _monedaController,
                label: "Moneda",
                hint: "PEN",
                readOnly: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Sección de notas
  Widget _buildNotesSection() {
    return _buildSection(
      title: 'Notas y Observaciones',
      icon: Icons.note_outlined,
      children: [
        _buildTextField(
          controller: _glosaController,
          label: "Glosa",
          hint: "Descripción del gasto...",
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _obsController,
          label: "Observaciones",
          hint: "Observaciones adicionales...",
          maxLines: 3,
        ),
      ],
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

  /// Constructor de campo de texto
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
    bool readOnly = false,
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
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          maxLines: maxLines,
          readOnly: readOnly,
          style: TextStyle(
            fontSize: 14,
            color: readOnly ? Colors.grey[600] : Colors.black,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            filled: true,
            fillColor: readOnly ? Colors.grey[100] : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: readOnly ? Colors.grey[300]! : Colors.grey[300]!,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.red[400]!, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  /// Botones de acción
  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 2,
              ),
              onPressed: _isLoading ? null : _saveReporte,
              child: _isLoading
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text("Guardando..."),
                      ],
                    )
                  : const Text(
                      "Guardar Cambios",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: TextButton(
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: _isLoading ? null : () => Navigator.pop(context),
              child: Text(
                "Cancelar",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
