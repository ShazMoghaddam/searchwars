import 'dart:math';
import 'package:flutter/material.dart';
import '../models/game_models.dart';
import '../services/daily_challenge_service.dart';
import '../services/score_service.dart';
import '../services/sound_service.dart';
import '../widgets/share_button.dart';
import '../theme.dart';
import '../widgets/category_background.dart';

enum _Phase  { guessing, revealing, sliding }
enum _Result { none, correct, wrong }

class DailyGameScreen extends StatefulWidget {
  const DailyGameScreen({super.key});
  @override
  State<DailyGameScreen> createState() => _DailyGameScreenState();
}

class _DailyGameScreenState extends State<DailyGameScreen>
    with TickerProviderStateMixin {

  late List<GamePair> _pairs;
  int _index   = 0;
  int _correct = 0;

  late GameItem _topItem, _bottomItem;

  _Phase  _phase  = _Phase.guessing;
  _Result _result = _Result.none;

  late AnimationController _slideCtrl, _flashCtrl, _progressCtrl;
  late Animation<Offset> _slideAnim;
  late Animation<double> _flashAnim, _progressAnim;

  static const _gold = AppColors.gold;
  static const int _total = DailyChallengeService.questionsPerDay;

  @override
  void initState() {
    super.initState();
    _slideCtrl    = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 400));
    _flashCtrl    = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 500));
    _progressCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 600));

    _slideAnim    = Tween<Offset>(begin: Offset.zero, end: const Offset(0, -1))
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeInOut));
    _flashAnim    = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _flashCtrl, curve: Curves.easeOut));
    _progressAnim = Tween<double>(begin: 0, end: 0)
        .animate(_progressCtrl);

    _pairs = DailyChallengeService.getTodaysPairs();
    _setupPair();
    _animateProgress(0);
  }

  @override
  void dispose() {
    _slideCtrl.dispose(); _flashCtrl.dispose(); _progressCtrl.dispose();
    super.dispose();
  }

  void _animateProgress(double target) {
    _progressAnim = Tween<double>(
      begin: _progressAnim.value, end: target)
        .animate(CurvedAnimation(parent: _progressCtrl, curve: Curves.easeOut));
    _progressCtrl.forward(from: 0);
  }

  void _setupPair() {
    if (_index >= _pairs.length) { _finish(); return; }
    final p = _pairs[_index];
    if (Random().nextBool()) { _topItem = p.itemA; _bottomItem = p.itemB; }
    else                     { _topItem = p.itemB; _bottomItem = p.itemA; }
  }

  Future<void> _onGuess(bool guessHigher) async {
    if (_phase != _Phase.guessing) return;

    final correct = guessHigher ==
        (_bottomItem.searchVolume > _topItem.searchVolume);

    setState(() {
      _phase  = _Phase.revealing;
      _result = correct ? _Result.correct : _Result.wrong;
    });

    if (correct) { SoundService.playCorrect(); _correct++; }
    else         { SoundService.playWrong(); }
    _flashCtrl.forward(from: 0);

    await Future.delayed(const Duration(milliseconds: 1000));

    // Update progress bar
    _animateProgress((_index + 1) / _total);

    setState(() { _phase = _Phase.sliding; _result = _Result.none; });
    await _slideCtrl.forward(from: 0);
    _index++;
    _slideCtrl.reset();
    setState(() => _phase = _Phase.guessing);
    _setupPair();
  }

  Future<void> _finish() async {
    await DailyChallengeService.recordCompletion(score: _correct);
    await ScoreService.recordGame(correct: _correct, totalQuestions: _total, categoryId: 'shuffle');
    if (mounted) {
      final score = _correct;
      final total = _total;
      if (score == total) SoundService.playWin();
      else if (score >= total * 0.6) SoundService.playCorrect();
      else SoundService.playGameOver();

      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => _DailyResultScreen(score: score, total: total),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    const vsDivH = 50.0;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(children: [
          Column(children: [
            _buildTopBar(),
            Expanded(
              child: LayoutBuilder(builder: (_, constraints) {
                final cardH = (constraints.maxHeight - vsDivH) / 2;
                return Stack(children: [
                  Column(children: [
                    SizedBox(height: cardH,
                      child: SlideTransition(
                        position: _phase == _Phase.sliding
                            ? _slideAnim
                            : const AlwaysStoppedAnimation(Offset.zero),
                        child: _DailyCard(item: _topItem, isRevealed: true,
                            result: _Result.none),
                      )),
                    _vsDivider(),
                    SizedBox(height: cardH,
                      child: _DailyCard(item: _bottomItem,
                          isRevealed: _phase != _Phase.guessing,
                          result: _result)),
                  ]),
                  if (_result != _Result.none)
                    FadeTransition(
                      opacity: ReverseAnimation(_flashAnim),
                      child: Container(
                        color: (_result == _Result.correct
                                ? AppColors.correct : AppColors.wrong)
                            .withOpacity(0.12),
                      ),
                    ),
                ]);
              }),
            ),
            _buildButtons(),
          ]),
        ]),
      ),
    );
  }

  Widget _buildTopBar() => Padding(
    padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
    child: Column(children: [
      Row(children: [
        // Back
        GestureDetector(
          onTap: () => _showQuitDialog(),
          child: Container(width: 38, height: 38,
            decoration: BoxDecoration(color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder)),
            child: const Icon(Icons.close_rounded,
                size: 18, color: AppColors.textPrimary)),
        ),
        const SizedBox(width: 12),
        // Daily badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: _gold.withOpacity(0.12),
            border: Border.all(color: _gold.withOpacity(0.4)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.calendar_today_rounded, color: _gold, size: 13),
            const SizedBox(width: 5),
            Text('Daily Challenge',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                    color: _gold)),
          ]),
        ),
        const Spacer(),
        // Question counter
        Container(
          width: 72,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: _gold.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _gold.withOpacity(0.3)),
          ),
          child: Text('${_index + 1} / $_total',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                  color: _gold)),
        ),
      ]),
      const SizedBox(height: 10),
      // Progress bar
      AnimatedBuilder(
        animation: _progressCtrl,
        builder: (_, __) => ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: _progressAnim.value,
            backgroundColor: AppColors.surfaceLight,
            valueColor: const AlwaysStoppedAnimation(_gold),
            minHeight: 6,
          ),
        ),
      ),
    ]),
  );

  Widget _vsDivider() => SizedBox(
    height: 50,
    child: Stack(alignment: Alignment.center, children: [
      Container(height: 1, color: AppColors.surfaceLight),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _gold.withOpacity(0.45), width: 1.5),
        ),
        child: Text('VS', style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w700,
            color: _gold, letterSpacing: 2)),
      ),
    ]),
  );

  Widget _buildButtons() => Padding(
    padding: const EdgeInsets.fromLTRB(14, 8, 14, 22),
    child: Row(children: [
      Expanded(child: _DailyBtn(
        label: 'HIGHER', icon: Icons.keyboard_arrow_up_rounded,
        color: AppColors.correct,
        enabled: _phase == _Phase.guessing,
        onTap: () => _onGuess(true),
      )),
      const SizedBox(width: 10),
      Expanded(child: _DailyBtn(
        label: 'LOWER', icon: Icons.keyboard_arrow_down_rounded,
        color: AppColors.wrong,
        enabled: _phase == _Phase.guessing,
        onTap: () => _onGuess(false),
      )),
    ]),
  );

  void _showQuitDialog() {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Quit Daily Challenge?',
          style: TextStyle(color: AppColors.textPrimary,
              fontSize: 18, fontWeight: FontWeight.w700)),
      content: Text(
        'Your progress will be lost. You only get one attempt per day!',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(_), child: const Text('Keep Playing')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.wrong,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          onPressed: () { Navigator.pop(_); Navigator.pop(context); },
          child: const Text('Quit', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    ));
  }
}

