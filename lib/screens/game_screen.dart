import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../data/dataset_loader.dart';
import '../widgets/category_background.dart';
import '../widgets/streak_banner.dart';
import '../widgets/milestone_overlay.dart';
import '../models/game_models.dart';
import '../services/score_service.dart';
import '../services/sound_service.dart';
import '../theme.dart';
import 'game_over_screen.dart';

enum GuessResult { none, correct, wrong }
enum GamePhase  { guessing, revealing, sliding }

class GameScreen extends StatefulWidget {
  final String categoryId;
  final String? subcategoryId;
  final bool twoPlayerMode;
  final String? playerOneName;
  final String? playerTwoName;

  const GameScreen({
    super.key,
    required this.categoryId,
    this.subcategoryId,
    this.twoPlayerMode = false,
    this.playerOneName,
    this.playerTwoName,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  static const int maxLives = 3;
  static const double _vsDividerH = 50.0;

  List<GamePair> _pairs = [];
  int _pairIndex = 0;
  late GameItem _topItem, _bottomItem;

  int _score = 0, _lives = maxLives;
  int _p1Score = 0, _p2Score = 0;
  int _p1Lives = maxLives, _p2Lives = maxLives;
  int _currentPlayer = 1;
  bool _showHandoff = false;

  GamePhase   _phase  = GamePhase.guessing;
  GuessResult _result = GuessResult.none;

  // Streak & milestone
  int  _streak = 0;
  bool _showStreak = false;
  bool _showMilestone = false;
  int  _milestoneScore = 0;
  final _milestones = {10, 25, 50};

  late AnimationController _slideCtrl, _flashCtrl, _scoreCtrl;
  late Animation<Offset> _slideAnim;
  late Animation<double> _flashAnim, _scoreAnim;

  String get _p1Name => widget.playerOneName ?? 'Player 1';
  String get _p2Name => widget.playerTwoName ?? 'Player 2';
  String get _activeName => _currentPlayer == 1 ? _p1Name : _p2Name;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _flashCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _scoreCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _slideAnim = Tween<Offset>(begin: Offset.zero, end: const Offset(0, -1))
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeInOut));
    _flashAnim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _flashCtrl, curve: Curves.easeOut));
    _scoreAnim = Tween<double>(begin: 1.0, end: 1.45)
        .animate(CurvedAnimation(parent: _scoreCtrl, curve: Curves.elasticOut));
    _loadPairs();
  }

  @override
  void dispose() {
    _slideCtrl.dispose(); _flashCtrl.dispose(); _scoreCtrl.dispose();
    super.dispose();
  }

  void _loadPairs() {
    var p = DatasetLoader.getPairs(categoryId: widget.categoryId, subcategoryId: widget.subcategoryId);
    if (p.isEmpty) p = DatasetLoader.getPairs(categoryId: 'shuffle');
    _pairs = p;
    _setupPair();
  }

  void _setupPair() {
    if (_pairIndex >= _pairs.length) { _endGame(); return; }
    final pair = _pairs[_pairIndex];
    if (Random().nextBool()) { _topItem = pair.itemA; _bottomItem = pair.itemB; }
    else                     { _topItem = pair.itemB; _bottomItem = pair.itemA; }
  }

  bool get _gameOver => widget.twoPlayerMode
      ? _p1Lives <= 0 && _p2Lives <= 0
      : _lives <= 0;

  Future<void> _onGuess(bool guessHigher) async {
    if (_phase != GamePhase.guessing || _showHandoff) return;

    final bottomHigher = _bottomItem.searchVolume > _topItem.searchVolume;
    final correct = guessHigher == bottomHigher;

    setState(() {
      _phase  = GamePhase.revealing;
      _result = correct ? GuessResult.correct : GuessResult.wrong;
    });

    if (correct) {
      SoundService.playCorrect();
      _scoreCtrl.forward(from: 0);
      _streak++;
      // Show streak banner at 3, 5, 7, 10, 15, 20...
      if (_streak >= 3) {
        setState(() => _showStreak = true);
        Future.delayed(const Duration(milliseconds: 1800), () {
          if (mounted) setState(() => _showStreak = false);
        });
      }
    } else {
      SoundService.playWrong();
      _streak = 0;
    }
    _flashCtrl.forward(from: 0);

    await Future.delayed(const Duration(milliseconds: 950));

    if (correct) {
      if (widget.twoPlayerMode) { if (_currentPlayer == 1) _p1Score++; else _p2Score++; }
      else { _score++; }
    } else {
      if (widget.twoPlayerMode) { if (_currentPlayer == 1) _p1Lives--; else _p2Lives--; }
      else { _lives--; }
    }

    if (_gameOver) { _endGame(); return; }

    if (widget.twoPlayerMode) {
      final next = _currentPlayer == 1 ? 2 : 1;
      final nextElim = (next == 1 && _p1Lives <= 0) || (next == 2 && _p2Lives <= 0);
      setState(() { _phase = GamePhase.sliding; _result = GuessResult.none; });
      await _slideCtrl.forward(from: 0);
      _pairIndex++;
      _slideCtrl.reset();
      if (!nextElim) {
        setState(() { _currentPlayer = next; _showHandoff = true; _phase = GamePhase.guessing; });
      } else {
        setState(() { _phase = GamePhase.guessing; });
        _setupPair();
      }
      return;
    }

    setState(() { _phase = GamePhase.sliding; _result = GuessResult.none; });
    await _slideCtrl.forward(from: 0);
    _pairIndex++;
    _slideCtrl.reset();
    setState(() => _phase = GamePhase.guessing);
    _setupPair();
  }

  void _dismissHandoff() {
    setState(() => _showHandoff = false);
    _setupPair();
  }

  void _endGame() {
    if (!widget.twoPlayerMode) {
      SoundService.playGameOver();
      ScoreService.setHighScoreIfBeaten(widget.categoryId, _score);
      ScoreService.recordGame(correct: _score, totalQuestions: _pairIndex, categoryId: widget.categoryId);
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => GameOverScreen(
          score: _score, categoryId: widget.categoryId,
          subcategoryId: widget.subcategoryId, playerName: _p1Name,
        ),
      ));
    } else {
      final winner = _p1Score > _p2Score ? 1 : (_p2Score > _p1Score ? 2 : 0);
      if (winner != 0) SoundService.playWin(); else SoundService.playGameOver();
      ScoreService.recordGame(correct: _p1Score + _p2Score, totalQuestions: _pairIndex * 2, categoryId: widget.categoryId);
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => GameOverScreen(
          score: 0, categoryId: widget.categoryId,
          subcategoryId: widget.subcategoryId, twoPlayer: true,
          p1Score: _p1Score, p2Score: _p2Score, winner: winner,
          p1Name: _p1Name, p2Name: _p2Name,
        ),
      ));
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.categoryColor(widget.categoryId);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(children: [
          Column(children: [
            // ── Top bar ──────────────────────────────────────────────────
            widget.twoPlayerMode ? _buildTwoBar(color) : _buildOneBar(color),

            // ── Cards area — LayoutBuilder guarantees equal heights ───────
            Expanded(
              child: LayoutBuilder(
                builder: (ctx, constraints) {
                  final cardH = (constraints.maxHeight - _vsDividerH) / 2;
                  return Stack(children: [
                    Column(children: [
                      // Top card (always revealed)
                      SizedBox(
                        height: cardH,
                        child: SlideTransition(
                          position: _phase == GamePhase.sliding
                              ? _slideAnim
                              : const AlwaysStoppedAnimation(Offset.zero),
                          child: _ItemCard(
                            item: _topItem, isRevealed: true,
                            color: color, result: GuessResult.none,
                            categoryId: widget.categoryId,
                          ),
                        ),
                      ),
                      // VS divider — exact fixed height
                      SizedBox(height: _vsDividerH, child: _vsDivider(color)),
                      // Bottom card (hidden until guess)
                      SizedBox(
                        height: cardH,
                        child: _ItemCard(
                          item: _bottomItem,
                          isRevealed: _phase != GamePhase.guessing,
                          color: color, result: _result,
                        ),
                      ),
                    ]),

                    // Colour flash overlay
                    if (_result != GuessResult.none)
                      FadeTransition(
                        opacity: ReverseAnimation(_flashAnim),
                        child: Container(
                          color: (_result == GuessResult.correct
                                  ? AppColors.correct : AppColors.wrong)
                              .withOpacity(0.12),
                        ),
                      ),
                  ]);
                },
              ),
            ),

            // ── Guess buttons ────────────────────────────────────────────
            _buildButtons(color),
          ]),

          // ── 2P Handoff overlay ───────────────────────────────────────────
          // Streak banner
          if (_showStreak && !widget.twoPlayerMode)
            Positioned(
              top: 60, left: 0, right: 0,
              child: StreakBanner(key: ValueKey(_streak), streak: _streak),
            ),

          // Milestone overlay
          if (_showMilestone)
            Positioned.fill(
              child: MilestoneOverlay(
                score: _milestoneScore,
                onDone: () => setState(() => _showMilestone = false),
              ),
            ),

          if (_showHandoff) _HandoffOverlay(
            name: _activeName, player: _currentPlayer, onReady: _dismissHandoff,
          ),
        ]),
      ),
    );
  }

  // ─── Single-player top bar ────────────────────────────────────────────────

  Widget _buildOneBar(Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      child: Row(
        children: [
          _BackBtn(),
          const SizedBox(width: 10),

          // Lives — fixed width so nothing shifts
          SizedBox(
            width: maxLives * 26.0,
            child: Row(
              children: List.generate(maxLives, (i) => Padding(
                padding: const EdgeInsets.only(right: 4),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    i < _lives ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    key: ValueKey('$i-$_lives'),
                    color: i < _lives
                        ? AppColors.wrong
                        : AppColors.textSecondary.withOpacity(0.35),
                    size: 22,
                  ),
                ),
              )),
            ),
          ),

          const Spacer(),

          // Mute toggle — always visible in game
          _MuteBtn(onToggle: () => setState(() {})),
          const SizedBox(width: 8),

          // Score pill — fixed width, no scale animation to avoid overflow
          SizedBox(
            width: 82,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.14),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.local_fire_department_rounded, color: color, size: 16),
                const SizedBox(width: 4),
                // Animate just the text colour briefly on correct
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700, color: color),
                  child: Text('$_score'),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Two-player top bar ───────────────────────────────────────────────────

  Widget _buildTwoBar(Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 0),
      child: Row(children: [
        _BackBtn(),
        const SizedBox(width: 6),
        Expanded(child: _PlayerBar(
          name: _p1Name, score: _p1Score, lives: _p1Lives,
          isActive: _currentPlayer == 1, maxLives: maxLives,
          color: const Color(0xFF29B6F6),
        )),
        const SizedBox(width: 6),
        Expanded(child: _PlayerBar(
          name: _p2Name, score: _p2Score, lives: _p2Lives,
          isActive: _currentPlayer == 2, maxLives: maxLives,
          color: const Color(0xFFFF6B6B),
        )),
        const SizedBox(width: 8),
        // Mute — always present
        _MuteBtn(onToggle: () => setState(() {})),
      ]),
    );
  }

  Widget _vsDivider(Color color) => Stack(alignment: Alignment.center, children: [
    Container(height: 1, color: AppColors.surfaceLight),
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.45), width: 1.5),
      ),
      child: Text('VS', style: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w700, color: color, letterSpacing: 2)),
    ),
  ]);

  Widget _buildButtons(Color color) => Padding(
    padding: const EdgeInsets.fromLTRB(14, 8, 14, 22),
    child: Row(children: [
      Expanded(child: _GuessBtn(
        label: 'HIGHER', icon: Icons.keyboard_arrow_up_rounded,
        color: AppColors.correct,
        enabled: _phase == GamePhase.guessing && !_showHandoff,
        onTap: () => _onGuess(true),
      )),
      const SizedBox(width: 10),
      Expanded(child: _GuessBtn(
        label: 'LOWER', icon: Icons.keyboard_arrow_down_rounded,
        color: AppColors.wrong,
        enabled: _phase == GamePhase.guessing && !_showHandoff,
        onTap: () => _onGuess(false),
      )),
    ]),
  );
}

