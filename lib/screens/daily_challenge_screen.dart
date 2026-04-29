import 'dart:async';
import 'package:flutter/material.dart';
import '../services/daily_challenge_service.dart';
import '../services/sound_service.dart';
import '../theme.dart';
import 'daily_game_screen.dart';

class DailyChallengeScreen extends StatefulWidget {
  const DailyChallengeScreen({super.key});
  @override
  State<DailyChallengeScreen> createState() => _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends State<DailyChallengeScreen>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  bool _completed = false;
  int? _todaysScore;
  int  _streak = 0;
  int  _bestScore = 0;
  String _countdown = '00:00:00';
  Timer? _timer;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.97, end: 1.03)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _load();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final completed   = await DailyChallengeService.hasCompletedToday();
    final score       = await DailyChallengeService.getTodaysScore();
    final streak      = await DailyChallengeService.getStreak();
    final best        = await DailyChallengeService.getBestScore();
    setState(() {
      _loading     = false;
      _completed   = completed;
      _todaysScore = score;
      _streak      = streak;
      _bestScore   = best;
    });
  }

  void _startCountdown() {
    _countdown = DailyChallengeService.countdownString;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() =>
          _countdown = DailyChallengeService.countdownString);
    });
  }

  void _startGame() {
    SoundService.playTap();
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => const DailyGameScreen(),
    )).then((_) => _load()); // refresh on return
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(children: [
          _buildHeader(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _completed ? _buildCompleted() : _buildReady(),
          ),
        ]),
      ),
    );
  }

  Widget _buildHeader() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
    child: Row(children: [
      GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          width: 38, height: 38,
          decoration: BoxDecoration(color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder)),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 15, color: AppColors.textPrimary),
        ),
      ),
      const SizedBox(width: 14),
      const Text('Daily Challenge',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
              color: AppColors.textPrimary, letterSpacing: -0.5)),
    ]),
  );

  // ── Not yet played ────────────────────────────────────────────────────────

  Widget _buildReady() {
    final today = DailyChallengeService.todayKey;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(children: [
        const Spacer(),

        // Pulsing calendar icon
        ScaleTransition(scale: _pulse, child: Container(
          width: 100, height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _gold.withOpacity(0.12),
            border: Border.all(color: _gold.withOpacity(0.5), width: 2),
            boxShadow: [BoxShadow(
              color: _gold.withOpacity(0.25), blurRadius: 24, offset: const Offset(0, 6))],
          ),
          child: Icon(Icons.calendar_today_rounded, color: _gold, size: 44),
        )),

        const SizedBox(height: 28),
        Text(today, style: TextStyle(
            fontSize: 13, color: AppColors.textSecondary,
            fontWeight: FontWeight.w500, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        const Text("Today's Challenge",
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800,
                color: AppColors.textPrimary, letterSpacing: -0.8)),
        const SizedBox(height: 10),
        Text(
          '${DailyChallengeService.questionsPerDay} questions · same for everyone · no second chances',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
        ),

        const SizedBox(height: 32),

        // Stats row
        Row(children: [
          Expanded(child: _InfoCard(
            icon: Icons.local_fire_department_rounded,
            label: 'Day Streak', value: '$_streak 🔥',
            color: const Color(0xFFFF6B35))),
          const SizedBox(width: 12),
          Expanded(child: _InfoCard(
            icon: Icons.emoji_events_rounded,
            label: 'Best Score', value: '$_bestScore / ${DailyChallengeService.questionsPerDay}',
            color: _gold)),
        ]),

        const SizedBox(height: 16),

        // Rules
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: AppColors.surface,
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(children: [
            _Rule(Icons.quiz_rounded,     'Answer ${DailyChallengeService.questionsPerDay} questions'),
            const SizedBox(height: 8),
            _Rule(Icons.people_rounded,   'Same questions for everyone today'),
            const SizedBox(height: 8),
            _Rule(Icons.lock_clock_rounded,'One attempt per day — make it count!'),
            const SizedBox(height: 8),
            _Rule(Icons.star_rounded,     'Score out of ${DailyChallengeService.questionsPerDay} — no lives system'),
          ]),
        ),

        const Spacer(),

        // Play button
        GestureDetector(
          onTap: _startGame,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [_gold, _gold.withOpacity(0.75)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              boxShadow: [BoxShadow(
                color: _gold.withOpacity(0.4), blurRadius: 24, offset: const Offset(0, 8))],
            ),
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.play_arrow_rounded, color: Colors.black87, size: 24),
              SizedBox(width: 8),
              Text("Let's Play!",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                      color: Colors.black87, letterSpacing: 0.3)),
            ]),
          ),
        ),
        const SizedBox(height: 32),
      ]),
    );
  }

  // ── Already played ────────────────────────────────────────────────────────

  Widget _buildCompleted() {
    final score = _todaysScore ?? 0;
    final pct   = score / DailyChallengeService.questionsPerDay;
    final (emoji, msg, color) = _resultInfo(score);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(children: [
        const Spacer(),

        ScaleTransition(scale: _pulse, child:
          Text(emoji, style: const TextStyle(fontSize: 80))),
        const SizedBox(height: 20),
        Text(msg, textAlign: TextAlign.center,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800,
                color: color, letterSpacing: -0.5, height: 1.2)),
        const SizedBox(height: 24),

        // Score donut-style display
        Container(
          width: double.infinity, padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: AppColors.surface,
            border: Border.all(color: color.withOpacity(0.35), width: 1.5),
          ),
          child: Column(children: [
            Text('$score / ${DailyChallengeService.questionsPerDay}',
                style: TextStyle(fontSize: 56, fontWeight: FontWeight.w800,
                    color: color, letterSpacing: -2)),
            Text("today's score",
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: pct,
                backgroundColor: AppColors.surfaceLight,
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              _MiniStat(label: 'Streak', value: '$_streak 🔥'),
              Container(width: 1, height: 32, color: AppColors.cardBorder),
              _MiniStat(label: 'Best Ever',
                  value: '$_bestScore / ${DailyChallengeService.questionsPerDay}'),
            ]),
          ]),
        ),

        const SizedBox(height: 24),

        // Countdown to next challenge
        Container(
          width: double.infinity, padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: AppColors.surface,
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.lock_clock_rounded,
                  color: AppColors.textSecondary, size: 16),
              const SizedBox(width: 6),
              Text('Next challenge in',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ]),
            const SizedBox(height: 8),
            Text(_countdown,
                style: TextStyle(
                  fontSize: 36, fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary, letterSpacing: 2,
                  fontFeatures: [const FontFeature.tabularFigures()],
                )),
          ]),
        ),

        const Spacer(),

        // Back button
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: AppColors.surface,
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.grid_view_rounded,
                  color: AppColors.textSecondary, size: 18),
              SizedBox(width: 8),
              Text('Back to Categories',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
            ]),
          ),
        ),
        const SizedBox(height: 32),
      ]),
    );
  }

  (String, String, Color) _resultInfo(int score) {
    if (score == 10) return ('🏆', 'Perfect score!\nGenius level!', AppColors.gold);
    if (score >= 8)  return ('🔥', 'Excellent!\nAlmost perfect!', const Color(0xFFFF6B35));
    if (score >= 6)  return ('😊', 'Well done!\nAbove average!', AppColors.correct);
    if (score >= 4)  return ('😅', 'Not bad!\nKeep practising!', const Color(0xFF29B6F6));
    return ('😩', 'Better luck\ntomorrow!', AppColors.wrong);
  }

  static const _gold = AppColors.gold;
}

// ─── Small widgets ─────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _InfoCard({required this.icon, required this.label,
      required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      color: AppColors.surface,
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(height: 8),
      Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
          color: color, letterSpacing: -0.3)),
      Text(label, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
    ]),
  );
}

class _Rule extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Rule(this.icon, this.text);
  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 16, color: AppColors.textSecondary),
    const SizedBox(width: 10),
    Text(text, style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
  ]);
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  const _MiniStat({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
        color: AppColors.textPrimary)),
    Text(label, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
  ]);
}
