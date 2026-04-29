import 'package:flutter/material.dart';
import '../firebase_config.dart';
import '../services/leaderboard_service.dart';
import '../services/sound_service.dart';
import '../theme.dart';

class LeaderboardScreen extends StatefulWidget {
  final String? submitName;
  final int?    submitScore;
  final String? submitCategory;

  const LeaderboardScreen({
    super.key,
    this.submitName,
    this.submitScore,
    this.submitCategory,
  });

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with TickerProviderStateMixin {
  // Tab controller
  late TabController _tabCtrl;

  // Data
  List<LeaderboardEntry> _allTime  = [];
  List<LeaderboardEntry> _weekly   = [];
  bool _loading    = true;
  bool _submitting = false;
  bool _dialogShown = false;
  int  _myRank     = -1;
  String _filterCategory = 'all';

  // Animation
  late AnimationController _listCtrl;

  static const _categories = [
    ('all','All'), ('shuffle','Shuffle'), ('sports','Sports'),
    ('celebrity','Celebrity'), ('culture','TV & Music'), ('tech','Tech'),
    ('gaming','Gaming'), ('food','Food'), ('geography','Geography'),
    ('history','History'), ('politics','Politics'),
    ('science','Science'), ('automotive','Automotive'),
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl  = TabController(length: 2, vsync: this);
    _listCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 700))..forward();
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose(); _listCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final allTime = await LeaderboardService.fetchAllTime(limit: 200);
    final weekly  = await LeaderboardService.fetchThisWeek(limit: 200);
    if (mounted) setState(() { _allTime = allTime; _weekly = weekly; _loading = false; });

