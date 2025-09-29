import 'package:flutter/material.dart';

class ProfileModal extends StatefulWidget {
  const ProfileModal({super.key});

  @override
  State<ProfileModal> createState() => _ProfileModalState();
}

class _ProfileModalState extends State<ProfileModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final _formKey = GlobalKey<FormState>();
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  bool _isSaving = false;
  double _avatarScale = 1.0;
  bool _isDragging = false;
  double _totalDragOffset = 0.0;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.fastEaseInToSlowEaseOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.forward();
    });

    _setupFocusAnimations();
  }

  void _setupFocusAnimations() {
    for (var node in _focusNodes) {
      node.addListener(() {
        if (node.hasFocus) {
          setState(() {
            _avatarScale = 0.95;
          });
        } else {
          setState(() {
            _avatarScale = 1.0;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _closeModal() async {
    await _controller.reverse();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      await Future.delayed(const Duration(milliseconds: 1500));

      if (mounted) {
        setState(() {
          _isSaving = false;
        });

        await _showSuccessAnimation();
        await _closeModal();
      }
    }
  }

  Future<void> _showSuccessAnimation() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              child: const Icon(Icons.check_circle, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Text("Perfil actualizado correctamente"),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _onAvatarTap() {
    setState(() {
      _avatarScale = 0.8;
    });

    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        setState(() {
          _avatarScale = 1.0;
        });
      }
    });

    _showImageSourceDialog();
  }

  void _showImageSourceDialog() {
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

  void _handleDragUpdate(DragUpdateDetails details) {
    // Solo permitir arrastre hacia abajo
    if (details.primaryDelta! > 0) {
      setState(() {
        _isDragging = true;
        _totalDragOffset += details.primaryDelta!;
      });
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_isDragging) {
      // Si el arrastre fue significativo (más de 100px o velocidad alta), cerrar el modal
      if (_totalDragOffset > 100 || details.primaryVelocity! > 500) {
        _closeModal();
      } else {
        // Si no, animar de vuelta a la posición original
        _resetDragAnimation();
      }
    }
  }

  void _resetDragAnimation() {
    setState(() {
      _isDragging = false;
      _totalDragOffset = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: _handleDragUpdate,
      onVerticalDragEnd: _handleDragEnd,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        color: Colors.black.withOpacity(_isDragging ? 0.3 : 0.0),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: _isDragging ? _totalDragOffset * 0.5 : 0.0,
          ),
          child: SingleChildScrollView(
            physics: _isDragging ? const NeverScrollableScrollPhysics() : null,
            child: Transform.translate(
              offset: Offset(0, _isDragging ? _totalDragOffset : 0),
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 30),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(
                            _isDragging ? 0.1 : 0.3,
                          ),
                          blurRadius: 20,
                          offset: Offset(0, _isDragging ? -2 : 0),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header con botón de cerrar
                          _buildHeaderWithCloseButton(),

                          // Título con animación de slide
                          SlideTransition(
                            position: _slideAnimation,
                            child: _buildTitleSection(),
                          ),

                          const SizedBox(height: 32),

                          // Avatar con animación de escala
                          _buildAnimatedAvatar(),

                          const SizedBox(height: 32),

                          // Formulario con animaciones escalonadas
                          _buildAnimatedForm(),

                          const SizedBox(height: 32),

                          // Botones animados
                          _buildAnimatedActionButtons(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderWithCloseButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Espacio para alinear el título centrado
          const SizedBox(width: 40),

          // Indicador de arrastre
          Expanded(
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _isDragging ? Colors.grey[500] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                if (_isDragging) ...[
                  const SizedBox(height: 8),
                  Text(
                    _totalDragOffset > 100
                        ? "Suelta para cerrar"
                        : "Desliza para cerrar",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Botón de cerrar (X)
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _isDragging ? 0.0 : 1.0,
            child: IconButton(
              onPressed: _closeModal,
              icon: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 20, color: Colors.grey),
              ),
              splashRadius: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleSection() {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: _isDragging ? 0.7 : 1.0,
      child: Column(
        children: [
          const Text(
            "Perfil Profesional",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1D1F),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Actualiza tu información personal",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedAvatar() {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: _isDragging ? 0.5 : 1.0,
      child: AnimatedScale(
        scale: _avatarScale,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: GestureDetector(
          onTap: _isDragging ? null : _onAvatarTap,
          child: MouseRegion(
            cursor: _isDragging
                ? SystemMouseCursors.basic
                : SystemMouseCursors.click,
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.blue[400]!, Colors.purple[400]!],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(
                                _avatarScale == 0.8 ? 0.3 : 0.1,
                              ),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.camera_alt,
                          size: 18,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _isDragging ? 0.0 : 1.0,
                  child: Text(
                    "Toca para cambiar foto",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedForm() {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: _isDragging ? 0.3 : 1.0,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
            .animate(
              CurvedAnimation(
                parent: _controller,
                curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
              ),
            ),
        child: FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: _controller,
              curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
            ),
          ),
          child: Column(
            children: [
              _buildAnimatedFormSection(
                title: "Información Personal",
                icon: Icons.person_outline,
                fields: [
                  _buildAnimatedField(
                    0,
                    "Nombre completo",
                    "Ej: Ana Rodríguez",
                  ),
                  _buildAnimatedField(1, "Profesión", "Ej: Diseñadora UX"),
                ],
                delay: 0,
              ),

              const SizedBox(height: 24),

              _buildAnimatedFormSection(
                title: "Contacto",
                icon: Icons.contact_page_outlined,
                fields: [
                  _buildAnimatedField(
                    2,
                    "Email",
                    "ana@ejemplo.com",
                    TextInputType.emailAddress,
                  ),
                  _buildAnimatedField(
                    3,
                    "Teléfono",
                    "+34 600 000 000",
                    TextInputType.phone,
                  ),
                ],
                delay: 100,
              ),

              const SizedBox(height: 24),

              _buildAnimatedFormSection(
                title: "Información Adicional",
                icon: Icons.info_outline,
                fields: [
                  _buildAnimatedField(4, "Empresa", "Ej: Tech Solutions SA"),
                  _buildAnimatedField(5, "Ubicación", "Madrid, España"),
                ],
                delay: 200,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedFormSection({
    required String title,
    required IconData icon,
    required List<Widget> fields,
    required int delay,
  }) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + delay),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[100]!),
      ),
      curve: Curves.easeInOut,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...fields,
        ],
      ),
    );
  }

  Widget _buildAnimatedField(
    int index,
    String label,
    String hint, [
    TextInputType? keyboardType,
  ]) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOutBack,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _focusNodes[index].hasFocus
                      ? Colors.blue[400]!
                      : Colors.grey[200]!,
                  width: _focusNodes[index].hasFocus ? 1.5 : 1.0,
                ),
                boxShadow: _focusNodes[index].hasFocus
                    ? [
                        BoxShadow(
                          color: Colors.blue[100]!,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: IgnorePointer(
                ignoring: _isDragging,
                child: TextField(
                  focusNode: _focusNodes[index],
                  keyboardType: keyboardType,
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedActionButtons() {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: _isDragging ? 0.0 : 1.0,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
            .animate(
              CurvedAnimation(
                parent: _controller,
                curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
              ),
            ),
        child: FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: _controller,
              curve: const Interval(0.8, 1.0, curve: Curves.easeIn),
            ),
          ),
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                height: 50,
                child: _isSaving ? _buildLoadingButton() : _buildSaveButton(),
              ),
              const SizedBox(height: 12),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _isSaving ? 0.5 : 1.0,
                child: TextButton(
                  onPressed: _isSaving ? null : _closeModal,
                  child: Text(
                    "Cancelar",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1A1D1F),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.2),
      ),
      onPressed: _saveProfile,
      child: const Text(
        "Guardar cambios",
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
    );
  }

  Widget _buildLoadingButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[400],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
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
          Text(
            "Guardando...",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
