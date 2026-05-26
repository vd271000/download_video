import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../helpers/ad_helper.dart';
import '../share/extensions/language_service.dart';
import '../splash/onboarding_page.dart';

class LanguagePage extends StatefulWidget {
  const LanguagePage({super.key});

  @override
  State<LanguagePage> createState() => _LanguagePageState();
}

class _LanguagePageState extends State<LanguagePage>
    with TickerProviderStateMixin {
  String selected = "English";
  String query = "";

  final List<Map<String, String>> languages = const [
    {"name": "English", "flag": "🇺🇸"},
    {"name": "Tiếng Việt", "flag": "🇻🇳"},
    {"name": "Русский", "flag": "🇷🇺"},
    {"name": "Indonesia", "flag": "🇮🇩"},
    {"name": "हिंदी", "flag": "🇮🇳"},
    {"name": "العربية", "flag": "🇸🇦"},
    {"name": "ภาษาไทย", "flag": "🇹🇭"},
    {"name": "Español", "flag": "🇪🇸"},
    {"name": "Türkçe", "flag": "🇹🇷"},
    {"name": "Français", "flag": "🇫🇷"},
    {"name": "Português", "flag": "🇧🇷"},
    {"name": "Deutsch", "flag": "🇩🇪"},
    {"name": "Italiano", "flag": "🇮🇹"},
  ];

  List<Map<String, String>> filtered = [];

  bool _canContinue = false;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  /// 2026 THEME
  static const Color primaryGreen = Color(0xff00E676);
  static const Color softGreen = Color(0xff00C853);

  @override
  void initState() {
    super.initState();

    filtered = languages;

    /// FADE
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    /// Detect language
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final systemLang = LanguageService.detectSystemLanguage(context);

      if (mounted) {
        setState(() {
          selected = systemLang;
        });
      }
    });

    /// preload ad
    AdHelper.loadInterstitial();

    /// enable continue
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() => _canContinue = true);
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    setState(() {
      query = value;

      filtered = languages.where((e) {
        return e["name"]!
            .toLowerCase()
            .contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final bottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          /// BACKGROUND
          const _ModernBackground(),

          /// GLOW
          Positioned(
            top: -120,
            right: -100,
            child: _GlowCircle(
              size: 300,
              color: primaryGreen.withOpacity(.15),
            ),
          ),

          Positioned(
            bottom: -140,
            left: -90,
            child: _GlowCircle(
              size: 320,
              color: Colors.greenAccent.withOpacity(.08),
            ),
          ),

          /// CONTENT
          FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                SizedBox(height: top + 24),

                /// TITLE
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) {
                          return const LinearGradient(
                            colors: [
                              Colors.white,
                              Color(0xffC8FFD8),
                              primaryGreen,
                            ],
                          ).createShader(bounds);
                        },
                        child: const Text(
                          "Choose Language",
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -.5,
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        "Select your preferred app language",
                        style: TextStyle(
                          color: Colors.white.withOpacity(.55),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                /// SEARCH
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    height: 58,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      color: Colors.white.withOpacity(.04),
                      border: Border.all(
                        color: Colors.white.withOpacity(.06),
                      ),
                    ),
                    child: TextField(
                      onChanged: _onSearch,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                      cursorColor: primaryGreen,
                      decoration: InputDecoration(
                        hintText: "Search language...",
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(.35),
                        ),
                        border: InputBorder.none,
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: Colors.white.withOpacity(.6),
                        ),
                        contentPadding: const EdgeInsets.only(top: 16),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                /// LIST
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                    physics: const BouncingScrollPhysics(),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final lang = filtered[i];

                      final isSelected =
                          selected == lang["name"];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              selected = lang["name"]!;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              color: isSelected
                                  ? Colors.white.withOpacity(.08)
                                  : Colors.white.withOpacity(.035),
                              border: Border.all(
                                color: isSelected
                                    ? primaryGreen.withOpacity(.7)
                                    : Colors.white.withOpacity(.05),
                                width: 1.3,
                              ),
                              boxShadow: isSelected
                                  ? [
                                BoxShadow(
                                  color: primaryGreen
                                      .withOpacity(.18),
                                  blurRadius: 24,
                                  spreadRadius: 1,
                                ),
                              ]
                                  : [],
                            ),
                            child: Row(
                              children: [
                                /// FLAG
                                Container(
                                  width: 54,
                                  height: 54,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    borderRadius:
                                    BorderRadius.circular(18),
                                    color: Colors.white.withOpacity(.05),
                                  ),
                                  child: Text(
                                    lang["flag"]!,
                                    style: const TextStyle(
                                      fontSize: 28,
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 16),

                                /// NAME
                                Expanded(
                                  child: Text(
                                    lang["name"]!,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.white.withOpacity(.82),
                                    ),
                                  ),
                                ),

                                /// CHECK
                                AnimatedContainer(
                                  duration:
                                  const Duration(milliseconds: 250),
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected
                                        ? primaryGreen
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: isSelected
                                          ? primaryGreen
                                          : Colors.white24,
                                    ),
                                  ),
                                  child: isSelected
                                      ? const Icon(
                                    Icons.check_rounded,
                                    size: 18,
                                    color: Colors.black,
                                  )
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                /// BUTTON
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    10,
                    20,
                    bottom + 20,
                  ),
                  child: GestureDetector(
                    onTap: _canContinue
                        ? () {
                      Navigator.pushReplacement(
                        context,
                        PageRouteBuilder(
                          transitionDuration:
                          const Duration(milliseconds: 700),
                          pageBuilder:
                              (_, animation, __) {
                            return FadeTransition(
                              opacity: animation,
                              child:
                              const OnboardingPage(),
                            );
                          },
                        ),
                      );
                    }
                        : null,
                    child: AnimatedContainer(
                      duration:
                      const Duration(milliseconds: 300),
                      height: 62,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius:
                        BorderRadius.circular(24),
                        gradient: _canContinue
                            ? const LinearGradient(
                          colors: [
                            Color(0xff00E676),
                            Color(0xff00C853),
                          ],
                        )
                            : LinearGradient(
                          colors: [
                            Colors.white
                                .withOpacity(.08),
                            Colors.white
                                .withOpacity(.05),
                          ],
                        ),
                        boxShadow: _canContinue
                            ? [
                          BoxShadow(
                            color: primaryGreen
                                .withOpacity(.35),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ]
                            : [],
                      ),
                      child: Row(
                        mainAxisAlignment:
                        MainAxisAlignment.center,
                        children: [
                          Text(
                            "Continue",
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight:
                              FontWeight.w800,
                              color: _canContinue
                                  ? Colors.black
                                  : Colors.white38,
                              letterSpacing: .3,
                            ),
                          ),

                          const SizedBox(width: 10),

                          Icon(
                            Icons.arrow_forward_rounded,
                            color: _canContinue
                                ? Colors.black
                                : Colors.white38,
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
}

/// ================= BACKGROUND =================
class _ModernBackground extends StatelessWidget {
  const _ModernBackground();

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
              colors: [
                Color(0xff040404),
                Color(0xff0B0B0B),
                Color(0xff111111),
              ],
            ),
          ),
        ),

        /// GRID
        Positioned.fill(
          child: CustomPaint(
            painter: _GridPainter(),
          ),
        ),

        /// BLUR
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 30,
              sigmaY: 30,
            ),
            child: Container(
              color: Colors.black.withOpacity(.10),
            ),
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
      ..color = Colors.white.withOpacity(.03)
      ..strokeWidth = .6;

    const gap = 38.0;

    for (double x = 0; x < size.width; x += gap) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    for (double y = 0; y < size.height; y += gap) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
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

  const _GlowCircle({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color,
              blurRadius: 150,
              spreadRadius: 80,
            ),
          ],
        ),
      ),
    );
  }
}