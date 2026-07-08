import 'dart:async';
import 'dart:ui';

import 'package:download_video/splash/splash_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../helpers/ad_helper.dart';

/// ================= MODERN WHITE 2026 VERSION =================
/// 👉 UI clean kiểu iOS 2026 + glassmorphism trắng + xanh lá neon
/// 👉 Premium hơn nền đen nếu app muốn cảm giác nhẹ / trust / modern

class StartPage extends StatefulWidget {
  const StartPage({super.key});

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> with TickerProviderStateMixin {
  late final AnimationController _mainController;
  late final AnimationController _floatController;
  late final AnimationController _textController;

  late final Animation<double> _logoScale;
  late final Animation<double> _floatAnim;

  late final Animation<Offset> _textSlide;
  late final Animation<double> _textFade;

  Timer? _timer;

  /// 2026 COLORS
  static const Color primaryGreen = Color(0xff00E676);

  static const Color softGreen = Color(0xff00C853);

  @override
  void initState() {
    super.initState();

    /// preload ads
    AdHelper.loadInterstitial();

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _logoScale = Tween<double>(begin: .72, end: 1).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeOutBack),
    );

    _floatAnim = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _textSlide = Tween<Offset>(begin: const Offset(0, .35), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
        );

    _textFade = CurvedAnimation(parent: _textController, curve: Curves.easeIn);

    Future.delayed(const Duration(milliseconds: 450), () {
      if (mounted) {
        _textController.forward();
      }
    });

    _startTimer();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _floatController.dispose();
    _textController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 700),
          pageBuilder: (_, animation, __) {
            return FadeTransition(
              opacity: animation,
              child: const SplashPage(),
            );
          },
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          /// BACKGROUND
          const _WhiteBackground(),

          /// GREEN GLOW
          Positioned(
            top: -100,
            right: -80,
            child: _GlowCircle(size: 260, color: primaryGreen.withOpacity(.15)),
          ),

          Positioned(
            bottom: -120,
            left: -100,
            child: _GlowCircle(size: 320, color: softGreen.withOpacity(.10)),
          ),

          /// CONTENT
          SafeArea(
            child: Center(
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _mainController,
                  _floatController,
                ]),
                builder: (_, __) {
                  return Transform.translate(
                    offset: Offset(0, _floatAnim.value),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          /// LOGO CARD
                          Transform.scale(
                            scale: _logoScale.value,
                            child: Container(
                              padding: const EdgeInsets.all(30),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(38),

                                /// GLASS WHITE
                                color: Colors.white.withOpacity(.75),

                                border: Border.all(
                                  color: Colors.white,
                                  width: 1.5,
                                ),

                                boxShadow: [
                                  BoxShadow(
                                    color: primaryGreen.withOpacity(.18),
                                    blurRadius: 60,
                                    spreadRadius: 6,
                                  ),

                                  BoxShadow(
                                    color: Colors.black.withOpacity(.06),
                                    blurRadius: 30,
                                    offset: const Offset(0, 14),
                                  ),
                                ],
                              ),

                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(30),
                                child: Image.asset(
                                  'assets/logo/logo.png',
                                  width: 115,
                                  height: 115,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 42),

                          /// TITLE
                          SlideTransition(
                            position: _textSlide,
                            child: FadeTransition(
                              opacity: _textFade,
                              child: Column(
                                children: [
                                  /// TITLE
                                  ShaderMask(
                                    shaderCallback: (bounds) {
                                      return const LinearGradient(
                                        colors: [
                                          Color(0xff111111),
                                          Color(0xff00C853),
                                        ],
                                      ).createShader(bounds);
                                    },
                                    child: const Text(
                                      "Snap Video",
                                      style: TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        letterSpacing: -.8,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  /// SUBTITLE CHIP
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(30),
                                      color: Colors.white.withOpacity(.70),

                                      border: Border.all(
                                        color: Colors.black.withOpacity(.04),
                                      ),
                                    ),
                                    child: const Text(
                                      "Fast • HD • Video Saver",
                                      style: TextStyle(
                                        color: Color(0xff444444),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 58),

                          /// LOADER
                          const _WhiteModernLoader(),

                          const SizedBox(height: 26),

                          Text(
                            "Preparing experience...",
                            style: TextStyle(
                              color: Colors.black.withOpacity(.45),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          /// VERSION
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                "2026 Edition",
                style: TextStyle(
                  color: Colors.black.withOpacity(.20),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ================= WHITE BG =================

class _WhiteBackground extends StatelessWidget {
  const _WhiteBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        /// BASE
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xffFDFDFD), Color(0xffF5F7F8), Color(0xffEEF2F3)],
            ),
          ),
        ),

        /// GRID
        Positioned.fill(child: CustomPaint(painter: _WhiteGridPainter())),

        /// BLUR
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(color: Colors.white.withOpacity(.05)),
          ),
        ),
      ],
    );
  }
}

/// ================= GLOW =================

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: color, blurRadius: 140, spreadRadius: 70),
          ],
        ),
      ),
    );
  }
}

/// ================= GRID =================

class _WhiteGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(.03)
      ..strokeWidth = .7;

    const gap = 38.0;

    for (double x = 0; x < size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y < size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

/// ================= LOADER =================

class _WhiteModernLoader extends StatefulWidget {
  const _WhiteModernLoader();

  @override
  State<_WhiteModernLoader> createState() => _WhiteModernLoaderState();
}

class _WhiteModernLoaderState extends State<_WhiteModernLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _dot(int index) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final delay = index * .2;

        final value = ((_controller.value - delay) % 1.0);

        final scale = .7 + (value * .5);

        return Transform.scale(
          scale: scale,
          child: Container(
            width: 13,
            height: 13,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xff00E676).withOpacity(.45 + (value * .55)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xff00E676).withOpacity(.30),
                  blurRadius: 12,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [_dot(0), _dot(1), _dot(2)],
      ),
    );
  }
}