    if (widget.submitScore != null && widget.submitScore! > 0 && !_dialogShown) {
      _dialogShown = true;
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) _showSubmitDialog();
    }
  }

  List<LeaderboardEntry> get _currentList =>
      _tabCtrl.index == 0 ? _allTime : _weekly;

  List<LeaderboardEntry> get _filtered {
    if (_filterCategory == 'all') return _currentList;
    return _currentList.where((e) => e.category == _filterCategory).toList();
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  void _showSubmitDialog() {
    final ctrl = TextEditingController(text: widget.submitName ?? '');
    const country = '';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Column(children: [
          const Text('🏆', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 8),
          Text('Score: ${widget.submitScore}',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text('Add to global leaderboard?', textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary,
                  fontWeight: FontWeight.w400)),

        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          if (!kLeaderboardEnabled) _demoBanner(),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(children: [
              Padding(padding: const EdgeInsets.all(12),
                child: Icon(Icons.person_rounded,
                    color: AppColors.textSecondary, size: 20)),
              Expanded(child: TextField(
                controller: ctrl, autofocus: true,
                style: const TextStyle(color: AppColors.textPrimary,
                    fontSize: 16, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Your name',
                  hintStyle: TextStyle(
                      color: AppColors.textSecondary.withOpacity(0.5))),
              )),
            ]),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: Text('Skip', style: TextStyle(color: AppColors.textSecondary))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.categoryColor(widget.submitCategory ?? 'shuffle'),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _submitting ? null : () async {
              final name = ctrl.text.trim().isEmpty
                  ? (widget.submitName ?? 'Anonymous')
                  : ctrl.text.trim();
              Navigator.pop(ctx);
              await _submitScore(name, country);
            },
            child: const Text('Submit', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _submitScore(String name, String country) async {
    setState(() => _submitting = true);

    final result = await LeaderboardService.submitScore(
      name: name,
      score: widget.submitScore!,
      category: widget.submitCategory ?? 'shuffle',
      countryCode: country,
    );

    // Immediately add locally
    final local = LeaderboardEntry(
      id: 'local_new', name: name, score: widget.submitScore!,
      category: widget.submitCategory ?? 'shuffle',
      timestamp: DateTime.now().millisecondsSinceEpoch,
      countryCode: country,
      weekKey: LeaderboardService.currentWeekKey,
    );

    void merge(List<LeaderboardEntry> list) {
      list.removeWhere((e) => e.name.toLowerCase().trim() == name.toLowerCase().trim());
      list.add(local);
      list.sort((a, b) {
        final cmp = b.score.compareTo(a.score);
        return cmp != 0 ? cmp : a.timestamp.compareTo(b.timestamp);
      });
    }

    merge(_allTime);
    merge(_weekly);

    final myPos = _allTime.indexWhere((e) => e.id == 'local_new') + 1;
    setState(() { _submitting = false; _loading = false; _myRank = myPos; });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: result.isNewBest ? AppColors.correct : AppColors.gold,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(children: [
          Icon(result.isNewBest
              ? Icons.emoji_events_rounded
              : Icons.workspace_premium_rounded,
              color: Colors.white),
          const SizedBox(width: 8),
          Expanded(child: Text(
            result.isNewBest
                ? "New personal best! You are #$myPos globally!"
                : "You are ranked #$myPos - beat your best to climb higher!",
            style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
          )),
        ]),
      ));
    }

    // Background refresh
    Future.delayed(const Duration(milliseconds: 800), () async {
      final fresh = await LeaderboardService.fetchAllTime(limit: 200);
      final freshW = await LeaderboardService.fetchThisWeek(limit: 200);
      if (mounted) setState(() { _allTime = fresh; _weekly = freshW; });
    });
  }

  Future<void> _deleteEntry(LeaderboardEntry entry) async {
    final confirmed = await showDialog<bool>(context: context, builder: (_) =>
        AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Remove your score?',
              style: TextStyle(color: AppColors.textPrimary,
                  fontSize: 18, fontWeight: FontWeight.w700)),
          content: Text('This removes "${entry.name}" from the leaderboard.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(_, false),
                child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.wrong,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () => Navigator.pop(_, true),
              child: const Text('Remove', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ));
    if (confirmed != true) return;

    setState(() => _loading = true);
    final ok = await LeaderboardService.deleteScore(name: entry.name);
    if (ok) {
      _allTime.removeWhere((e) => e.name.toLowerCase() == entry.name.toLowerCase());
      _weekly.removeWhere((e) => e.name.toLowerCase() == entry.name.toLowerCase());
    }
    setState(() => _loading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: ok ? AppColors.wrong : AppColors.textSecondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(ok ? '${entry.name} removed from leaderboard'
            : 'Could not remove. Try again.',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ));
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: Column(children: [
        _buildHeader(),
        // All Time / This Week tabs
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: TabBar(
            controller: _tabCtrl,
            onTap: (_) => setState(() {}),
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            labelColor: AppColors.textPrimary,
            unselectedLabelColor: AppColors.textSecondary,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppColors.surfaceLight,
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            tabs: [
              Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.emoji_events_rounded, size: 14),
                const SizedBox(width: 6),
                const Text('All Time'),
              ])),
              Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.calendar_view_week_rounded, size: 14),
                const SizedBox(width: 6),
                const Text('This Week'),
              ])),
            ],
          ),
        ),
        _buildCategoryFilter(),
        if (!kLeaderboardEnabled) _demoBanner(),
        Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _filtered.isEmpty
                ? _buildEmpty()
                : _buildList(_filtered)),
      ])),
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
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Leaderboard', style: TextStyle(fontSize: 22,
            fontWeight: FontWeight.w700, color: AppColors.textPrimary,
            letterSpacing: -0.5)),
        Text(
          _tabCtrl.index == 1
              ? 'Week ${LeaderboardService.currentWeekKey}'
              : 'All time best scores',
          style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ])),
      GestureDetector(
        onTap: _load,
        child: Container(width: 38, height: 38,
          decoration: BoxDecoration(color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder)),
          child: const Icon(Icons.refresh_rounded,
              size: 18, color: AppColors.textSecondary)),
      ),
    ]),
  );

  Widget _buildCategoryFilter() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 6, 16, 2),
    child: Wrap(
      spacing: 6,
      runSpacing: 6,
      children: _categories.map((cat) {
        final (id, label) = cat;
        final selected = _filterCategory == id;
        final color = id == 'all' ? AppColors.gold : AppTheme.categoryColor(id);
        return GestureDetector(
          onTap: () { SoundService.playTap(); setState(() => _filterCategory = id); },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: selected ? color.withOpacity(0.2) : AppColors.surface,
              border: Border.all(
                color: selected ? color.withOpacity(0.6) : AppColors.cardBorder,
                width: selected ? 1.5 : 1),
            ),
            child: Text(label, style: TextStyle(fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? color : AppColors.textSecondary)),
          ),
        );
      }).toList(),
    ),
  );

  Widget _demoBanner() => Container(
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      color: AppColors.gold.withOpacity(0.08),
      border: Border.all(color: AppColors.gold.withOpacity(0.3)),
    ),
    child: Row(children: [
      Icon(Icons.star_rounded, color: AppColors.gold, size: 16),
      const SizedBox(width: 8),
      Expanded(child: Text(
        'Demo mode — add your Firebase URL in firebase_config.dart to go live!',
        style: TextStyle(fontSize: 11, color: AppColors.gold,
            fontWeight: FontWeight.w500))),
    ]),
  );

  Widget _buildEmpty() => Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(_tabCtrl.index == 1
        ? Icons.calendar_view_week_rounded
        : Icons.leaderboard_rounded,
        size: 56, color: AppColors.textSecondary.withOpacity(0.4)),
    const SizedBox(height: 16),
    Text(_tabCtrl.index == 1 ? 'No scores this week yet' : 'No scores yet',
        style: TextStyle(fontSize: 18, color: AppColors.textSecondary,
            fontWeight: FontWeight.w600)),
    const SizedBox(height: 6),
    Text('Play a game and be the first!',
        style: TextStyle(fontSize: 13,
            color: AppColors.textSecondary.withOpacity(0.6))),
  ]));

  Widget _buildList(List<LeaderboardEntry> entries) {
    final podium = entries.take(3).toList();
    final rest   = entries.skip(3).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        if (podium.isNotEmpty) _buildPodium(podium),
        const SizedBox(height: 16),
        ...List.generate(rest.length, (i) {
          final rank  = i + 4;
          final entry = rest[i];
          return FadeTransition(
            opacity: Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
              parent: _listCtrl,
              curve: Interval((i * 0.04).clamp(0.0, 0.8), 1.0,
                  curve: Curves.easeOut))),
            child: _LeaderboardRow(rank: rank, entry: entry,
                isMe: _myRank == rank, onDelete: () => _deleteEntry(entry)),
          );
        }),
      ],
    );
  }

  Widget _buildPodium(List<LeaderboardEntry> top) {
    final hasTwo   = top.length >= 2;
    final hasThree = top.length >= 3;
    return ScaleTransition(
      scale: CurvedAnimation(parent: _listCtrl, curve: Curves.elasticOut),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        if (hasTwo)
          Expanded(child: _PodiumCard(entry: top[1], rank: 2, height: 130,
              onDelete: () => _deleteEntry(top[1])))
        else const Expanded(child: SizedBox()),
        const SizedBox(width: 8),
        Expanded(flex: 1, child: _PodiumCard(entry: top[0], rank: 1, height: 165,
            onDelete: () => _deleteEntry(top[0]))),
        const SizedBox(width: 8),
        if (hasThree)
          Expanded(child: _PodiumCard(entry: top[2], rank: 3, height: 110,
              onDelete: () => _deleteEntry(top[2])))
        else const Expanded(child: SizedBox()),
      ]),
    );
  }
}