// ─── Mute button (reusable, stateless — reads SoundService directly) ──────────

class _MuteBtn extends StatelessWidget {
  final VoidCallback onToggle;
  const _MuteBtn({required this.onToggle});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () { SoundService.toggleMute(); onToggle(); }, // toggleMute is async but fire-and-forget is intentional here
    child: Container(
      width: 38, height: 38,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Icon(
        SoundService.muted
            ? Icons.volume_off_rounded
            : Icons.volume_up_rounded,
        size: 18,
        color: SoundService.muted
            ? AppColors.textSecondary
            : AppColors.textPrimary,
      ),
    ),
  );
}

// ─── Item Card ────────────────────────────────────────────────────────────────
// No internal height logic — fills whatever SizedBox it's placed in.

class _ItemCard extends StatelessWidget {
  final GameItem item;
  final bool isRevealed;
  final Color color;
  final GuessResult result;
  final String categoryId;
  const _ItemCard({required this.item, required this.isRevealed,
      required this.color, required this.result,
      this.categoryId = 'shuffle'});

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 280),
    // Margin is symmetric — both cards will have identical insets
    margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      color: AppColors.surface,
      gradient: LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: result == GuessResult.correct
            ? [AppColors.correct.withOpacity(0.2), AppColors.surface]
            : result == GuessResult.wrong
                ? [AppColors.wrong.withOpacity(0.2), AppColors.surface]
                : [AppColors.surface, AppColors.surfaceLight.withOpacity(0.5)],
      ),
      border: Border.all(
        color: result == GuessResult.correct ? AppColors.correct.withOpacity(0.55)
             : result == GuessResult.wrong   ? AppColors.wrong.withOpacity(0.55)
             : AppColors.cardBorder,
        width: result != GuessResult.none ? 2 : 1.5,
      ),
    ),
    // SizedBox.expand so the card ALWAYS fills its SizedBox container fully
    child: SizedBox.expand(
      child: Stack(alignment: Alignment.center, children: [
        // Category watermark background
        CategoryBackground(categoryId: categoryId),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(item.name,
                textAlign: TextAlign.center, maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary, height: 1.25, letterSpacing: -0.3)),
            const SizedBox(height: 14),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              child: isRevealed ? _Revealed(item: item, color: color) : _Hidden(),
            ),
          ]),
        ),
        if (result != GuessResult.none)
          Positioned(top: 12, right: 12, child: _ResultBadge(result: result)),
      ]),
    ),
  );
}

