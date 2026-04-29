import 'package:flutter/material.dart';
import '../constants.dart';
import '../data/dataset_loader.dart';
import '../models/game_models.dart';
import '../services/score_service.dart';
import '../services/sound_service.dart';
import '../theme.dart';
import '../widgets/category_icon.dart';
import 'daily_challenge_screen.dart';
import '../services/daily_challenge_service.dart';
import 'player_setup_screen.dart';
import 'leaderboard_screen.dart';
import 'stats_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _DailyBanner(),
      Expanded(child: _buildGrid()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 24, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(kAppName,
                    style: const TextStyle(
                        fontSize: 32, fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary, letterSpacing: -1)),
                const SizedBox(height: 3),
                Text(kAppTagline,
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(
                  '${DatasetLoader.totalPairs()} questions · ${DatasetLoader.categories.length - 1} categories',
                  style: TextStyle(fontSize: 11,
                      color: AppColors.textSecondary.withOpacity(0.55)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Mute toggle
          _HeaderBtn(
            icon: SoundService.muted
                ? Icons.volume_off_rounded
                : Icons.volume_up_rounded,
            onTap: () async {
              await SoundService.toggleMute();
              setState(() {});
            },
            active: !SoundService.muted,
          ),
          const SizedBox(width: 6),
          // Leaderboard button — labelled like Stats
          GestureDetector(
            onTap: () {
              SoundService.playTap();
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const LeaderboardScreen()));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.leaderboard_rounded, size: 20, color: AppColors.gold),
                  const SizedBox(width: 6),
                  Text('Top',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                          color: AppColors.gold)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Stats button with label
          GestureDetector(
            onTap: () {
              SoundService.playTap();
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const StatsScreen()));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bar_chart_rounded,
                      size: 20, color: AppColors.textPrimary),
                  const SizedBox(width: 6),
                  const Text('Stats',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    final cats = DatasetLoader.categories;
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 28),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, mainAxisSpacing: 11, crossAxisSpacing: 11,
        childAspectRatio: 1.28,
      ),
      itemCount: cats.length,
      itemBuilder: (context, i) => _CategoryCard(category: cats[i]),
    );
  }
}

class _HeaderBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool active;
  final Color? color;

  const _HeaderBtn({required this.icon, required this.onTap,
      this.active = true, this.color});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Icon(icon, size: 20,
          color: color ?? (active ? AppColors.textPrimary : AppColors.textSecondary)),
    ),
  );
}

// ─── Category Card ────────────────────────────────────────────────────────────

class _CategoryCard extends StatefulWidget {
  final Category category;
  const _CategoryCard({required this.category});
  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  int _best = 0;

  @override
  void initState() {
    super.initState();
    ScoreService.getHighScore(widget.category.id)
        .then((v) { if (mounted) setState(() => _best = v); });
  }

  @override
  Widget build(BuildContext context) {
    final color    = AppTheme.categoryColor(widget.category.id);
    final category = widget.category;
    return GestureDetector(
      onTap: () {
        SoundService.playTap();
        _onTap(context);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: AppColors.surface,
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [AppColors.surface, color.withOpacity(0.12)],
          ),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          boxShadow: [BoxShadow(
            color: color.withOpacity(0.08), blurRadius: 12, offset: const Offset(0,4))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: CategoryIcon(categoryId: category.id, size: 20),
              ),
              const Spacer(),
              // Best score badge
              if (_best > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: color.withOpacity(0.12),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.emoji_events_rounded, color: AppColors.gold, size: 10),
                    const SizedBox(width: 3),
                    Text('$_best',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
                            color: color)),
                  ]),
                ),
            ]),
            const Spacer(),
            Text(category.label,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary, letterSpacing: -0.3)),
            if (category.subcategories.isNotEmpty)
              Text('${category.subcategories.length} sub-topics',
                  style: TextStyle(fontSize: 10, color: color,
                      fontWeight: FontWeight.w500))
            else if (_best == 0)
              Text('No score yet',
                  style: TextStyle(fontSize: 10,
                      color: AppColors.textSecondary.withOpacity(0.5)))
            else
              Text('Best: $_best',
                  style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          ]),
        ),
      ),
    );
  }

  void _onTap(BuildContext context) {
    final category = widget.category;
    if (category.subcategories.isNotEmpty) {
      _showSubSheet(context);
    } else {
      _showModeSheet(context, category.id, null);
    }
  }

  void _showSubSheet(BuildContext context) {
    final category = widget.category;
    final color = AppTheme.categoryColor(category.id);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => _SubSheet(
        category: category, color: color,
        onSelect: (subId) {
          Navigator.pop(context);
          _showModeSheet(context, category.id, subId);
        },
      ),
    );
  }

  void _showModeSheet(BuildContext context, String catId, String? subId) {
    // ignore category variable shadowing
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => _ModeSheet(categoryId: catId, subcategoryId: subId),
    );
  }
}

