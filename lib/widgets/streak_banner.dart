import 'package:flutter/material.dart';
import '../theme.dart';

/// Animated streak banner — slides in when streak >= 3.
class StreakBanner extends StatefulWidget {
  final int streak;
  const StreakBanner({super.key, required this.streak});

  @override
  State<StreakBanner> createState() => _StreakBannerState();
}

class _StreakBannerState extends State<StreakBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;
  late Animation<double>  _fade;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 450));
    _slide = Tween<Offset>(
        begin: const Offset(0, -1.5), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _fade  = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl,
            curve: const Interval(0, 0.4, curve: Curves.easeIn)));
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  String get _label {
    if (widget.streak >= 20) return '🔥 UNSTOPPABLE! ${widget.streak} in a row!';
    if (widget.streak >= 15) return '🔥 LEGENDARY! ${widget.streak} in a row!';
    if (widget.streak >= 10) return '🔥 ON FIRE! ${widget.streak} in a row!';
    if (widget.streak >= 7)  return '🔥 HOT STREAK! ${widget.streak} in a row!';
    if (widget.streak >= 5)  return '🔥 ${widget.streak} in a row!';
    return '🔥 ${widget.streak} in a row!';
  }

  Color get _color {
    if (widget.streak >= 10) return const Color(0xFFFF6B35);
    if (widget.streak >= 7)  return const Color(0xFFFFB300);
    return AppColors.correct;
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: _color.withOpacity(0.15),
              border: Border.all(color: _color.withOpacity(0.6), width: 1.5),
              boxShadow: [
                BoxShadow(color: _color.withOpacity(0.3),
                    blurRadius: 16, offset: const Offset(0, 4)),
              ],
            ),
            child: Text(_label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700,
                  color: _color, letterSpacing: 0.3,
                )),
          ),
        ),
      ),
    );
  }
}