// ─── Verified badge ───────────────────────────────────────────────────────────

class _VerifiedBadge extends StatelessWidget {
  final VerifiedTier tier;
  const _VerifiedBadge({required this.tier});

  @override
  Widget build(BuildContext context) {
    if (tier == VerifiedTier.none) return const SizedBox.shrink();
    final (icon, color, label) = switch (tier) {
      VerifiedTier.legendary => (Icons.auto_awesome_rounded, const Color(0xFFE040FB), '50+'),
      VerifiedTier.gold      => (Icons.verified_rounded,     AppColors.gold,           '30+'),
      VerifiedTier.verified  => (Icons.check_circle_rounded, const Color(0xFF29B6F6),  '20+'),
      _                      => (Icons.check_circle_rounded, AppColors.correct,        ''),
    };
    return Tooltip(
      message: label.isEmpty ? 'Verified' : 'Score $label verified',
      child: Icon(icon, color: color, size: 14),
    );
  }
}

// ─── Podium Card ──────────────────────────────────────────────────────────────

class _PodiumCard extends StatelessWidget {
  final LeaderboardEntry entry;
  final int rank;
  final double height;
  final VoidCallback onDelete;

  const _PodiumCard({required this.entry, required this.rank,
      required this.height, required this.onDelete});

  static const _medals = ['🥇', '🥈', '🥉'];
  static const _colors = [AppColors.gold, Color(0xFFC0C0C0), Color(0xFFCD7F32)];

