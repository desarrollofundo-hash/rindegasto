import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../services/company_service.dart';
import '../widgets/company_selection_modal.dart';

class ProfileModalController with ChangeNotifier {
  // Animation Controller
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Form and focus management
  final formKey = GlobalKey<FormState>();
  final List<FocusNode> focusNodes = List.generate(6, (index) => FocusNode());

  // Avatar and drag state
  double _avatarScale = 1.0;
  bool _isDragging = false;
  double _totalDragOffset = 0.0;

  // Getters
  AnimationController get animationController => _animationController;
  Animation<double> get scaleAnimation => _scaleAnimation;
  Animation<double> get fadeAnimation => _fadeAnimation;
  Animation<Offset> get slideAnimation => _slideAnimation;
  double get avatarScale => _avatarScale;
  bool get isDragging => _isDragging;
  double get totalDragOffset => _totalDragOffset;

  void initializeAnimations(TickerProvider vsync) {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: vsync,
    );

    _scaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.fastEaseInToSlowEaseOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _setupFocusAnimations();
  }

  void startAnimation() {
    _animationController.forward();
  }

  void _setupFocusAnimations() {
    for (var node in focusNodes) {
      node.addListener(() {
        if (node.hasFocus) {
          _avatarScale = 0.95;
        } else {
          _avatarScale = 1.0;
        }
        notifyListeners();
      });
    }
  }

  Future<void> closeModal(BuildContext context) async {
    await _animationController.reverse();
    if (context.mounted) {
      Navigator.pop(context);
    }
  }

  void onAvatarTap() {
    _avatarScale = 0.8;
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 150), () {
      _avatarScale = 1.0;
      notifyListeners();
    });
  }

  void showImageSourceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ScaleTransition(
        scale: CurvedAnimation(
          parent: ModalRoute.of(context)!.animation!,
          curve: Curves.easeOutBack,
        ),
        child: AlertDialog(
          title: const Text("Cambiar foto de perfil"),
          content: const Text("Selecciona una opción"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cámara"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Galería"),
            ),
          ],
        ),
      ),
    );
  }

  void handleDragUpdate(DragUpdateDetails details) {
    if (details.primaryDelta! > 0) {
      _isDragging = true;
      _totalDragOffset += details.primaryDelta!;
      notifyListeners();
    }
  }

  void handleDragEnd(DragEndDetails details, BuildContext context) {
    if (_isDragging) {
      if (_totalDragOffset > 100 || details.primaryVelocity! > 500) {
        closeModal(context);
      } else {
        resetDragAnimation();
      }
    }
  }

  void resetDragAnimation() {
    _isDragging = false;
    _totalDragOffset = 0.0;
    notifyListeners();
  }

  String getFieldValue(int index) {
    switch (index) {
      case 0: // Nombre
        return UserService().currentUserName;
      case 1: // DNI
        return UserService().currentUserDni;
      case 4: // Empresa
        return CompanyService().currentUserCompany;
      case 5: // RUC
        return CompanyService().companyRuc;
      default:
        return '';
    }
  }

  bool isFieldReadOnly(int index) {
    switch (index) {
      case 0: // Nombre
        return UserService().currentUserName.isNotEmpty;
      case 1: // DNI
        return UserService().currentUserDni.isNotEmpty;
      case 4: // Empresa
        return CompanyService().currentUserCompany.isNotEmpty;
      case 5: // RUC
        return CompanyService().companyRuc.isNotEmpty;
      default:
        return false;
    }
  }

  Future<void> logout(BuildContext context) async {
    // Limpiar la sesión del usuario
    UserService().clearCurrentUser();
    CompanyService().clearCurrentCompany();

    // Cerrar el modal primero
    await closeModal(context);

    // Navegar al login y limpiar toda la pila de navegación
    if (context.mounted) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
    }
  }

  void onChangeCompany(BuildContext context) {
    final userService = UserService();
    final userId = int.tryParse(userService.currentUserCode) ?? 0;
    final userName = userService.currentUserName;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return CompanySelectionModal(
          userName: userName,
          userId: userId,
          shouldNavigateToHome: false,
        );
      },
    );
  }

  void dispose() {
    _animationController.dispose();
    for (var node in focusNodes) {
      node.dispose();
    }
    super.dispose();
  }
}
