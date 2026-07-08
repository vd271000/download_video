import 'dart:async';
import 'dart:developer' as dev;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/ad_helper.dart';
import '../home/home_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late final AnimationController _mainController;
  late final AnimationController _progressController;
  late final AnimationController _floatingController;
  late final AnimationController _rotateController;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoGlow;
  late final Animation<double> _progress;
  late final Animation<double> _floating;

  Timer? _timer;

  /// 2026 COLORS
  static const Color primaryGreen = Color(0xff00E676);
  static const Color softGreen = Color(0xff00C853);

  @override
  void initState() {
    super.initState();

    /// MAIN
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();

    /// FLOAT
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);

    /// ROTATE
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    /// PROGRESS
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward();

    _logoScale = Tween<double>(begin: 0.72, end: 1).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeOutBack),
    );

    _logoGlow = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeInOut),
    );

    _floating = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );

    _progress = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOutCubic,
    );

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _startTimer();
      }
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _progressController.dispose();
    _floatingController.dispose();
    _rotateController.dispose();

    _timer?.cancel();

    super.dispose();
  }

  /// TIMER
  void _startTimer() {
    _timer = Timer(const Duration(milliseconds: 250), () async {
      if (!mounted) return;

      final prefs = await SharedPreferences.getInstance();

      /// Nếu đã rate 4-5 sao rồi thì không hiện nữa
      final hasRated = prefs.getBool("has_rated") ?? false;

      dev.log("has_rated ${hasRated}");

      if (hasRated) {
        AdHelper.showInterstitial(() {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 700),
              pageBuilder: (_, animation, __) {
                return FadeTransition(opacity: animation, child: HomePage());
              },
            ),
          );
        });
      } else {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 700),
            pageBuilder: (_, animation, __) {
              return FadeTransition(opacity: animation, child: HomePage());
            },
          ),
        );
      }
      ;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          /// BACKGROUND
          AnimatedBuilder(
            animation: _rotateController,
            builder: (_, __) {
              return const _WhiteBackground();
            },
          ),

          /// TOP GLOW
          Positioned(
            top: -120,
            right: -100,
            child: _GlowCircle(size: 320, color: primaryGreen.withOpacity(.14)),
          ),

          /// BOTTOM GLOW
          Positioned(
            bottom: -160,
            left: -100,
            child: _GlowCircle(size: 360, color: softGreen.withOpacity(.10)),
          ),

          /// CONTENT
          SafeArea(
            child: Center(
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _mainController,
                  _floatingController,
                ]),
                builder: (_, __) {
                  return Transform.translate(
                    offset: Offset(0, _floating.value),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          /// LOGO WRAPPER
                          Transform.scale(
                            scale: _logoScale.value,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                /// OUTER GLOW
                                Container(
                                  width: 210,
                                  height: 210,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        primaryGreen.withOpacity(
                                          .18 * _logoGlow.value,
                                        ),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),

                                /// GLASS CARD
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(42),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                      sigmaX: 25,
                                      sigmaY: 25,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.all(28),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(42),
                                        color: Colors.white.withOpacity(.72),
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 1.4,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: primaryGreen.withOpacity(
                                              .18,
                                            ),
                                            blurRadius: 60,
                                            spreadRadius: 4,
                                          ),

                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              .06,
                                            ),
                                            blurRadius: 30,
                                            offset: const Offset(0, 12),
                                          ),
                                        ],
                                      ),

                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(30),
                                        child: Image.asset(
                                          'assets/logo/logo.png',
                                          width: 120,
                                          height: 120,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 42),

                          /// TITLE
                          ShaderMask(
                            shaderCallback: (bounds) {
                              return const LinearGradient(
                                colors: [Color(0xff111111), Color(0xff00C853)],
                              ).createShader(bounds);
                            },
                            child: const Text(
                              "Snap Video",
                              style: TextStyle(
                                fontSize: 38,
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
                              color: Colors.white.withOpacity(.78),
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
                                letterSpacing: .3,
                              ),
                            ),
                          ),

                          const SizedBox(height: 80),

                          /// LOADING
                          const _ModernLoader(),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          /// PROGRESS
          Positioned(
            left: 30,
            right: 30,
            bottom: bottomSafe + 58,
            child: _ModernProgressBar(progress: _progress),
          ),

          /// VERSION
          Positioned(
            bottom: bottomSafe + 22,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                "2026 Edition",
                style: TextStyle(
                  color: Colors.black.withOpacity(.22),
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

/// ================= BACKGROUND =================

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
              colors: [Color(0xffFFFFFF), Color(0xffF7F9FA), Color(0xffEEF2F3)],
            ),
          ),
        ),

        /// GRID
        Positioned.fill(child: CustomPaint(painter: _GridPainter())),

        /// BLUR
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(color: Colors.white.withOpacity(.02)),
          ),
        ),
      ],
    );
  }
}

/// ================= GRID =================

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(.03)
      ..strokeWidth = .7;

    const gap = 40.0;

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
            BoxShadow(color: color, blurRadius: 160, spreadRadius: 90),
          ],
        ),
      ),
    );
  }
}

/// ================= LOADER =================

class _ModernLoader extends StatefulWidget {
  const _ModernLoader();

  @override
  State<_ModernLoader> createState() => _ModernLoaderState();
}

class _ModernLoaderState extends State<_ModernLoader>
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

        final scale = .75 + (value * .45);

        return Transform.scale(
          scale: scale,
          child: Container(
            width: 14,
            height: 14,
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
      width: 100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [_dot(0), _dot(1), _dot(2)],
      ),
    );
  }
}

/// ================= PROGRESS =================

class _ModernProgressBar extends StatelessWidget {
  final Animation<double> progress;

  const _ModernProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (_, __) {
        return Column(
          children: [
            /// BAR
            ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Stack(
                children: [
                  /// BG
                  Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(.05),
                    ),
                  ),

                  /// ACTIVE
                  FractionallySizedBox(
                    widthFactor: progress.value,
                    child: Container(
                      height: 12,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.greenAccent.shade100,
                            const Color(0xff00E676),
                            const Color(0xff00C853),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xff00E676).withOpacity(.45),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            /// PERCENT
            Text(
              "${(progress.value * 100).toInt()}%",
              style: TextStyle(
                color: Colors.black.withOpacity(.45),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: .5,
              ),
            ),
          ],
        );
      },
    );
  }
}
