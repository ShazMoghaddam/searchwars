import 'dart:math';
import 'package:flutter/material.dart';
import '../theme.dart';

/// Full-screen milestone celebration overlay — shown at 10, 25, 50.
class MilestoneOverlay extends StatefulWidget {
  final int score;
  final VoidCallback onDone;

  const MilestoneOverlay({super.key, required this.score, required this.onDone});

  @override
  State<MilestoneOverlay> createState() => _MilestoneOverlayState();
}

class _MilestoneOverlayState extends State<MilestoneOverlay>
    with TickerProviderStateMixin {
  late AnimationController _entryCtrl, _exitCtrl, _confettiCtrl;
  late Animation<double> _scale, _fade, _exitFade;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 500));
    _exitCtrl  = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 400));
    _confettiCtrl = AnimationController(vsync: this,
        duration: const Duration(seconds: 2))..repeat();

    _scale    = CurvedAnimation(parent: _entryCtrl, curve: Curves.elasticOut);
    _fade     = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeIn);
    _exitFade = Tween<double>(begin: 1, end: 0)
        .animate(CurvedAnimation(parent: _exitCtrl, curve: Curves.easeOut));

    _entryCtrl.forward();

    // Auto-dismiss after 2s
    Future.delayed(const Duration(milliseconds: 2000), () async {
      if (!mounted) return;
      await _exitCtrl.forward();
      widget.onDone();
    });
  }

  @override
  void dispose() {
    _entryCtrl.dispose(); _exitCtrl.dispose(); _confettiCtrl.dispose();
    super.dispose();
  }

  (String, String, Color) get _info {
    if (widget.score >= 50)
      return ('🏆', 'LEGENDARY!\n50 correct!', AppColors.gold);
    if (widget.score >= 25)
      return ('🔥', 'ON FIRE!\n25 correct!', const Color(0xFFFF6B35));
    return ('⚡', '10 in a row!', AppColors.correct);
  }

  @override
  Widget build(BuildContext context) {
    final (emoji, label, color) = _info;
    return FadeTransition(
      opacity: _exitFade,
      child: GestureDetector(
        onTap: () async {
          await _exitCtrl.forward();
          widget.onDone();
        },
        child: Container(
          color: Colors.black.withOpacity(0.75),
          child: Stack(children: [
            // Confetti
            AnimatedBuilder(
              animation: _confettiCtrl,
              builder: (_, __) => CustomPaint(
                painter: _MilestoneConfetti(progress: _confettiCtrl.value,
                    color: color),
                child: const SizedBox.expand(),
              ),
            ),
            // Content
            Center(
              child: FadeTransition(
                opacity: _fade,
                child: ScaleTransition(
                  scale: _scale,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 80)),
                      const SizedBox(height: 16),
                      Text(label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 32, fontWeight: FontWeight.w800,
                            color: color, letterSpacing: -0.5, height: 1.2,
                          )),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: color.withOpacity(0.15),
                          border: Border.all(color: color.withOpacity(0.4)),
                        ),
                        child: Text('Tap to continue',
                            style: TextStyle(
                                fontSize: 14, color: color,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _MilestoneConfetti extends CustomPainter {
  final double progress;
  final Color color;
  static final _rng = Random(7);
  static final _particles = List.generate(80, (_) => _P(_rng));

  const _MilestoneConfetti({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      final t = (progress + p.offset) % 1.0;
      final x = p.x * size.width;
      final y = t * (size.height + 50) - 25;
      final paint = Paint()
        ..color = p.useColor ? color.withOpacity((1 - t) * 0.9)
                             : p.col.withOpacity((1 - t) * 0.9);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(t * p.spin * 2 * pi);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero,
              width: p.size, height: p.size * 0.45),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_MilestoneConfetti old) => old.progress != progress;
}

class _P {
  final double x, size, offset, spin;
  final Color col;
  final bool useColor;
  _P(Random r)
      : x = r.nextDouble(), size = r.nextDouble() * 10 + 5,
        offset = r.nextDouble(), spin = r.nextDouble() * 6 - 3,
        useColor = r.nextBool(),
        col = _cols[r.nextInt(_cols.length)];
  static const _cols = [
    Color(0xFF7C6FFF), Color(0xFF2ECC71), Color(0xFFFF6B35),
    Color(0xFFFFD700), Color(0xFFE91E8C), Color(0xFF29B6F6),
    Colors.white,
  ];
}