class _ResultBadge extends StatelessWidget {
  final GuessResult result;
  const _ResultBadge({required this.result});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(7),
    decoration: BoxDecoration(
      color: result == GuessResult.correct ? AppColors.correct : AppColors.wrong,
      shape: BoxShape.circle,
      boxShadow: [BoxShadow(
        color: (result == GuessResult.correct ? AppColors.correct : AppColors.wrong)
            .withOpacity(0.4),
        blurRadius: 10, offset: const Offset(0, 2),
      )],
    ),
    child: Icon(
      result == GuessResult.correct ? Icons.check_rounded : Icons.close_rounded,
      color: Colors.white, size: 14,
    ),
  );
}

class _Revealed extends StatelessWidget {
  final GameItem item; final Color color;
  const _Revealed({required this.item, required this.color});
  @override
  Widget build(BuildContext context) => Column(key: const ValueKey('r'), children: [
    Text(item.formattedVolume, style: TextStyle(
        fontSize: 42, fontWeight: FontWeight.w700, color: color, letterSpacing: -1)),
    Text('monthly searches',
        style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
  ]);
}

class _Hidden extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(key: const ValueKey('h'), children: [
    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text('Higher ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
          color: AppColors.correct)),
      Text('or ', style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
      Text('Lower?', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
          color: AppColors.wrong)),
    ]),
    const SizedBox(height: 8),
    Row(mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (i) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: 7, height: 7,
          decoration: BoxDecoration(
            color: AppColors.textSecondary.withOpacity(0.22),
            shape: BoxShape.circle,
          ),
        ))),
  ]);
}

