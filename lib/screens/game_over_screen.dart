import 'dart:math';
import 'package:flutter/material.dart';
import '../services/score_service.dart';
import '../services/ad_service.dart';
import '../theme.dart';
import '../widgets/share_button.dart';
import 'home_screen.dart';
import 'leaderboard_screen.dart';
import 'player_setup_screen.dart';

class GameOverScreen extends StatefulWidget {
  final int score;
  final String categoryId;
  final String? subcategoryId;
  final String playerName;
  final bool twoPlayer;
  final int p1Score, p2Score, winner;
  final String p1Name, p2Name;

  const GameOverScreen({
    super.key,
    required this.score,
    required this.categoryId,
    this.subcategoryId,
    this.playerName = 'Player 1',
    this.twoPlayer = false,
    this.p1Score = 0, this.p2Score = 0, this.winner = 0,
    this.p1Name = 'Player 1', this.p2Name = 'Player 2',
  });

  @override
  State<GameOverScreen> createState() => _GameOverScreenState();
}

class _GameOverScreenState extends State<GameOverScreen>
    with TickerProviderStateMixin {
  bool _isNewRecord = false;
  int _highScore = 0;
  bool _submitted = false;   // prevents double-submission
  late AnimationController _entryCtrl, _confettiCtrl;
  late Animation<double> _fadeAnim, _scaleAnim, _slideAnim;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 800));
    _confettiCtrl = AnimationController(vsync: this,
        duration: const Duration(seconds: 3))..repeat();
    _fadeAnim  = CurvedAnimation(parent: _entryCtrl,
        curve: const Interval(0, 0.5, curve: Curves.easeIn));
    _scaleAnim = CurvedAnimation(parent: _entryCtrl,
        curve: const Interval(0.2, 0.8, curve: Curves.elasticOut));
    _slideAnim = CurvedAnimation(parent: _entryCtrl,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut));
    _load();
  }

  Future<void> _load() async {
    if (!widget.twoPlayer) {
      final hs = await ScoreService.getHighScore(widget.categoryId);
      final newRec = await ScoreService.setHighScoreIfBeaten(
          widget.categoryId, widget.score);
      setState(() { _highScore = hs; _isNewRecord = newRec; });
    }
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose(); _confettiCtrl.dispose();
    super.dispose();
  }

  bool get _showConfetti => widget.twoPlayer
      ? widget.winner != 0
      : (_isNewRecord || widget.score >= 10);

  void _goLeaderboard({String? name, int? score}) {
    setState(() => _submitted = true);
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => LeaderboardScreen(
        submitName:     name,
        submitScore:    score,
        submitCategory: widget.categoryId,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(children: [
          if (_showConfetti) _ConfettiLayer(controller: _confettiCtrl),
          FadeTransition(
            opacity: _fadeAnim,
            child: widget.twoPlayer ? _buildTwoPlayer() : _buildSinglePlayer(),
          ),
        ]),
      ),
    );
  }

  // ── Single player ─────────────────────────────────────────────────────────

  Widget _buildSinglePlayer() {
    final color = AppTheme.categoryColor(widget.categoryId);
    final tier = widget.score >= 20 ? 4 : widget.score >= 15 ? 3
               : widget.score >= 10 ? 2 : widget.score >= 5  ? 1 : 0;
    final faces  = ['😩', '😅', '😊', '🤩', '🏆'];
    final titles = ['Keep trying!', 'Not Bad!', 'Well Played!', 'Incredible!', 'Legendary!'];
    final subs   = [
      "Don't give up, ${widget.playerName}!",
      "You're getting there, ${widget.playerName}!",
      "Nice one, ${widget.playerName}!",
      "You're amazing, ${widget.playerName}!",
      "${widget.playerName}, you're a legend!",
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 26),
      child: Column(children: [
        const Spacer(),
        ScaleTransition(scale: _scaleAnim, child: Column(children: [
          Text(faces[tier], style: const TextStyle(fontSize: 80)),
          const SizedBox(height: 16),
          Text(titles[tier], style: TextStyle(
              fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.6,
              color: _isNewRecord ? AppColors.gold : AppColors.textPrimary)),
          const SizedBox(height: 6),
          Text(subs[tier], textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
        ])),
        const SizedBox(height: 28),

        // Score card
        SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
              .animate(_slideAnim),
          child: Container(
            width: double.infinity, padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24), color: AppColors.surface,
              border: Border.all(
                color: _isNewRecord ? AppColors.gold.withOpacity(0.5) : color.withOpacity(0.3),
                width: _isNewRecord ? 2 : 1.5,
              ),
            ),
            child: Column(children: [
              if (_isNewRecord) ...[
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.emoji_events_rounded, color: AppColors.gold, size: 18),
                  const SizedBox(width: 6),
                  Text('New Personal Best!', style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.gold)),
                ]),
                const SizedBox(height: 16),
              ],
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                _BigStat(label: 'Score', value: '${widget.score}', color: color),
                Container(width: 1, height: 50, color: AppColors.cardBorder),
                _BigStat(label: 'Best',
                    value: '${_isNewRecord ? widget.score : _highScore}',
                    color: AppColors.gold),
              ]),
            ]),
          ),
        ),

        const Spacer(),

        // Submit to leaderboard
        if (widget.score > 0)
          _ActionBtn(
            label: _submitted ? 'View Leaderboard' : 'Submit to Leaderboard',
            icon: Icons.leaderboard_rounded,
            color: _submitted ? AppColors.textSecondary : AppColors.gold,
            filled: false,
            onTap: () {
              // Always pass the score — server checks if it's a new personal best
              _goLeaderboard(name: widget.playerName, score: widget.score);
            },
          ),
        const SizedBox(height: 10),

        // Watch ad for extra life (shown when lives = 0 and ads available)
        if (!widget.twoPlayer && AdService.isAdReady)
          _WatchAdButton(
            onAdComplete: () => Navigator.pushReplacement(context, MaterialPageRoute(
              builder: (_) => PlayerSetupScreen(
                categoryId: widget.categoryId,
                subcategoryId: widget.subcategoryId,
                twoPlayerMode: false,
              ),
            )),
          ),
        if (!widget.twoPlayer && AdService.isAdReady) const SizedBox(height: 10),

        _ActionBtn(label: 'Play Again', icon: Icons.replay_rounded,
            color: color, filled: true,
            onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(
              builder: (_) => PlayerSetupScreen(
                categoryId: widget.categoryId,
                subcategoryId: widget.subcategoryId,
                twoPlayerMode: false,
              ),
            ))),
        const SizedBox(height: 10),
        _ActionBtn(label: 'Choose Category', icon: Icons.grid_view_rounded,
            color: AppColors.textSecondary, filled: false,
            onTap: () => Navigator.pushAndRemoveUntil(context,
                MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false)),
        const SizedBox(height: 28),
      ]),
    );
  }

  // ── Two player ────────────────────────────────────────────────────────────

  Widget _buildTwoPlayer() {
    final p1Color  = const Color(0xFF29B6F6);
    final p2Color  = const Color(0xFFFF6B6B);
    final winColor = widget.winner == 1 ? p1Color : widget.winner == 2 ? p2Color : AppColors.gold;
    final catColor = AppTheme.categoryColor(widget.categoryId);
    final (title, subtitle, face) = widget.winner == 0
        ? ("It's a Tie!", 'Great game, both of you!', '🤝')
        : widget.winner == 1
            ? ('${widget.p1Name} Wins!', '${widget.p1Name} knows the internet better!', '🥇')
            : ('${widget.p2Name} Wins!', '${widget.p2Name} knows the internet better!', '🏆');
    final winnerName  = widget.winner == 1 ? widget.p1Name : widget.p2Name;
    final winnerScore = widget.winner == 1 ? widget.p1Score : widget.p2Score;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 26),
      child: Column(children: [
        const Spacer(),
        ScaleTransition(scale: _scaleAnim, child: Column(children: [
          Text(face, style: const TextStyle(fontSize: 80)),
          const SizedBox(height: 16),
          Text(title, textAlign: TextAlign.center, style: TextStyle(
              fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5,
              color: winColor)),
          const SizedBox(height: 6),
          Text(subtitle, textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        ])),
        const SizedBox(height: 28),

        SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
              .animate(_slideAnim),
          child: Row(children: [
            Expanded(child: _PlayerCard(
              name: widget.p1Name, score: widget.p1Score,
              isWinner: widget.winner == 1, color: p1Color,
              face: widget.winner == 1 ? '😄' : widget.winner == 0 ? '😊' : '😔',
            )),
            const SizedBox(width: 12),
            Expanded(child: _PlayerCard(
              name: widget.p2Name, score: widget.p2Score,
              isWinner: widget.winner == 2, color: p2Color,
              face: widget.winner == 2 ? '😄' : widget.winner == 0 ? '😊' : '😔',
            )),
          ]),
        ),

        const Spacer(),

        if (widget.winner != 0 && winnerScore > 0)
          _ActionBtn(
            label: 'Submit ${widget.winner == 1 ? widget.p1Name : widget.p2Name}\'s Score',
            icon: Icons.leaderboard_rounded,
            color: AppColors.gold, filled: false,
            onTap: () => _goLeaderboard(name: winnerName, score: winnerScore),
          ),
        const SizedBox(height: 10),
        _ActionBtn(label: 'Play Again', icon: Icons.replay_rounded,
            color: catColor, filled: true,
            onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(
              builder: (_) => PlayerSetupScreen(
                categoryId: widget.categoryId,
                subcategoryId: widget.subcategoryId,
                twoPlayerMode: true,
              ),
            ))),
        const SizedBox(height: 10),
        _ActionBtn(label: 'Choose Category', icon: Icons.grid_view_rounded,
            color: AppColors.textSecondary, filled: false,
            onTap: () => Navigator.pushAndRemoveUntil(context,
                MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false)),
        const SizedBox(height: 28),
      ]),
    );
  }
}

  String _catLabel(String id) => const {
    'shuffle':'Shuffle','sports':'Sports','celebrity':'Celebrity',
    'culture':'TV & Music','tech':'Tech','gaming':'Gaming',
    'food':'Food','geography':'Geography','history':'History',
    'politics':'Politics','science':'Science','automotive':'Automotive',
  }[id] ?? id;

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _BigStat extends StatelessWidget {
  final String label, value; final Color color;
  const _BigStat({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: TextStyle(fontSize: 52, fontWeight: FontWeight.w700,
        color: color, letterSpacing: -1.5)),
    Text(label, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
  ]);
}