// ─── Daily Result Screen ──────────────────────────────────────────────────────

class _DailyResultScreen extends StatefulWidget {
  final int score, total;
  const _DailyResultScreen({required this.score, required this.total});
  @override
  State<_DailyResultScreen> createState() => _DailyResultScreenState();
}

class _DailyResultScreenState extends State<_DailyResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale, _fade;
  int _streak = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 700));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
    DailyChallengeService.getStreak().then((s) =>
        setState(() => _streak = s));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  (String, String, Color) get _info {
    final s = widget.score;
    final t = widget.total;
    if (s == t)      return ('🏆', 'Perfect!\nGenius level!',    AppColors.gold);
    if (s >= t * .8) return ('🔥', 'Excellent!\nAlmost there!',  const Color(0xFFFF6B35));
    if (s >= t * .6) return ('😊', 'Well done!\nAbove average!', AppColors.correct);
    if (s >= t * .4) return ('😅', 'Not bad!\nKeep going!',      const Color(0xFF29B6F6));
    return ('😩', 'Better luck\ntomorrow!', AppColors.wrong);
  }

  @override
  Widget build(BuildContext context) {
    final (emoji, msg, color) = _info;
    final pct = widget.score / widget.total;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(children: [
            const Spacer(),
            ScaleTransition(scale: _scale,
              child: FadeTransition(opacity: _fade,
                child: Column(children: [
                  Text(emoji, style: const TextStyle(fontSize: 80)),
                  const SizedBox(height: 16),
                  Text(msg, textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800,
                          color: color, letterSpacing: -0.5, height: 1.2)),
                  const SizedBox(height: 28),

                  // Score card
                  Container(
                    width: double.infinity, padding: const EdgeInsets.all(26),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      color: AppColors.surface,
                      border: Border.all(color: color.withOpacity(0.35), width: 1.5),
                    ),
                    child: Column(children: [
                      Text('${widget.score} / ${widget.total}',
                          style: TextStyle(fontSize: 60, fontWeight: FontWeight.w800,
                              color: color, letterSpacing: -2)),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: pct, minHeight: 8,
                          backgroundColor: AppColors.surfaceLight,
                          valueColor: AlwaysStoppedAnimation(color),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.local_fire_department_rounded,
                            color: const Color(0xFFFF6B35), size: 18),
                        const SizedBox(width: 6),
                        Text('$_streak day streak!',
                            style: const TextStyle(fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary)),
                      ]),
                    ]),
                  ),
                ]),
              ),
            ),
            const Spacer(),
            DailyShareButton(
              playerName: 'Player',
              score:      widget.score,
              total:      widget.total,
              dateKey:    DateTime.now().toUtc().toString().substring(0,10),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => Navigator.of(context)
                  .popUntil((r) => r.isFirst),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                  Icon(Icons.home_rounded,
                      color: AppColors.textSecondary, size: 18),
                  SizedBox(width: 8),
                  Text('Back to Home',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                ]),
              ),
            ),
            const SizedBox(height: 32),
          ]),
        ),
      ),
    );
  }
}