// ─── Guess Button ─────────────────────────────────────────────────────────────

class _GuessBtn extends StatelessWidget {
  final String label; final IconData icon;
  final Color color; final bool enabled; final VoidCallback onTap;
  const _GuessBtn({required this.label, required this.icon,
      required this.color, required this.enabled, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: enabled ? onTap : null,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: enabled ? color.withOpacity(0.13) : color.withOpacity(0.04),
        border: Border.all(
          color: enabled ? color.withOpacity(0.55) : color.withOpacity(0.15), width: 1.5),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: enabled ? color : color.withOpacity(0.3), size: 22),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
            color: enabled ? color : color.withOpacity(0.3), letterSpacing: 0.8)),
      ]),
    ),
  );
}

// ─── Player bar (2P) ──────────────────────────────────────────────────────────

class _PlayerBar extends StatelessWidget {
  final String name; final int score, lives, maxLives;
  final bool isActive; final Color color;
  const _PlayerBar({required this.name, required this.score, required this.lives,
      required this.maxLives, required this.isActive, required this.color});
  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 280),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(14),
      color: isActive ? color.withOpacity(0.16) : AppColors.surface,
      border: Border.all(
        color: isActive ? color.withOpacity(0.55) : AppColors.cardBorder, width: 1.5),
    ),
    child: Row(children: [
      Expanded(child: Text(name, overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
              color: isActive ? color : AppColors.textSecondary))),
      ...List.generate(maxLives, (i) => Icon(
        i < lives ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        color: i < lives ? AppColors.wrong : AppColors.textSecondary.withOpacity(0.25),
        size: 11,
      )),
      const SizedBox(width: 5),
      // Fixed width so score never shifts bar width
      SizedBox(
        width: 24,
        child: Text('$score', textAlign: TextAlign.right,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                color: isActive ? color : AppColors.textSecondary)),
      ),
    ]),
  );
}

