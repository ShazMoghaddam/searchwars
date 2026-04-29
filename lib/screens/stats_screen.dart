import 'package:flutter/material.dart';
import '../data/dataset_loader.dart';
import '../services/score_service.dart';
import '../theme.dart';
import '../widgets/category_icon.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});
  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _stats;
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    final catIds = DatasetLoader.categories
        .map((c) => c.id).toList(); // include shuffle
    final stats = await ScoreService.getStats(catIds);
    if (mounted) setState(() => _stats = stats);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(children: [
          _buildHeader(),
          TabBar(
            controller: _tabCtrl,
            labelColor: AppColors.textPrimary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: const Color(0xFF7C6FFF),
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            tabs: const [Tab(text: 'Overview'), Tab(text: 'By Category')],
          ),
          Expanded(
            child: _stats == null
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabCtrl,
                    children: [
                      _buildOverview(),
                      _buildCategoryTab(),
                    ],
                  ),
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
        child: Container(width: 38, height: 38,
          decoration: BoxDecoration(color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder)),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 15, color: AppColors.textPrimary)),
      ),
      const SizedBox(width: 14),
      const Text('Stats', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700,
          color: AppColors.textPrimary, letterSpacing: -0.5)),
      const Spacer(),
      GestureDetector(
        onTap: _confirmReset,
        child: Container(width: 38, height: 38,
          decoration: BoxDecoration(color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder)),
          child: const Icon(Icons.refresh_rounded,
              size: 18, color: AppColors.textSecondary)),
      ),
    ]),
  );

  // ── Overview tab ──────────────────────────────────────────────────────────

  Widget _buildOverview() {
    final s        = _stats!;
    final games    = s['totalGames']     as int;
    final correct  = s['totalCorrect']   as int;
    final totalQ   = s['totalQuestions'] as int;
    final accuracy = s['accuracy']       as double;
    final best     = s['bestAllTime']    as int;
    final streak   = s['playStreak']     as int;

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        // Hero stat — total questions
        _HeroStat(
          icon: Icons.quiz_rounded,
          label: 'Questions Answered',
          value: _formatNum(totalQ),
          sub: '$correct correct · ${(accuracy * 100).toStringAsFixed(0)}% accuracy',
          color: const Color(0xFF7C6FFF),
        ),
        const SizedBox(height: 12),

        // 2-col grid
        Row(children: [
          Expanded(child: _StatCard(label: 'Games Played',
              value: '$games',
              icon: Icons.sports_score_rounded,
              color: const Color(0xFF29B6F6))),
          const SizedBox(width: 10),
          Expanded(child: _StatCard(label: 'Best Score',
              value: '$best',
              icon: Icons.emoji_events_rounded,
              color: AppColors.gold)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _StatCard(label: 'Correct Answers',
              value: _formatNum(correct),
              icon: Icons.check_circle_rounded,
              color: AppColors.correct)),
          const SizedBox(width: 10),
          Expanded(child: _StatCard(label: 'Play Streak',
              value: '$streak ${streak > 0 ? "🔥" : ""}',
              icon: Icons.local_fire_department_rounded,
              color: const Color(0xFFFF6B35))),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _StatCard(label: 'Accuracy',
              value: '${(accuracy * 100).toStringAsFixed(0)}%',
              icon: Icons.percent_rounded,
              color: const Color(0xFF26A69A))),
          const SizedBox(width: 10),
          Expanded(child: _StatCard(label: 'Wrong Answers',
              value: _formatNum(totalQ - correct),
              icon: Icons.cancel_rounded,
              color: AppColors.wrong)),
        ]),

        const SizedBox(height: 24),

        // Overall accuracy bar
        _SectionTitle('Overall Accuracy'),
        const SizedBox(height: 10),
        _AccuracyBar(
          correct: correct, total: totalQ,
          color: const Color(0xFF7C6FFF),
        ),
      ],
    );
  }

  // ── Category tab ──────────────────────────────────────────────────────────

  Widget _buildCategoryTab() {
    final s          = _stats!;
    final hs         = s['highScores']  as Map<String, int>;
    final catAcc     = s['catAccuracy'] as Map<String, Map<String, int>>;
    final cats       = DatasetLoader.categories.toList();

    // Sort by questions answered desc
    cats.sort((a, b) {
      final qa = catAcc[a.id]?['questions'] ?? 0;
      final qb = catAcc[b.id]?['questions'] ?? 0;
      return qb.compareTo(qa);
    });

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
      children: [
        _SectionTitle('Best Scores & Accuracy by Category'),
        const SizedBox(height: 4),
        Text('Sorted by most played', style: TextStyle(
            fontSize: 11, color: AppColors.textSecondary.withOpacity(0.6))),
        const SizedBox(height: 14),
        ...cats.map((cat) {
          final color    = AppTheme.categoryColor(cat.id);
          final score    = hs[cat.id] ?? 0;
          final acc      = catAcc[cat.id] ?? {'correct': 0, 'questions': 0};
          final catC     = acc['correct']   ?? 0;
          final catQ     = acc['questions'] ?? 0;
          final pct      = catQ == 0 ? 0.0 : catC / catQ;
          final played   = catQ > 0;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: AppColors.surface,
              border: Border.all(
                color: played ? color.withOpacity(0.3) : AppColors.cardBorder),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                CategoryIcon(categoryId: cat.id, size: 20, showBackground: true),
                const SizedBox(width: 12),
                Expanded(child: Text(cat.label,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary))),
                // Best score
                if (score > 0) Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.emoji_events_rounded, color: AppColors.gold, size: 14),
                  const SizedBox(width: 3),
                  Text('$score', style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800, color: color)),
                ]) else Text('—', style: TextStyle(
                    fontSize: 16, color: AppColors.textSecondary)),
              ]),

              if (played) ...[
                const SizedBox(height: 10),
                // Accuracy bar
                Row(children: [
                  Expanded(child: _AnimatedBar(value: pct, color: color)),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 42,
                    child: Text('${(pct*100).toStringAsFixed(0)}%',
                        textAlign: TextAlign.right,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                            color: color)),
                  ),
                ]),
                const SizedBox(height: 4),
                Text('$catC correct of $catQ questions',
                    style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              ] else ...[
                const SizedBox(height: 6),
                Text('Not played yet',
                    style: TextStyle(fontSize: 11,
                        color: AppColors.textSecondary.withOpacity(0.5))),
              ],
            ]),
          );
        }),
      ],
    );
  }

  String _formatNum(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}k';
    return '$n';
  }

  void _confirmReset() {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Reset Stats',
          style: TextStyle(color: AppColors.textPrimary)),
      content: Text('This clears all scores and history.',
          style: TextStyle(color: AppColors.textSecondary)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(_),
            child: const Text('Cancel')),
        TextButton(
          onPressed: () async {
            await ScoreService.resetAll();
            Navigator.pop(_);
            _load();
          },
          child: const Text('Reset',
              style: TextStyle(color: AppColors.wrong)),
        ),
      ],
    ));
  }
}

