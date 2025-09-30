import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../widgets/company_selection_modal.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscurePassword = true;

  void _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String usuario = _userController.text.trim();
      String contrasena = _passwordController.text.trim();

      print('🚀 Iniciando login...');
      print('👤 Usuario: $usuario');

      final url =
          'http://190.119.200.124:45490/login/credencial?usuario=$usuario&contrasena=$contrasena&app=12';
      print('🌐 URL: $url');

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      print('📊 Status Code: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse.isNotEmpty) {
          final userData = jsonResponse[0];

          // Verificar que el usuario esté activo
          if (userData['estado'] == 'S') {
            print('✅ Login exitoso');
            print('👋 Bienvenido: ${userData['usenam']}');

            // Opcional: Guardar datos del usuario para uso posterior
            // Aquí podrías usar SharedPreferences o Provider para almacenar la sesión

            if (mounted) {
              // Mostrar modal de selección de empresa
              showDialog(
                context: context,
                barrierDismissible: false, // No permitir cerrar tocando fuera
                builder: (BuildContext context) {
                  return CompanySelectionModal(
                    userName: userData['usenam'] ?? 'Usuario',
                  );
                },
              );
            }
          } else {
            throw Exception('Usuario inactivo. Contacta al administrador.');
          }
        } else {
          throw Exception('Usuario o contraseña incorrectos');
        }
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Error en login: $e');

      if (mounted) {
        String errorMessage;
        if (e.toString().contains('TimeoutException')) {
          errorMessage = 'Tiempo de espera agotado. Verifica tu conexión.';
        } else if (e.toString().contains('SocketException')) {
          errorMessage = 'Sin conexión a internet. Verifica tu red.';
        } else if (e.toString().contains('Usuario inactivo')) {
          errorMessage = 'Usuario inactivo. Contacta al administrador.';
        } else if (e.toString().contains('Usuario o contraseña incorrectos')) {
          errorMessage = 'Usuario o contraseña incorrectos';
        } else {
          errorMessage = 'Error al iniciar sesión. Intenta nuevamente.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String? _validateUser(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa tu DNI/usuario';
    }
    if (value.length < 8) {
      return 'El DNI debe tener al menos 8 dígitos';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa tu contraseña';
    }
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    return null;
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  @override
  void dispose() {
    _userController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

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
                  // Logo y título superior
                  Column(
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
                        child: Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.blue.shade700,
                        ),
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
                  ),

                  const SizedBox(height: 40),

                  // Card del formulario
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    // ignore: deprecated_member_use
                    shadowColor: Colors.black.withOpacity(0.3),
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Campo de usuario
                            TextFormField(
                              controller: _userController,
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
                              validator: _validateUser,
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (_) =>
                                  FocusScope.of(context).nextFocus(),
                            ),
                            const SizedBox(height: 20),

                            // Campo de contraseña
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
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
                                      _obscurePassword
                                          ? Icons.visibility_off_rounded
                                          : Icons.visibility_rounded,
                                      color: Colors.grey.shade600,
                                      size: 24,
                                    ),
                                    onPressed: _togglePasswordVisibility,
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
                              validator: _validatePassword,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _login(),
                            ),
                            const SizedBox(height: 16),

                            // Olvidé contraseña
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  // Navegar a pantalla de recuperación
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                ),
                                child: Text(
                                  "¿Olvidaste tu contraseña?",
                                  style: TextStyle(
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Botón de login
                            SizedBox(
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
                                onPressed: _isLoading ? null : _login,
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 3,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : const Text(
                                        "Ingresar",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Registrarse
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "¿No tienes cuenta?",
                        // ignore: deprecated_member_use
                        style: TextStyle(color: Colors.white.withOpacity(0.9)),
                      ),
                      TextButton(
                        onPressed: () {
                          // Navegar a pantalla de registro
                        },
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
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
