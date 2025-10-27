import 'dart:ui';
import 'package:flutter/material.dart';
import '../controllers/login_controller.dart';

class LoginView extends StatefulWidget {
  final LoginController controller;
  final VoidCallback onLogin;
  final VoidCallback onForgotPassword;
  final VoidCallback onRegister;

  const LoginView({
    super.key,
    required this.controller,
    required this.onLogin,
    required this.onForgotPassword,
    required this.onRegister,
  });

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
<<<<<<< HEAD
  late Animation<Offset> _slideAnimation;
=======

  final FocusNode _userFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  bool _isUserFocused = false;
  bool _isPasswordFocused = false;
>>>>>>> 7c73e73c1453c44b7c3553a90b48f0a3b70b58f9

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

<<<<<<< HEAD
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

=======
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _setupFocusListeners();
    _animationController.forward();
  }

  void _setupFocusListeners() {
    _userFocusNode.addListener(() {
      setState(() => _isUserFocused = _userFocusNode.hasFocus);
    });
    _passwordFocusNode.addListener(() {
      setState(() => _isPasswordFocused = _passwordFocusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _userFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _onLoginPressed() {
    _userFocusNode.unfocus();
    _passwordFocusNode.unfocus();
    widget.onLogin();
  }

>>>>>>> 7c73e73c1453c44b7c3553a90b48f0a3b70b58f9
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 700;

    return Scaffold(
<<<<<<< HEAD
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade800,
              Colors.blue.shade600,
              Colors.blue.shade400,
            ],
            stops: const [0.1, 0.5, 0.9],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.all(isSmallScreen ? 20.0 : 24.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHeader(isSmallScreen),
                      if (!isSmallScreen) const SizedBox(height: 40),
                      _buildLoginForm(context, isSmallScreen),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
=======
      resizeToAvoidBottomInset:
          true, // ✅ Evita que el teclado tape el contenido
      backgroundColor: const Color(0xFFF2F6FC),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 30,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 40),
                          _buildLoginForm(),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                );
              },
>>>>>>> 7c73e73c1453c44b7c3553a90b48f0a3b70b58f9
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isSmallScreen) {
    return Column(
      children: [
<<<<<<< HEAD
        AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          width: isSmallScreen ? 80 : 100,
          height: isSmallScreen ? 80 : 100,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 16,
                offset: const Offset(0, 6),
=======
        Container(
          height: 90,
          width: 90,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0066FF), Color(0xFF00C2FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
>>>>>>> 7c73e73c1453c44b7c3553a90b48f0a3b70b58f9
              ),
            ],
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Colors.blue.shade50],
            ),
          ),
          child: Icon(
            Icons.person_outline_rounded,
            size: isSmallScreen ? 40 : 50,
            color: Colors.blue.shade700,
          ),
<<<<<<< HEAD
        ),
        const SizedBox(height: 24),
        Text(
          "Bienvenido",
          style: TextStyle(
            fontSize: isSmallScreen ? 28 : 32,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.5,
=======
          child: const Icon(
            Icons.receipt_long_rounded,
            color: Colors.white,
            size: 48,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          "Bienvenido a FcturASA",
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: Color(0xFF003366),
>>>>>>> 7c73e73c1453c44b7c3553a90b48f0a3b70b58f9
          ),
        ),
        const SizedBox(height: 8),
        Text(
<<<<<<< HEAD
          "Inicia sesión en tu cuenta",
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 16,
            color: Colors.white.withOpacity(0.9),
            fontWeight: FontWeight.w400,
          ),
=======
          "Accede con tu cuenta para continuar",
          style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
>>>>>>> 7c73e73c1453c44b7c3553a90b48f0a3b70b58f9
        ),
      ],
    );
  }

<<<<<<< HEAD
  Widget _buildLoginForm(BuildContext context, bool isSmallScreen) {
    return Card(
      elevation: 12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      shadowColor: Colors.black.withOpacity(0.25),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 24.0 : 32.0),
        child: Form(
          key: widget.controller.formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildUserField(context),
              const SizedBox(height: 20),
              _buildPasswordField(),
              const SizedBox(height: 16),
              const SizedBox(height: 24),
              _buildLoginButton(),
            ],
=======
  Widget _buildLoginForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 6),
>>>>>>> 7c73e73c1453c44b7c3553a90b48f0a3b70b58f9
          ),
        ],
      ),
      child: Form(
        key: widget.controller.formKey,
        child: Column(
          children: [
            _buildUserField(),
            const SizedBox(height: 20),
            _buildPasswordField(),
            const SizedBox(height: 30),
            _buildLoginButton(),
          ],
        ),
      ),
    );
  }