// ─── Widgets ──────────────────────────────────────────────────────────────────

class _HeroStat extends StatelessWidget {
  final IconData icon;
  final String label, value, sub;
  final Color color;

  const _HeroStat({required this.icon, required this.label,
      required this.value, required this.sub, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      gradient: LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [color.withOpacity(0.22), color.withOpacity(0.06)],
      ),
      border: Border.all(color: color.withOpacity(0.35), width: 1.5),
    ),
    child: Row(children: [
      Container(
        width: 52, height: 52,
        decoration: BoxDecoration(shape: BoxShape.circle,
            color: color.withOpacity(0.15)),
        child: Icon(icon, color: color, size: 26),
      ),
      const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Text(value, style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800,
            color: color, letterSpacing: -1)),
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
            color: AppColors.textPrimary)),
        const SizedBox(height: 2),
        Text(sub, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ])),
    ]),
  );
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value,
      required this.icon, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: color.withOpacity(0.25)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(height: 8),
      Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800,
          color: color, letterSpacing: -0.5)),
      Text(label, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
    ]),
  );
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
          color: AppColors.textPrimary));
}

class _AccuracyBar extends StatelessWidget {
  final int correct, total;
  final Color color;
  const _AccuracyBar({required this.correct, required this.total,
      required this.color});
  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : correct / total;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: _AnimatedBar(value: pct, color: color, height: 14)),
        const SizedBox(width: 12),
        Text('${(pct*100).toStringAsFixed(0)}%',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                color: color)),
      ]),
      const SizedBox(height: 4),
      Text('$correct correct answers out of $total total',
          style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
    ]);
  }
}

/// Animated horizontal bar that fills on first build.
class _AnimatedBar extends StatefulWidget {
  final double value;
  final Color color;
  final double height;
  const _AnimatedBar({required this.value, required this.color,
      this.height = 8});
  @override
  State<_AnimatedBar> createState() => _AnimatedBarState();
}

class _AnimatedBarState extends State<_AnimatedBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 900));
    _anim = Tween<double>(begin: 0, end: widget.value)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _anim,
    builder: (_, __) => ClipRRect(
      borderRadius: BorderRadius.circular(widget.height),
      child: Stack(children: [
        Container(height: widget.height, color: AppColors.surfaceLight),
        FractionallySizedBox(
          widthFactor: _anim.value.clamp(0.0, 1.0),
          child: Container(
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.height),
              gradient: LinearGradient(
                colors: [widget.color, widget.color.withOpacity(0.7)]),
            ),
          ),
        ),
      ]),
    ),
  );
}
