import 'dart:ui';

import 'package:flutter/material.dart';

import '../helpers/ad_helper.dart';
import '../home/home_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with TickerProviderStateMixin {
  final PageController _controller = PageController();

  double page = 0;

  late final AnimationController _floatController;
  late final Animation<double> _floating;

  /// 2026 DATA
  final pages = const [
    {
      "title": "Download Videos",
      "desc":
          "Paste a video link and prepare it quickly with a smooth experience.",
      "icon": Icons.download_rounded,
    },
    {
      "title": "HD Quality",
      "desc":
          "Keep videos clear with HD output when available from the source.",
      "icon": Icons.high_quality_rounded,
    },
    {
      "title": "Fast & Smooth",
      "desc":
          "One tap flow with a clean interface and quick saving experience.",
      "icon": Icons.flash_on_rounded,
    },
  ];

  /// THEME
  static const Color primaryGreen = Color(0xff00E676);

  @override
  void initState() {
    super.initState();

    _controller.addListener(() {
      if (!mounted) return;

      setState(() {
        page = _controller.page ?? 0;
      });
    });

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);

    _floating = Tween<double>(begin: -12, end: 12).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    /// preload ads
    AdHelper.loadInterstitial();
  }

  @override
  void dispose() {
    _controller.dispose();
    _floatController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = page.round().clamp(0, pages.length - 1);

    final bottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          /// BACKGROUND
          AnimatedContainer(
            duration: const Duration(milliseconds: 700),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.lerp(
                    const Color(0xff050505),
                    const Color(0xff07140B),
                    page / 2,
                  )!,
                  Color.lerp(
                    const Color(0xff0D0D0D),
                    const Color(0xff101A12),
                    page / 2,
                  )!,
                  const Color(0xff111111),
                ],
              ),
            ),
          ),

          /// GRID
          Positioned.fill(child: CustomPaint(painter: _GridPainter())),

          /// GLOW
          Positioned(
            top: -120,
            right: -100,
            child: _GlowCircle(size: 320, color: primaryGreen.withOpacity(.16)),
          ),

          Positioned(
            bottom: -150,
            left: -100,
            child: _GlowCircle(
              size: 340,
              color: Colors.greenAccent.withOpacity(.08),
            ),
          ),

          /// GLASS
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(color: Colors.black.withOpacity(.08)),
            ),
          ),

          /// CONTENT
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 16),

                /// TOP BAR
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          color: Colors.white.withOpacity(.05),
                          border: Border.all(
                            color: Colors.white.withOpacity(.05),
                          ),
                        ),
                        child: const Text(
                          "2026 EDITION",
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                            fontSize: 11,
                          ),
                        ),
                      ),

                      /// SKIP
                      GestureDetector(
                        onTap: _goHome,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            color: Colors.white.withOpacity(.05),
                          ),
                          child: Text(
                            "Skip",
                            style: TextStyle(
                              color: Colors.white.withOpacity(.75),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                /// PAGES
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    physics: const BouncingScrollPhysics(),
                    itemCount: pages.length,
                    itemBuilder: (_, i) {
                      final p = pages[i];

                      final progress = (page - i).abs().clamp(0.0, 1.0);

                      return AnimatedBuilder(
                        animation: _floating,
                        builder: (_, __) {
                          return Transform.translate(
                            offset: Offset(progress * 80, _floating.value),
                            child: Opacity(
                              opacity: (1 - progress).clamp(0.0, 1.0),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 28,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    /// ICON GLASS CARD
                                    Transform.scale(
                                      scale: 1 - (progress * .15),
                                      child: Container(
                                        width: 230,
                                        height: 230,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            46,
                                          ),
                                          color: Colors.white.withOpacity(.05),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(
                                              .08,
                                            ),
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: primaryGreen.withOpacity(
                                                .30,
                                              ),
                                              blurRadius: 80,
                                              spreadRadius: 10,
                                            ),
                                          ],
                                        ),
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            /// INNER CIRCLE
                                            Container(
                                              width: 140,
                                              height: 140,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Colors.greenAccent.shade100,
                                                    primaryGreen,
                                                  ],
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: primaryGreen
                                                        .withOpacity(.5),
                                                    blurRadius: 40,
                                                  ),
                                                ],
                                              ),
                                            ),

                                            Icon(
                                              p["icon"] as IconData,
                                              size: 76,
                                              color: Colors.black,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 55),

                                    /// TITLE
                                    ShaderMask(
                                      shaderCallback: (bounds) {
                                        return const LinearGradient(
                                          colors: [
                                            Colors.white,
                                            Color(0xffD8FFE5),
                                            primaryGreen,
                                          ],
                                        ).createShader(bounds);
                                      },
                                      child: Text(
                                        p["title"] as String,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 36,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          letterSpacing: -.7,
                                          height: 1.1,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 22),

                                    /// DESC
                                    Text(
                                      p["desc"] as String,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 15.5,
                                        color: Colors.white.withOpacity(.60),
                                        height: 1.7,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),

                                    const SizedBox(height: 36),

                                    /// FEATURES
                                    Wrap(
                                      alignment: WrapAlignment.center,
                                      spacing: 12,
                                      runSpacing: 12,
                                      children: const [
                                        _FeatureChip(title: "HD Quality"),
                                        _FeatureChip(title: "Fast Speed"),
                                        _FeatureChip(title: "Easy Save"),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                /// INDICATOR
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(pages.length, (i) {
                    final active = currentIndex == i;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      width: active ? 30 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: active
                            ? const LinearGradient(
                                colors: [Color(0xff00E676), Color(0xff00C853)],
                              )
                            : null,
                        color: active ? null : Colors.white24,
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 28),

                /// BUTTON
                Padding(
                  padding: EdgeInsets.fromLTRB(24, 0, 24, bottom + 20),
                  child: GestureDetector(
                    onTap: () {
                      if (currentIndex == pages.length - 1) {
                        AdHelper.showInterstitial(() => _goHome());
                      } else {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOutCubic,
                        );
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 64,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(26),
                        gradient: const LinearGradient(
                          colors: [Color(0xff00E676), Color(0xff00C853)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primaryGreen.withOpacity(.35),
                            blurRadius: 30,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            currentIndex == pages.length - 1
                                ? "Get Started"
                                : "Continue",
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                              letterSpacing: .3,
                            ),
                          ),

                          const SizedBox(width: 10),

                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.black,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// GO HOME
  void _goHome() {
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
}

/// ================= FEATURE CHIP =================
class _FeatureChip extends StatelessWidget {
  final String title;

  const _FeatureChip({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withOpacity(.05),
        border: Border.all(color: Colors.white.withOpacity(.06)),
      ),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white.withOpacity(.80),
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}

/// ================= GRID =================
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(.03)
      ..strokeWidth = .6;

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