// ─── Back button ──────────────────────────────────────────────────────────────

class _BackBtn extends StatelessWidget {
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () { SoundService.playTap(); Navigator.pop(context); },
    child: Container(
      width: 38, height: 38,
      decoration: BoxDecoration(
        color: AppColors.surface, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder)),
      child: const Icon(Icons.arrow_back_ios_new_rounded,
          size: 15, color: AppColors.textPrimary),
    ),
  );
}

// ─── Handoff overlay ──────────────────────────────────────────────────────────

class _HandoffOverlay extends StatelessWidget {
  final String name;
  final int player;
  final VoidCallback onReady;
  const _HandoffOverlay({required this.name, required this.player, required this.onReady});

  @override
  Widget build(BuildContext context) {
    final color = player == 1 ? const Color(0xFF29B6F6) : const Color(0xFFFF6B6B);
    return GestureDetector(
      onTap: onReady,
      child: Container(
        color: AppColors.background.withOpacity(0.97),
        child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 88, height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.15),
              border: Border.all(color: color.withOpacity(0.5), width: 2.5),
            ),
            child: Icon(Icons.person_rounded, color: color, size: 44),
          ),
          const SizedBox(height: 24),
          Text(name, style: TextStyle(fontSize: 34, fontWeight: FontWeight.w700,
              color: color, letterSpacing: -0.5)),
          const SizedBox(height: 6),
          Text('Your turn!', style: TextStyle(
              fontSize: 18, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
          const SizedBox(height: 44),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: color.withOpacity(0.12),
              border: Border.all(color: color.withOpacity(0.4)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.touch_app_rounded, color: color, size: 18),
              const SizedBox(width: 8),
              Text('Tap to reveal', style: TextStyle(
                  fontSize: 16, color: color, fontWeight: FontWeight.w600)),
            ]),
          ),
        ])),
      ),
    );
  }
}