<<<<<<< HEAD
  Widget _buildUserField(BuildContext context) {
    return TextFormField(
      controller: widget.controller.userController,
      keyboardType: TextInputType.number,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: "Usuario o Email",
        labelStyle: TextStyle(
          color: Colors.grey.shade700,
          fontWeight: FontWeight.w500,
        ),
        hintText: "Ingresa tu usuario o email",
        hintStyle: TextStyle(
          color: Colors.grey.shade500,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: Container(
          margin: const EdgeInsets.all(10),
          child: Icon(
            Icons.person_outline_rounded,
            color: Colors.blue.shade700,
            size: 24,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
      ),
      validator: widget.controller.validateUser,
      textInputAction: TextInputAction.next,
      onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
      onChanged: (_) => setState(() {}),
=======
  Widget _buildUserField() {
    return TextFormField(
      controller: widget.controller.userController,
      focusNode: _userFocusNode,
      keyboardType: TextInputType.number,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        labelText: "Usuario o Email",
        labelStyle: TextStyle(
          color: _isUserFocused
              ? const Color(0xFF0066FF)
              : Colors.grey.shade700,
        ),
        prefixIcon: Icon(
          Icons.person_outline_rounded,
          color: _isUserFocused
              ? const Color(0xFF0066FF)
              : Colors.grey.shade600,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF0066FF), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      validator: widget.controller.validateUser,
      textInputAction: TextInputAction.next,
      onFieldSubmitted: (_) =>
          FocusScope.of(context).requestFocus(_passwordFocusNode),
>>>>>>> 7c73e73c1453c44b7c3553a90b48f0a3b70b58f9
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: widget.controller.passwordController,
<<<<<<< HEAD
      obscureText: widget.controller.obscurePassword,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: "Contraseña",
        labelStyle: TextStyle(
          color: Colors.grey.shade700,
          fontWeight: FontWeight.w500,
        ),
        hintText: "Ingresa tu contraseña",
        hintStyle: TextStyle(
          color: Colors.grey.shade500,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: Container(
          margin: const EdgeInsets.all(10),
          child: Icon(
            Icons.lock_outline_rounded,
            color: Colors.blue.shade700,
            size: 24,
=======
      focusNode: _passwordFocusNode,
      obscureText: widget.controller.obscurePassword,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        labelText: "Contraseña",
        labelStyle: TextStyle(
          color: _isPasswordFocused
              ? const Color(0xFF0066FF)
              : Colors.grey.shade700,
        ),
        prefixIcon: Icon(
          Icons.lock_outline_rounded,
          color: _isPasswordFocused
              ? const Color(0xFF0066FF)
              : Colors.grey.shade600,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            widget.controller.obscurePassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: _isPasswordFocused
                ? const Color(0xFF0066FF)
                : Colors.grey.shade600,
>>>>>>> 7c73e73c1453c44b7c3553a90b48f0a3b70b58f9
          ),
          onPressed: () => setState(() {
            widget.controller.togglePasswordVisibility();
          }),
        ),
<<<<<<< HEAD
        suffixIcon: Container(
          margin: const EdgeInsets.all(10),
          child: IconButton(
            icon: Icon(
              widget.controller.obscurePassword
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
              color: Colors.grey.shade600,
              size: 24,
            ),
            onPressed: () {
              setState(() {
                widget.controller.togglePasswordVisibility();
              });
            },
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
=======
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF0066FF), width: 2),
>>>>>>> 7c73e73c1453c44b7c3553a90b48f0a3b70b58f9
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
<<<<<<< HEAD
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
      ),
      validator: widget.controller.validatePassword,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => widget.onLogin(),
      onChanged: (_) => setState(() {}),
=======
      ),
      validator: widget.controller.validatePassword,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _onLoginPressed(),
>>>>>>> 7c73e73c1453c44b7c3553a90b48f0a3b70b58f9
    );
  }

  Widget _buildLoginButton() {
<<<<<<< HEAD
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
=======
    final isValid =
        widget.controller.userController.text.isNotEmpty &&
        widget.controller.passwordController.text.isNotEmpty;

    return SizedBox(
>>>>>>> 7c73e73c1453c44b7c3553a90b48f0a3b70b58f9
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          if (!widget.controller.isLoading)
            BoxShadow(
              color: Colors.blue.shade400.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isValid
              ? const Color(0xFF0066FF)
              : Colors.grey.shade400,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
<<<<<<< HEAD
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
        onPressed: widget.controller.isLoading ? null : widget.onLogin,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: widget.controller.isLoading
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white.withOpacity(0.8),
                    ),
                  ),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Ingresar",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                ),
        ),
=======
          elevation: isValid ? 6 : 0,
        ),
        onPressed: (isValid && !widget.controller.isLoading)
            ? _onLoginPressed
            : null,
        child: widget.controller.isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                "Iniciar sesión",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
>>>>>>> 7c73e73c1453c44b7c3553a90b48f0a3b70b58f9
      ),
    );
  }
}