// ─── Daily Card ───────────────────────────────────────────────────────────────

class _DailyCard extends StatelessWidget {
  final GameItem item;
  final bool isRevealed;
  final _Result result;
  const _DailyCard({required this.item, required this.isRevealed,
      required this.result});

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 280),
    margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      color: AppColors.surface,
      gradient: LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: result == _Result.correct
            ? [AppColors.correct.withOpacity(0.2), AppColors.surface]
            : result == _Result.wrong
                ? [AppColors.wrong.withOpacity(0.2), AppColors.surface]
                : [AppColors.surface, AppColors.surfaceLight.withOpacity(0.5)],
      ),
      border: Border.all(
        color: result == _Result.correct ? AppColors.correct.withOpacity(0.55)
             : result == _Result.wrong   ? AppColors.wrong.withOpacity(0.55)
             : AppColors.cardBorder,
        width: result != _Result.none ? 2 : 1.5,
      ),
    ),
    child: SizedBox.expand(
      child: Stack(alignment: Alignment.center, children: [
        const CategoryBackground(categoryId: 'shuffle'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(item.name, textAlign: TextAlign.center, maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary, height: 1.25,
                    letterSpacing: -0.3)),
            const SizedBox(height: 14),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              child: isRevealed ? _Revealed(item: item) : _Hidden(),
            ),
          ]),
        ),
        if (result != _Result.none)
          Positioned(top: 12, right: 12, child: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: result == _Result.correct ? AppColors.correct : AppColors.wrong,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(
                color: (result == _Result.correct ? AppColors.correct : AppColors.wrong)
                    .withOpacity(0.4),
                blurRadius: 10, offset: const Offset(0, 2))],
            ),
            child: Icon(
              result == _Result.correct ? Icons.check_rounded : Icons.close_rounded,
              color: Colors.white, size: 14),
          )),
      ]),
    ),
  );
}

class _Revealed extends StatelessWidget {
  final GameItem item;
  const _Revealed({required this.item});
  @override
  Widget build(BuildContext context) => Column(key: const ValueKey('r'), children: [
    Text(item.formattedVolume,
        style: TextStyle(fontSize: 42, fontWeight: FontWeight.w700,
            color: AppColors.gold, letterSpacing: -1)),
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
            shape: BoxShape.circle),
        ))),
  ]);
}

class _DailyBtn extends StatelessWidget {
  final String label; final IconData icon;
  final Color color; final bool enabled; final VoidCallback onTap;
  const _DailyBtn({required this.label, required this.icon,
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
          color: enabled ? color.withOpacity(0.55) : color.withOpacity(0.15),
          width: 1.5),
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
