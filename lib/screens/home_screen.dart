import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/profile_modal.dart';
import '../widgets/informes_reporte_list.dart';
import '../widgets/reportes_list.dart';
import '../widgets/edit_reporte_modal.dart';
import '../widgets/nuevo_informe_modal.dart';
import '../widgets/tabbed_screen.dart';
import '../models/gasto_model.dart';
import '../models/reporte_informe_model.dart';
import '../services/api_service.dart';
import '../services/user_service.dart';
import '../services/company_service.dart';
import '../models/reporte_model.dart';
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
  bool _isLoading = false;

  // Datos para informes y revisión
  List<ReporteInforme> _informes = [];
  final List<Gasto> gastosRecepcion = [];

  @override
  void initState() {
    super.initState();
    _loadReportes();
    _loadInformes();
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
        user: UserService().currentUserCode,
        ruc: CompanyService().companyRuc,
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

  Future<void> _loadInformes() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final informes = await _apiService.getReportesRendicionInforme(
        id: '1',
        idrend: '1',
        user: UserService().currentUserCode,
        ruc: CompanyService().companyRuc,
      );
      if (!mounted) return;

      setState(() {
        _informes = informes;
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
            content: Text('Error al cargar informes: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Reintentar',
              textColor: Colors.white,
              onPressed: _loadInformes,
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

  void _actualizarInforme(ReporteInforme informeActualizado) {
    setState(() {
      final index = _informes.indexWhere(
        (i) => i.idInf == informeActualizado.idInf,
      );
      if (index != -1) {
        _informes[index] = informeActualizado;
      }
    });
  }

  void _eliminarInforme(ReporteInforme informe) {
    setState(() {
      _informes.remove(informe);
    });
  }

  void _mostrarEditarReporte(Reporte reporte) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) => EditReporteModal(reporte: reporte),
    );
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
        onTap: _mostrarEditarReporte,
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
          InformesReporteList(
            informes: _informes,
            auditoria: [],
            onInformeUpdated: _actualizarInforme,
            onInformeDeleted: _eliminarInforme,
            showEmptyStateButton: true,
            onEmptyStateButtonPressed: _agregarInforme,
            onRefresh: _loadInformes,
          ),
          InformesReporteList(
            informes: _informes.where((i) => i.estado == "Borrador").toList(),
            auditoria: [],
            onInformeUpdated: _actualizarInforme,
            onInformeDeleted: _eliminarInforme,
            showEmptyStateButton: false,
            onRefresh: _loadInformes,
          ),
        ],
      ),
    );
  }

  Widget _buildPantallaAditoria() {
    return Scaffold(
      appBar: CustomAppBar(
        hintText: "Buscar en Auditoría...",
        onProfilePressed: () => _mostrarEditarPerfil(context),
        notificationCount: _notificaciones,
        onNotificationPressed: _decrementarNotificaciones,
      ),
      body: TabbedScreen(
        tabLabels: const ["Todos"],
        tabColors: const [Colors.green],
        tabViews: [
          InformesReporteList(
            informes: _informes,
            auditoria: [],
            onInformeUpdated: _actualizarInforme,
            onInformeDeleted: _eliminarInforme,
            showEmptyStateButton: false,
            onRefresh: _loadInformes,
          ),
        ],
      ),
    );
  }

  Widget _buildPantallaRevision() {
    return Scaffold(
      appBar: CustomAppBar(
        hintText: "Buscar en Revisión...",
        onProfilePressed: () => _mostrarEditarPerfil(context),
        notificationCount: _notificaciones,
        onNotificationPressed: _decrementarNotificaciones,
      ),
      body: TabbedScreen(
        tabLabels: const ["Todos"],
        tabColors: const [Colors.green],
        tabViews: [
          InformesReporteList(
            informes: _informes,
            auditoria: [],
            onInformeUpdated: _actualizarInforme,
            onInformeDeleted: _eliminarInforme,
            showEmptyStateButton: false,
            onRefresh: _loadInformes,
          ),
        ],
      ),
    );
  }

  // ========== MÉTODOS DE INFORMES ==========

  Future<void> _agregarInforme() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) => NuevoInformeModal(
        onInformeCreated: (nuevoInforme) {
          // Después de crear el informe, recargamos la lista
          _loadInformes();
          _mostrarSnackInformeCreado(nuevoInforme);
        },
        onCancel: () {
          Navigator.of(context).pop();
        },
      ),
    );
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
      _buildPantallaAditoria(), // 3 - Configuración
      _buildPantallaRevision(), // 2 - Revisión
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton.extended(
              onPressed: _agregarInforme,
              backgroundColor: const Color.fromARGB(255, 195, 15, 15),
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
          NavigationDestination(
            icon: Icon(Icons.assignment_turned_in_outlined),
            label: "Aditoria",
          ),
          NavigationDestination(icon: Icon(Icons.inbox), label: "Revisión"),
        ],
      ),
    );
  }
}
