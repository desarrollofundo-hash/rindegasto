import 'package:flu2/models/user_model.dart';
import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/profile_modal.dart';
import '../widgets/gastos_list.dart';
import '../widgets/informes_list.dart';
import '../widgets/reportes_list.dart';
import '../widgets/tabbed_screen.dart';
import '../models/gasto_model.dart';
import '../services/api_service.dart';
import '../models/reporte_model.dart';
import './informes/agregar_informe_screen.dart';
import './informes/detalle_informe_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int _notificaciones = 5;

  // Variables para API
  final ApiService _apiService = ApiService();
  List<Reporte> _reportes = [];
  List<UserModel> _usuarios = [];
  bool _isLoading = false;

  // Datos para informes y revisión
  final List<Gasto> informes = [];
  final List<Gasto> gastosRecepcion = [];

  @override
  void initState() {
    super.initState();
    _loadReportes();
  }

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }

  // ========== MÉTODOS API ==========

  Future<void> _loadReportes() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final reportes = await _apiService.getReportesRendicionGasto(
        id: '1',
        idrend: '1',
        user: '1',
      );
      if (!mounted) return;

      setState(() {
        _reportes = reportes;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // Mostrar error en SnackBar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar reportes: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Reintentar',
              textColor: Colors.white,
              onPressed: _loadReportes,
            ),
          ),
        );
      }
    }
  }

  // ========== MÉTODOS REUTILIZABLES ==========

  void _mostrarEditarPerfil(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) => const ProfileModal(),
    );
  }

  void _decrementarNotificaciones() {
    setState(() {
      if (_notificaciones > 0) _notificaciones--;
    });
  }

  Future<void> _refreshConDelay() async {
    await Future.delayed(const Duration(seconds: 2));
  }

  void _actualizarInforme(Gasto informeActualizado) {
    setState(() {
      final index = informes.indexWhere(
        (i) => i.titulo == informeActualizado.titulo,
      );
      if (index != -1) {
        informes[index] = informeActualizado;
      }
    });
  }

  void _eliminarInforme(Gasto informe) {
    setState(() {
      informes.remove(informe);
    });
  }

  // ========== PANTALLAS REFACTORIZADAS ==========

  Widget _buildPantallaInicio() {
    return Scaffold(
      appBar: CustomAppBar(
        hintText: "Buscar reportes...",
        onProfilePressed: () => _mostrarEditarPerfil(context),
        notificationCount: _notificaciones,
        onNotificationPressed: _decrementarNotificaciones,
      ),
      body: ReportesList(
        reportes: _reportes,
        onRefresh: _loadReportes,
        isLoading: _isLoading,
      ),
    );
  }

  Widget _buildPantallaInformes() {
    return Scaffold(
      appBar: CustomAppBar(
        hintText: "Buscar informes...",
        onProfilePressed: () => _mostrarEditarPerfil(context),
        notificationCount: _notificaciones,
        onNotificationPressed: _decrementarNotificaciones,
      ),
      body: TabbedScreen(
        tabLabels: const ["Todos", "Borrador"],
        tabColors: const [Colors.indigo, Colors.indigo],
        tabViews: [
          InformesList(
            informes: informes,
            onInformeUpdated: _actualizarInforme,
            onInformeDeleted: _eliminarInforme,
            showEmptyStateButton: true,
            onEmptyStateButtonPressed: _agregarInforme,
          ),
          InformesList(
            informes: informes.where((i) => i.estado == "Borrador").toList(),
            onInformeUpdated: _actualizarInforme,
            onInformeDeleted: _eliminarInforme,
            showEmptyStateButton: false,
          ),
        ],
      ),
    );
  }

  Widget _buildPantallaRecepcion() {
    return Scaffold(
      appBar: CustomAppBar(
        hintText: "Buscar en Revisión...",
        onProfilePressed: () => _mostrarEditarPerfil(context),
        notificationCount: _notificaciones,
        onNotificationPressed: _decrementarNotificaciones,
      ),
      body: TabbedScreen(
        tabLabels: const ["Todos", "Borrador", "Transporte"],
        tabColors: const [Colors.green, Colors.green, Colors.green],
        tabViews: [
          GastosList(gastos: gastosRecepcion, onRefresh: _refreshConDelay),
          GastosList(
            gastos: gastosRecepcion
                .where((g) => g.estado == "Borrador")
                .toList(),
            onRefresh: _refreshConDelay,
          ),
          GastosList(
            gastos: gastosRecepcion
                .where((g) => g.categoria == "Transporte")
                .toList(),
            onRefresh: _refreshConDelay,
          ),
        ],
      ),
    );
  }

  Widget _buildPantallaConfiguracion() {
    return Scaffold(
      appBar: CustomAppBar(
        hintText: "Configuración...",
        onProfilePressed: () => _mostrarEditarPerfil(context),
        notificationCount: _notificaciones,
        onNotificationPressed: _decrementarNotificaciones,
      ),
      body: const Center(
        child: Text("⚙️ Configuración", style: TextStyle(fontSize: 20)),
      ),
    );
  }

  // ========== MÉTODOS DE INFORMES ==========

  Future<void> _agregarInforme() async {
    final nuevo = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AgregarInformeScreen()),
    );
    if (nuevo != null && nuevo is Gasto) {
      setState(() => informes.add(nuevo));
      _mostrarSnackInformeCreado(nuevo);
    }
  }

  void _mostrarSnackInformeCreado(Gasto nuevo) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("✅ Informe registrado con éxito"),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: "Ver",
          textColor: Colors.white,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DetalleInformeScreen(informe: nuevo),
              ),
            );
          },
        ),
      ),
    );
  }

  // ========== BUILD PRINCIPAL ACTUALIZADO ==========

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildPantallaInicio(), // 0 - Gastos
      _buildPantallaInformes(), // 1 - Informes
      _buildPantallaRecepcion(), // 2 - Revisión
      _buildPantallaConfiguracion(), // 3 - Config
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton.extended(
              onPressed: _agregarInforme,
              backgroundColor: const Color.fromARGB(255, 90, 113, 246),
              icon: const Icon(Icons.add),
              label: const Text("Agregar"),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index.clamp(0, pages.length - 1));
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.monetization_on),
            label: "Gastos",
          ),
          NavigationDestination(
            icon: Icon(Icons.description),
            label: "Informes",
          ),
          NavigationDestination(icon: Icon(Icons.inbox), label: "Revisión"),
          NavigationDestination(icon: Icon(Icons.settings), label: "Config"),
        ],
      ),
    );
  }
}
