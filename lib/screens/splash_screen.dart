import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // Constantes
  static const Duration _splashDuration = Duration(seconds: 3);
  static const Duration _animationDuration = Duration(milliseconds: 2500);

  // Colores dinámicos basados en tema
  Color get _primaryColor => Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF60A5FA) // Azul más claro para tema oscuro
      : const Color(0xFF3B82F6); // Azul para tema claro

  Color get _secondaryColor => Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF3B82F6) // Azul oscuro para tema oscuro
      : const Color(0xFF1E40AF); // Azul muy oscuro para tema claro

  Color get _accentColor => Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF34D399) // Verde más brillante para tema oscuro
      : const Color(0xFF10B981); // Verde para tema claro

  Color get _backgroundStart => Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF1F2937) // Gris oscuro
      : const Color(0xFFE0F2FE); // Azul muy claro

  Color get _backgroundEnd => Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF111827) // Gris más oscuro
      : const Color(0xFFF0FDF4); // Verde muy claro

  Color get _textColor => Theme.of(context).brightness == Brightness.dark
      ? Colors.white
      : const Color(0xFF1F2937); // Gris oscuro

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<double> _progressAnimation;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    // Detectar preferencia del sistema para reducir animaciones
    try {
      _reduceMotion =
          WidgetsBinding.instance.window.accessibilityFeatures.reduceMotion;
    } catch (_) {
      _reduceMotion = false;
    }

    _initializeAnimations();
    _navigateToLogin();
  }

  void _initializeAnimations() {
    // Si el usuario ha pedido reducir las animaciones, inicializamos
    // el controller en el estado final para evitar animaciones costosas.
    _controller = AnimationController(
      vsync: this,
      duration: _animationDuration,
    );

    // Logo aparece primero (0.0 - 0.4)
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.5, curve: Curves.elasticOut),
      ),
    );

    _rotationAnimation = Tween<double>(begin: -0.2, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutBack),
      ),
    );

    // Texto aparece después (0.3 - 0.7)
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.3, 0.7, curve: Curves.easeOutCubic),
          ),
        );

    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.6, curve: Curves.easeOut),
      ),
    );

    // Indicador aparece al final (0.6 - 1.0)
    _pulseAnimation =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 50),
          TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 50),
        ]).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.6, 1.0, curve: Curves.easeInOut),
          ),
        );

    // Progress animation (0.6 - 1.0)
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.linear),
      ),
    );

    _controller.forward();
  }

  void _navigateToLogin() {
    Duration delay = _splashDuration;
    if (_reduceMotion) {
      // Si se reduce movimiento, navegamos antes para no mantener la pantalla
      // innecesariamente.
      delay = const Duration(milliseconds: 600);
    }

    Timer(delay, () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_backgroundStart, _backgroundEnd],
            stops: [0.0, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Partículas de fondo
              RepaintBoundary(
                child: BackgroundParticles(reduceMotion: _reduceMotion),
              ),

              // Contenido principal
              Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo animado mejorado
                      _buildLogo(),
                      const SizedBox(height: 40),

                      // Texto principal con animación de slide
                      SlideTransition(
                        position: _slideAnimation,
                        child: FadeTransition(
                          opacity: _textFadeAnimation,
                          child: Column(
                            children: [
                              _buildTitle(),
                              const SizedBox(height: 20),
                              _buildSubtitle(),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 60),

                      // Indicador de carga con pulso
                      _buildLoadingIndicator(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    final screenWidth = MediaQuery.of(context).size.width;
    final logoSize = screenWidth < 400 ? 100.0 : 120.0;
    final iconSize = screenWidth < 400 ? 50.0 : 60.0;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform(
          transform: Matrix4.identity()
            ..scale(_reduceMotion ? 1.0 : _scaleAnimation.value)
            ..rotateZ(_reduceMotion ? 0.0 : _rotationAnimation.value),
          alignment: Alignment.center,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {}, // Sin acción, solo para el efecto visual
              borderRadius: BorderRadius.circular(logoSize / 2),
              child: Container(
                width: logoSize,
                height: logoSize,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_primaryColor, _secondaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _primaryColor.withOpacity(0.4),
                      blurRadius: 25,
                      offset: const Offset(0, 15),
                    ),
                    BoxShadow(
                      color: _accentColor.withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Semantics(
                  label: 'Logo FacturasAsa',
                  image: true,
                  child: Icon(
                    Icons.account_balance_wallet,
                    color: Colors.white,
                    size: iconSize,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTitle() {
    final screenWidth = MediaQuery.of(context).size.width;
    final fontSize = screenWidth < 400 ? 28.0 : 36.0;

    if (_reduceMotion) {
      return Text(
        'FacturasAsa',
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: _textColor,
          letterSpacing: -0.5,
        ),
      );
    }

    return TypingText(
      text: "FacturasAsa",
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: _textColor,
        letterSpacing: -0.5,
      ),
      typingSpeed: const Duration(milliseconds: 150),
    );
  }

  Widget _buildSubtitle() {
    final screenWidth = MediaQuery.of(context).size.width;
    final fontSize = screenWidth < 400 ? 14.0 : 16.0;

    return Text(
      "Gestión financiera inteligente",
      style: TextStyle(
        fontSize: fontSize,
        color: _textColor.withOpacity(0.7),
        fontWeight: FontWeight.w400,
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnimation, _progressAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _reduceMotion ? 1.0 : _pulseAnimation.value,
          child: SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              value: _progressAnimation.value,
              valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
              strokeWidth: 3,
            ),
          ),
        );
      },
    );
  }
}

// Widget para efecto Shimmer
class Shimmer extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const Shimmer({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();

    _animation = Tween<double>(
      begin: -1.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            // _animation.value va de -1.0 a 1.0; mapear a 0..1 para stops válidos
            final center = (_animation.value + 1.0) / 2.0;
            final left = (center - 0.25).clamp(0.0, 1.0);
            final middle = center.clamp(0.0, 1.0);
            final right = (center + 0.25).clamp(0.0, 1.0);

            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.white.withOpacity(0.0),
                Colors.white.withOpacity(0.85),
                Colors.white.withOpacity(0.0),
              ],
              stops: [left, middle, right],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

// Widget para animación de escritura
class TypingText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Duration typingSpeed;

  const TypingText({
    super.key,
    required this.text,
    required this.style,
    this.typingSpeed = const Duration(milliseconds: 100),
  });

  @override
  State<TypingText> createState() => _TypingTextState();
}

class _TypingTextState extends State<TypingText> {
  String _displayText = '';
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  void _startTyping() {
    _timer = Timer.periodic(widget.typingSpeed, (timer) {
      if (_currentIndex < widget.text.length) {
        setState(() {
          _displayText += widget.text[_currentIndex];
          _currentIndex++;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(_displayText, style: widget.style);
  }
}

// Widget para partículas de fondo
class BackgroundParticles extends StatefulWidget {
  final bool reduceMotion;

  const BackgroundParticles({super.key, this.reduceMotion = false});

  @override
  State<BackgroundParticles> createState() => _BackgroundParticlesState();
}

class _BackgroundParticlesState extends State<BackgroundParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );

    if (widget.reduceMotion) {
      // No repetir la animación si el usuario solicita reducir movimiento;
      // dejamos el controller en 0.0 (partículas estáticas)
      _controller.value = 0.0;
    } else {
      _controller.repeat();
    }

    // Crear partículas con una sola instancia de Random
    final rand = math.Random();
    for (int i = 0; i < 20; i++) {
      _particles.add(Particle(rand));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: ParticlePainter(_particles, _controller.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class Particle {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double opacity;

  Particle(math.Random rand)
    : x = rand.nextDouble(),
      y = rand.nextDouble(),
      size = rand.nextDouble() * 2 + 1,
      speed = rand.nextDouble() * 0.02 + 0.01,
      opacity = rand.nextDouble() * 0.1 + 0.05;
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double time;

  ParticlePainter(this.particles, this.time);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final particle in particles) {
      final x = (particle.x + time * particle.speed) % 1.0;
      final y = (particle.y + time * particle.speed * 0.5) % 1.0;

      paint.color = Colors.white.withOpacity(particle.opacity);

      canvas.drawCircle(
        Offset(x * size.width, y * size.height),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) => true;
}