class _PlayerCard extends StatelessWidget {
  final String name, face; final int score; final bool isWinner; final Color color;
  const _PlayerCard({required this.name, required this.face, required this.score,
      required this.isWinner, required this.color});
  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 400),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(22), color: AppColors.surface,
      border: Border.all(
        color: isWinner ? color.withOpacity(0.6) : AppColors.cardBorder,
        width: isWinner ? 2.5 : 1.5,
      ),
      boxShadow: isWinner ? [BoxShadow(
        color: color.withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 6))] : [],
    ),
    child: Column(children: [
      Text(face, style: const TextStyle(fontSize: 40)),
      const SizedBox(height: 8),
      Text(name, overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
              color: isWinner ? color : AppColors.textSecondary)),
      const SizedBox(height: 4),
      Text('$score', style: TextStyle(fontSize: 46, fontWeight: FontWeight.w700,
          color: isWinner ? color : AppColors.textSecondary, letterSpacing: -1)),
      Text('correct', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      if (isWinner) ...[
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20), color: color.withOpacity(0.15)),
          child: Text('WINNER', style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w800,
              color: color, letterSpacing: 1.5)),
        ),
      ],
    ]),
  );
}

class _ActionBtn extends StatelessWidget {
  final String label; final IconData icon;
  final Color color; final bool filled; final VoidCallback onTap;
  const _ActionBtn({required this.label, required this.icon,
      required this.color, required this.filled, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: filled ? color : Colors.transparent,
        border: filled ? null : Border.all(color: color.withOpacity(0.45)),
        boxShadow: filled ? [BoxShadow(
          color: color.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))] : [],
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: filled ? Colors.white : color, size: 18),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
            color: filled ? Colors.white : color)),
      ]),
    ),
  );
}

