import 'package:flutter/material.dart';
import '../constants.dart';
import '../theme.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _bgCtrl, _logoCtrl, _textCtrl, _pulseCtrl;
  late Animation<double> _bgFade, _logoScale, _logoFade,
      _upArrow, _downArrow, _divider,
      _titleSlide, _titleFade, _tagFade, _pulse;

  @override
  void initState() {
    super.initState();

    _bgCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 600));
    _logoCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1000));
    _textCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 700));
    _pulseCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1200))..repeat(reverse: true);

    _bgFade    = CurvedAnimation(parent: _bgCtrl,   curve: Curves.easeIn);
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _logoCtrl,
            curve: const Interval(0.0, 0.6, curve: Curves.elasticOut)));
    _logoFade  = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _logoCtrl,
            curve: const Interval(0.0, 0.3, curve: Curves.easeIn)));
    _upArrow   = Tween<double>(begin: -30.0, end: 0.0).animate(
        CurvedAnimation(parent: _logoCtrl,
            curve: const Interval(0.3, 0.7, curve: Curves.easeOut)));
    _downArrow = Tween<double>(begin: 30.0, end: 0.0).animate(
        CurvedAnimation(parent: _logoCtrl,
            curve: const Interval(0.4, 0.8, curve: Curves.easeOut)));
    _divider   = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _logoCtrl,
            curve: const Interval(0.65, 1.0, curve: Curves.easeOut)));
    _titleSlide = Tween<double>(begin: 24.0, end: 0.0).animate(
        CurvedAnimation(parent: _textCtrl,
            curve: const Interval(0.0, 0.7, curve: Curves.easeOut)));
    _titleFade  = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _textCtrl,
            curve: const Interval(0.0, 0.5, curve: Curves.easeIn)));
    _tagFade    = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _textCtrl,
            curve: const Interval(0.4, 1.0, curve: Curves.easeIn)));
    _pulse      = Tween<double>(begin: 0.97, end: 1.03).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    // Sequence: bg → logo → text
    _bgCtrl.forward().then((_) async {
      await _logoCtrl.forward();
      await Future.delayed(const Duration(milliseconds: 100));
      await _textCtrl.forward();
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        Navigator.of(context).pushReplacement(PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ));
      }
    });
  }

  @override
  void dispose() {
    _bgCtrl.dispose(); _logoCtrl.dispose();
    _textCtrl.dispose(); _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FadeTransition(
        opacity: _bgFade,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── Logo ─────────────────────────────────────────────────────
              AnimatedBuilder(
                animation: Listenable.merge([_logoCtrl, _pulseCtrl]),
                builder: (_, __) => FadeTransition(
                  opacity: _logoFade,
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: ScaleTransition(
                      scale: _pulse,
                      child: Container(
                        width: 110, height: 110,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          color: AppColors.surface,
                          border: Border.all(color: AppColors.cardBorder, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.correct.withOpacity(0.25),
                              blurRadius: 32, offset: const Offset(0, -8),
                            ),
                            BoxShadow(
                              color: AppColors.wrong.withOpacity(0.25),
                              blurRadius: 32, offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(alignment: Alignment.center, children: [
                          // Divider
                          Opacity(
                            opacity: _divider.value,
                            child: Container(
                              height: 1.5,
                              margin: const EdgeInsets.symmetric(horizontal: 18),
                              color: AppColors.cardBorder,
                            ),
                          ),
                          // Up arrow
                          Transform.translate(
                            offset: Offset(0, _upArrow.value - 22),
                            child: Icon(Icons.keyboard_arrow_up_rounded,
                                color: AppColors.correct, size: 52),
                          ),
                          // Down arrow
                          Transform.translate(
                            offset: Offset(0, _downArrow.value + 22),
                            child: Icon(Icons.keyboard_arrow_down_rounded,
                                color: AppColors.wrong, size: 52),
                          ),
                        ]),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 36),

              // ── Title ────────────────────────────────────────────────────
              AnimatedBuilder(
                animation: _textCtrl,
                builder: (_, __) => Transform.translate(
                  offset: Offset(0, _titleSlide.value),
                  child: Opacity(
                    opacity: _titleFade.value,
                    child: Column(children: [
                      // SearchWars with coloured split
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(fontSize: 40, fontWeight: FontWeight.w800,
                              letterSpacing: -1.5, height: 1),
                          children: [
                            TextSpan(text: 'Search',
                                style: TextStyle(color: AppColors.textPrimary)),
                            TextSpan(text: 'Wars',
                                style: TextStyle(color: AppColors.correct)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Opacity(
                        opacity: _tagFade.value,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 7),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: AppColors.surface,
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Text(kAppTagline,
                              style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary)),
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