  @override
  Widget build(BuildContext context) {
    final medal = _medals[rank - 1];
    final color = _colors[rank - 1];

    return GestureDetector(
      onLongPress: onDelete,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [color.withOpacity(0.25), color.withOpacity(0.06)],
          ),
          border: Border.all(color: color.withOpacity(0.5), width: 1.5),
          boxShadow: [BoxShadow(color: color.withOpacity(0.2),
              blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(medal, style: const TextStyle(fontSize: 26)),
          const SizedBox(height: 4),
          _VerifiedBadge(tier: entry.verifiedTier),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(entry.name, textAlign: TextAlign.center,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: rank == 1 ? 13 : 11,
                    fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20), color: color.withOpacity(0.2)),
            child: Text('${entry.score}', style: TextStyle(
                fontSize: rank == 1 ? 20 : 15, fontWeight: FontWeight.w800,
                color: color, letterSpacing: -0.5)),
          ),
        ]),
      ),
    );
  }
}

// ─── Leaderboard Row ──────────────────────────────────────────────────────────

class _LeaderboardRow extends StatelessWidget {
  final int rank;
  final LeaderboardEntry entry;
  final bool isMe;
  final VoidCallback onDelete;

  const _LeaderboardRow({required this.rank, required this.entry,
      required this.isMe, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.categoryColor(entry.category);
    return GestureDetector(
      onLongPress: onDelete,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isMe ? AppColors.correct.withOpacity(0.08) : AppColors.surface,
          border: Border.all(
            color: isMe ? AppColors.correct.withOpacity(0.4) : AppColors.cardBorder,
            width: isMe ? 1.5 : 1),
        ),
        child: Row(children: [
          // Rank
          SizedBox(width: 32, child: Text('#$rank',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary))),

          // Avatar with flag overlay
          Container(width: 36, height: 36,
              decoration: BoxDecoration(shape: BoxShape.circle,
                  color: color.withOpacity(0.18),
                  border: Border.all(color: color.withOpacity(0.35))),
              child: Center(child: Text(
                entry.name.isNotEmpty ? entry.name[0].toUpperCase() : '?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                    color: color)))),
          const SizedBox(width: 10),

          // Name + category + verified
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Row(children: [
              Flexible(child: Text(entry.name, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary))),
              const SizedBox(width: 4),
              _VerifiedBadge(tier: entry.verifiedTier),
              if (isMe) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: AppColors.correct.withOpacity(0.2)),
                  child: const Text('You', style: TextStyle(
                      fontSize: 9, fontWeight: FontWeight.w800,
                      color: AppColors.correct))),
              ],
            ]),
            Row(children: [
              Text(_catLabel(entry.category),
                  style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              const SizedBox(width: 6),
              Text('Hold to remove',
                  style: TextStyle(fontSize: 9,
                      color: AppColors.textSecondary.withOpacity(0.35))),
            ]),
          ])),

          // Score
          Text('${entry.score}', style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.w800,
              color: color, letterSpacing: -0.5)),
        ]),
      ),
    );
  }

  String _catLabel(String id) => const {
    'shuffle':'Shuffle','sports':'Sports','celebrity':'Celebrity',
    'culture':'TV & Music','tech':'Tech','gaming':'Gaming',
    'food':'Food','geography':'Geography','history':'History',
    'politics':'Politics','science':'Science','automotive':'Automotive',
  }[id] ?? id;
}