// ─── Confetti ─────────────────────────────────────────────────────────────────

class _ConfettiLayer extends StatelessWidget {
  final AnimationController controller;
  const _ConfettiLayer({required this.controller});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (_, __) => CustomPaint(
      painter: _ConfettiPainter(progress: controller.value),
      child: const SizedBox.expand(),
    ),
  );
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  static final _rng = Random(42);
  static final _particles = List.generate(60, (_) => _Particle(_rng));
  const _ConfettiPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      final t = (progress + p.offset) % 1.0;
      final x = p.x * size.width;
      final y = t * (size.height + 40) - 20;
      final paint = Paint()..color = p.color.withOpacity((1 - t) * 0.85);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(t * p.spin * 2 * pi);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.45),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}

class _Particle {
  final double x, size, offset, spin;
  final Color color;
  _Particle(Random r)
      : x = r.nextDouble(), size = r.nextDouble() * 8 + 5,
        offset = r.nextDouble(), spin = r.nextDouble() * 4 - 2,
        color = _cols[r.nextInt(_cols.length)];
  static const _cols = [
    Color(0xFF7C6FFF), Color(0xFF2ECC71), Color(0xFFFF6B35),
    Color(0xFFFFD700), Color(0xFFE91E8C), Color(0xFF29B6F6),
  ];
}

