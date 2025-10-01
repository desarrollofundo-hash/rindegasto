import 'package:flutter/material.dart';
import '../controllers/login_controller.dart';

class LoginView extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade700,
              Colors.blue.shade500,
              Colors.blue.shade300,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 40),
                  _buildLoginForm(context),
                  const SizedBox(height: 32),
                  _buildRegisterSection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(Icons.person, size: 50, color: Colors.blue.shade700),
        ),
        const SizedBox(height: 24),
        const Text(
          "Bienvenido",
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "Inicia sesión en tu cuenta",
          style: TextStyle(fontSize: 16, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildLoginForm(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      shadowColor: Colors.black.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Form(
          key: controller.formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildUserField(),
              const SizedBox(height: 20),
              _buildPasswordField(),
              const SizedBox(height: 16),
              _buildForgotPasswordButton(),
              const SizedBox(height: 24),
              _buildLoginButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserField() {
    return Builder(
      builder: (context) => TextFormField(
        controller: controller.userController,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          labelText: "Usuario",
          labelStyle: TextStyle(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            child: Icon(
              Icons.person_outline_rounded,
              color: Colors.blue.shade700,
              size: 24,
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        validator: controller.validateUser,
        textInputAction: TextInputAction.next,
        onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: controller.passwordController,
      obscureText: controller.obscurePassword,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        labelText: "Contraseña",
        labelStyle: TextStyle(
          color: Colors.grey.shade600,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Container(
          margin: const EdgeInsets.all(8),
          child: Icon(
            Icons.lock_outline_rounded,
            color: Colors.blue.shade700,
            size: 24,
          ),
        ),
        suffixIcon: Container(
          margin: const EdgeInsets.all(8),
          child: IconButton(
            icon: Icon(
              controller.obscurePassword
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
              color: Colors.grey.shade600,
              size: 24,
            ),
            onPressed: controller.togglePasswordVisibility,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      validator: controller.validatePassword,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => onLogin(),
    );
  }

  Widget _buildForgotPasswordButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: onForgotPassword,
        style: TextButton.styleFrom(padding: EdgeInsets.zero),
        child: Text(
          "¿Olvidaste tu contraseña?",
          style: TextStyle(
            color: Colors.blue.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          shadowColor: Colors.blue.shade300,
        ),
        onPressed: controller.isLoading ? null : onLogin,
        child: controller.isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                "Ingresar",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  Widget _buildRegisterSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "¿No tienes cuenta?",
          style: TextStyle(color: Colors.white.withOpacity(0.9)),
        ),
        TextButton(
          onPressed: onRegister,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          child: const Text(
            "Regístrate",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
}
