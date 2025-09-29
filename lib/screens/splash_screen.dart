//PARTE DE BIENVENIDA
//-------------------------
import 'dart:async';
import 'package:flutter/material.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // Constantes para facilitar mantenimiento
  static const Duration _splashDuration = Duration(seconds: 3);
  static const Color _backgroundColor = Colors.blueAccent;
  static const Color _textColor = Colors.white;
  static const Color _secondaryTextColor = Colors.white70;

  @override
  void initState() {
    super.initState();
    _navigateToLogin();
  }

  void _navigateToLogin() {
    Timer(_splashDuration, () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icono con animación sutil
                _buildAnimatedIcon(),
                const SizedBox(height: 30),
                // Texto principal
                _buildWelcomeText(),
                const SizedBox(height: 15),
                // Indicador de progreso
                _buildProgressIndicator(),
                const SizedBox(height: 20),
                // Texto secundario
                _buildLoadingText(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedIcon() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value,
            child: const Icon(Icons.flutter_dash, size: 120, color: _textColor),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeText() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeIn,
      builder: (context, value, child) {
        return FutureBuilder(
          future: Future.delayed(const Duration(milliseconds: 300)),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox.shrink();
            }
            return Opacity(
              opacity: value,
              child: const Text(
                "Bienvenido al sistema!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: _textColor,
                  height: 1.2,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProgressIndicator() {
    return SizedBox(
      width: 100,
      child: LinearProgressIndicator(
        backgroundColor: _textColor.withOpacity(0.3),
        valueColor: AlwaysStoppedAnimation<Color>(_textColor),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  Widget _buildLoadingText() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      builder: (context, value, child) {
        return FutureBuilder(
          future: Future.delayed(const Duration(milliseconds: 600)),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox.shrink();
            }
            return Opacity(
              opacity: value,
              child: const Text(
                "Cargando aplicación...",
                style: TextStyle(
                  color: _secondaryTextColor,
                  fontSize: 16,
                  letterSpacing: 0.5,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