// ─── Two-player submit row ────────────────────────────────────────────────────

class _TwoPlayerSubmitRow extends StatefulWidget {
  final String p1Name, p2Name;
  final int p1Score, p2Score;
  final String categoryId;
  final void Function(String name, int score) onSubmit;

  const _TwoPlayerSubmitRow({
    required this.p1Name, required this.p1Score,
    required this.p2Name, required this.p2Score,
    required this.categoryId, required this.onSubmit,
  });

  @override
  State<_TwoPlayerSubmitRow> createState() => _TwoPlayerSubmitRowState();
}

class _TwoPlayerSubmitRowState extends State<_TwoPlayerSubmitRow> {
  bool _p1Submitted = false;
  bool _p2Submitted = false;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      if (widget.p1Score > 0)
        Expanded(child: _SubmitBtn(
          name: widget.p1Name,
          score: widget.p1Score,
          color: const Color(0xFF29B6F6),
          submitted: _p1Submitted,
          onTap: () {
            setState(() => _p1Submitted = true);
            widget.onSubmit(widget.p1Name, widget.p1Score);
          },
        )),
      if (widget.p1Score > 0 && widget.p2Score > 0)
        const SizedBox(width: 10),
      if (widget.p2Score > 0)
        Expanded(child: _SubmitBtn(
          name: widget.p2Name,
          score: widget.p2Score,
          color: const Color(0xFFFF6B6B),
          submitted: _p2Submitted,
          onTap: () {
            setState(() => _p2Submitted = true);
            widget.onSubmit(widget.p2Name, widget.p2Score);
          },
        )),
    ]);
  }
}

class _SubmitBtn extends StatelessWidget {
  final String name;
  final int score;
  final Color color;
  final bool submitted;
  final VoidCallback onTap;

  const _SubmitBtn({
    required this.name, required this.score,
    required this.color, required this.submitted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: submitted ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: submitted
              ? AppColors.surface
              : color.withOpacity(0.12),
          border: Border.all(
            color: submitted
                ? AppColors.cardBorder
                : color.withOpacity(0.5),
            width: 1.5,
          ),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(
            submitted ? Icons.check_circle_rounded : Icons.leaderboard_rounded,
            color: submitted ? AppColors.correct : color,
            size: 18,
          ),
          const SizedBox(height: 4),
          Text(
            name,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w700,
              color: submitted ? AppColors.textSecondary : color,
            ),
          ),
          Text(
            submitted ? 'Submitted!' : 'Submit ($score)',
            style: TextStyle(
              fontSize: 10,
              color: submitted
                  ? AppColors.correct
                  : color.withOpacity(0.7),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Watch Ad button ──────────────────────────────────────────────────────────

class _WatchAdButton extends StatefulWidget {
  final VoidCallback onAdComplete;
  const _WatchAdButton({required this.onAdComplete});
  @override
  State<_WatchAdButton> createState() => _WatchAdButtonState();
}

class _WatchAdButtonState extends State<_WatchAdButton> {
  bool _loading = false;

  Future<void> _onTap() async {
    setState(() => _loading = true);
    final rewarded = await AdService.showRewardedAd();
    setState(() => _loading = false);
    if (rewarded && mounted) widget.onAdComplete();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: _loading ? null : _onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF7C6FFF), Color(0xFF29B6F6)],
          begin: Alignment.centerLeft, end: Alignment.centerRight,
        ),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _loading
            ? const SizedBox(width: 18, height: 18,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.play_circle_rounded, color: Colors.white, size: 20),
        const SizedBox(width: 8),
        const Text('Watch Ad for Extra Life ❤️',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                color: Colors.white)),
      ]),
    ),
  );
}
