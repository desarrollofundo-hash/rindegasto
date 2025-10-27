import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../screens/home_screen.dart';
import '../services/api_service.dart';
import '../services/company_service.dart';
import '../models/user_company.dart';

class CompanySelectionModal extends StatefulWidget {
  final String userName;
  final int userId; // Agregar userId para la API
  final bool shouldNavigateToHome;

  const CompanySelectionModal({
    super.key,
    required this.userName,
    required this.userId,
    this.shouldNavigateToHome = true,
  });

  @override
  State<CompanySelectionModal> createState() => _CompanySelectionModalState();
}

class _CompanySelectionModalState extends State<CompanySelectionModal> {
  String? selectedCompany;
  List<UserCompany> userCompanies = [];
  final ApiService _apiService = ApiService();
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserCompanies();
  }

  /// Cargar empresas del usuario desde la API
  Future<void> _loadUserCompanies() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final companiesData = await _apiService.getUserCompanies(widget.userId);

      if (companiesData.isEmpty) {
        setState(() {
          errorMessage = 'No se encontraron empresas asociadas al usuario';
          isLoading = false;
        });
        return;
      }

      final companies = companiesData
          .map((json) => UserCompany.fromJson(json))
          .toList();

      setState(() {
        userCompanies = companies;
        isLoading = false;
      });

      print('✅ Empresas cargadas: ${companies.length}');
    } catch (e) {
      print('💥 Error al cargar empresas: $e');
      setState(() {
        errorMessage = 'Error al cargar empresas: $e';
        isLoading = false;
      });
    }
  }

  void _continueToHome() {
    if (selectedCompany != null) {
      // Buscar la empresa seleccionada
      final selectedUserCompany = userCompanies.firstWhere(
        (company) => company.id.toString() == selectedCompany,
      );

      // 🏢 GUARDAR LA EMPRESA SELECCIONADA EN EL SERVICIO
      CompanyService().setCurrentCompany(selectedUserCompany);

      // Quitar foco de cualquier TextField antes de cerrar modales
      FocusScope.of(context).unfocus();

      // Cerrar el modal de selección de empresa
      Navigator.of(context).pop();

      // Si el modal fue abierto desde el flujo de login -> navegar a Home
      if (widget.shouldNavigateToHome) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        // Si fue abierto desde el perfil (shouldNavigateToHome == false),
        // cerramos también el modal del perfil (bottom sheet) para volver
        // a la pantalla principal y permitir que HomeScreen escuche el
        // cambio de empresa y se refresque.
        // Hacemos un pop adicional si es posible.
        if (Navigator.of(context).canPop()) {
          try {
            FocusScope.of(context).unfocus();
            Navigator.of(context).pop();
          } catch (_) {
            // Ignorar si no se puede hacer pop adicional
          }
        }
      }

      // Mostrar mensaje de confirmación con más detalles
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Empresa: ${selectedUserCompany.empresa}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (selectedUserCompany.sucursal.isNotEmpty)
                Text(
                  'Sucursal: ${selectedUserCompany.sucursal}',
                  style: const TextStyle(fontSize: 8),
                ),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(35),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: const Duration(seconds: 2),
        ),
      );

      // Asegurar que el foco y el teclado se oculten una vez que la navegación termine
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FocusManager.instance.primaryFocus?.unfocus();
        SystemChannels.textInput.invokeMethod('TextInput.hide');
      });
    }
  }

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 8,
      shadowColor: Colors.blue.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade50, Colors.white, Colors.blue.shade50],
            stops: const [0.0, 0.5, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
<<<<<<< HEAD
            // Header con icono animado
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.blue.shade100, Colors.blue.shade200],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.business_center_rounded,
                size: 36,
                color: Colors.blue.shade800,
              ),
            ),
            const SizedBox(height: 20),

            // Título principal
            Text(
              '¡Bienvenido ${widget.userName}! 👋',
=======
            // Icono y título
            Text(
              '¡Bienvenido ${widget.userName} 👋!',
>>>>>>> 7c73e73c1453c44b7c3553a90b48f0a3b70b58f9
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Subtítulo
            Text(
              'Selecciona la empresa con la que vas a trabajar',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
<<<<<<< HEAD
            const SizedBox(height: 28),
=======
            const SizedBox(height: 14),
>>>>>>> 7c73e73c1453c44b7c3553a90b48f0a3b70b58f9

            // Contenido dinámico
            _buildContent(),

            const SizedBox(height: 32),

            // Botones de acción
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return _buildLoadingState();
    } else if (errorMessage != null) {
      return _buildErrorState();
    } else if (userCompanies.isEmpty) {
      return _buildEmptyState();
    } else {
      return _buildCompanyDropdown();
    }
  }

  Widget _buildLoadingState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Column(
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator.adaptive(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Cargando empresas...',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade200),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline_rounded,
              color: Colors.red.shade600,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            errorMessage!,
            style: TextStyle(
              color: Colors.red.shade700,
              fontSize: 14,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadUserCompanies,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Reintentar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border.all(color: Colors.orange.shade200),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.business_outlined,
              color: Colors.orange.shade600,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'No tienes empresas asignadas',
            style: TextStyle(
              color: Colors.orange.shade700,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Contacta con el administrador del sistema',
            style: TextStyle(color: Colors.orange.shade600, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 15, left: 8, right: 8),
          child: Text(
            'Empresa',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedCompany,
              hint: Text(
                'Selecciona una empresa',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
              ),
              isExpanded: true,
              icon: Icon(
                Icons.arrow_drop_down_rounded,
                color: Colors.blue.shade700,
                size: 24,
              ),
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(12),
              items: userCompanies.map((company) {
                return DropdownMenuItem<String>(
                  value: company.id.toString(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          company.empresa,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'RUC: ${company.ruc}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
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
      ],
    );
  }

  Widget _buildActionButtons() {
    final bool isEnabled =
        selectedCompany != null && !isLoading && userCompanies.isNotEmpty;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              side: BorderSide(color: Colors.grey.shade400),
              backgroundColor: Colors.white,
            ),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              boxShadow: isEnabled
                  ? [
                      BoxShadow(
                        color: Colors.blue.shade400.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [],
            ),
            child: ElevatedButton(
              onPressed: isEnabled ? _continueToHome : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: isEnabled
                    ? Colors.blue.shade700
                    : Colors.grey.shade400,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _getButtonText(),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (isEnabled) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getButtonText() {
    if (isLoading) return 'Cargando...';
    if (userCompanies.isEmpty && !isLoading) return 'Sin empresas';
    return 'Continuar';
  }
}