// ─── Sub Sheet ────────────────────────────────────────────────────────────────

class _SubSheet extends StatelessWidget {
  final Category category;
  final Color color;
  final void Function(String? subId) onSelect;

  const _SubSheet({required this.category, required this.color, required this.onSelect});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Handle(),
        const SizedBox(height: 20),
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: CategoryIcon(categoryId: category.id, size: 20),
          ),
          const SizedBox(width: 10),
          Text(category.label,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
        ]),
        const SizedBox(height: 16),
        _SheetRow(icon: Icons.apps_rounded, label: 'All ${category.label}',
            color: color, onTap: () => onSelect(null)),
        const SizedBox(height: 8),
        ...category.subcategories.map((sub) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _SheetRow(
            iconWidget: CategoryIcon(categoryId: sub.id, size: 18),
            label: sub.label, color: color,
            onTap: () => onSelect(sub.id)),
        )),
      ],
    ),
  );
}

// ─── Mode Sheet ───────────────────────────────────────────────────────────────

class _ModeSheet extends StatelessWidget {
  final String categoryId;
  final String? subcategoryId;

  const _ModeSheet({required this.categoryId, this.subcategoryId});

  void _go(BuildContext context, bool twoPlayer) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => PlayerSetupScreen(
        categoryId: categoryId,
        subcategoryId: subcategoryId,
        twoPlayerMode: twoPlayer,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Handle(),
        const SizedBox(height: 20),
        const Text('Choose Mode', style: TextStyle(
            fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        Text('Solo or pass the phone?',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(height: 16),
        _SheetRow(icon: Icons.person_rounded, label: '1 Player',
            sublabel: 'Classic solo — beat your high score',
            color: const Color(0xFF29B6F6),
            onTap: () => _go(context, false)),
        const SizedBox(height: 10),
        _SheetRow(icon: Icons.people_rounded, label: '2 Players',
            sublabel: 'Take turns — who knows the internet best?',
            color: const Color(0xFFFF6B6B),
            onTap: () => _go(context, true)),
      ],
    ),
  );
}

// ─── Shared ───────────────────────────────────────────────────────────────────

class _Handle extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(child: Container(
    width: 38, height: 4,
    decoration: BoxDecoration(
      color: AppColors.textSecondary.withOpacity(0.3),
      borderRadius: BorderRadius.circular(2),
    ),
  ));
}

class _SheetRow extends StatelessWidget {
  final IconData? icon;
  final Widget? iconWidget;
  final String label;
  final String? sublabel;
  final Color color;
  final VoidCallback onTap;

  const _SheetRow({
    this.icon, this.iconWidget,
    required this.label, this.sublabel,
    required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () { SoundService.playTap(); onTap(); },
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: color.withOpacity(0.08),
        border: Border.all(color: color.withOpacity(0.28)),
      ),
      child: Row(children: [
        iconWidget ?? Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 15,
                fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            if (sublabel != null) Text(sublabel!,
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        )),
        Icon(Icons.chevron_right_rounded, color: color, size: 20),
      ]),
    ),
  );
}

// ─── Daily Challenge Banner ───────────────────────────────────────────────────

class _DailyBanner extends StatefulWidget {
  @override
  State<_DailyBanner> createState() => _DailyBannerState();
}

class _DailyBannerState extends State<_DailyBanner> {
  bool _completed = false;
  int? _score;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final completed = await DailyChallengeService.hasCompletedToday();
    final score     = await DailyChallengeService.getTodaysScore();
    if (mounted) setState(() {
      _completed = completed; _score = score; _loaded = true;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load(); // refresh when navigating back
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const SizedBox(height: 8);

    const gold   = AppColors.gold;
    const total  = DailyChallengeService.questionsPerDay;

    return GestureDetector(
      onTap: () {
        SoundService.playTap();
        Navigator.push(context, MaterialPageRoute(
            builder: (_) => const DailyChallengeScreen()))
            .then((_) => _load());
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [gold.withOpacity(0.18), gold.withOpacity(0.06)],
          ),
          border: Border.all(color: gold.withOpacity(0.45), width: 1.5),
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: gold.withOpacity(0.15),
            ),
            child: Icon(
              _completed
                  ? Icons.check_circle_rounded
                  : Icons.calendar_today_rounded,
              color: gold, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Row(children: [
              const Text('Daily Challenge',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: gold.withOpacity(0.2),
                ),
                child: Text(_completed ? 'DONE' : 'NEW',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800,
                        color: gold, letterSpacing: 0.8)),
              ),
            ]),
            Text(
              _completed
                  ? 'Today: ${_score ?? 0}/$total correct · Come back tomorrow!'
                  : '10 questions · same for everyone · resets at midnight',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ])),
          Icon(Icons.chevron_right_rounded, color: gold.withOpacity(0.7), size: 22),
        ]),
      ),
    );
  }
}
