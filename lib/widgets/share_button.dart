import 'package:flutter/material.dart';
import '../services/share_service.dart';
import '../theme.dart';

/// Animated share button that shows a brief "Copied!" confirmation.
class ShareButton extends StatefulWidget {
  final String playerName;
  final int score;
  final String categoryId;
  final String categoryLabel;

  const ShareButton({
    super.key,
    required this.playerName,
    required this.score,
    required this.categoryId,
    required this.categoryLabel,
  });

  @override
  State<ShareButton> createState() => _ShareButtonState();
}

class _ShareButtonState extends State<ShareButton>
    with SingleTickerProviderStateMixin {
  bool _copied = false;
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 200));
    _scale = Tween<double>(begin: 1.0, end: 0.92)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _onTap() async {
    await _ctrl.forward();
    await _ctrl.reverse();

    await ShareService.shareScore(
      playerName:    widget.playerName,
      score:         widget.score,
      categoryId:    widget.categoryId,
      categoryLabel: widget.categoryLabel,
    );

    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTap: _onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: _copied
                ? AppColors.correct.withOpacity(0.15)
                : AppColors.surfaceLight,
            border: Border.all(
              color: _copied
                  ? AppColors.correct.withOpacity(0.5)
                  : AppColors.cardBorder,
              width: 1.5,
            ),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                _copied ? Icons.check_rounded : Icons.share_rounded,
                key: ValueKey(_copied),
                color: _copied ? AppColors.correct : AppColors.textSecondary,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                _copied ? 'Copied to clipboard!' : 'Share Score',
                key: ValueKey(_copied),
                style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600,
                  color: _copied ? AppColors.correct : AppColors.textSecondary,
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Compact share icon button for leaderboard rows.
class ShareIconButton extends StatefulWidget {
  final String playerName;
  final int score;
  final int rank;

  const ShareIconButton({
    super.key,
    required this.playerName,
    required this.score,
    required this.rank,
  });

  @override
  State<ShareIconButton> createState() => _ShareIconButtonState();
}

class _ShareIconButtonState extends State<ShareIconButton> {
  bool _done = false;

  Future<void> _onTap() async {
    await ShareService.shareLeaderboardRank(
      playerName: widget.playerName,
      score:      widget.score,
      rank:       widget.rank,
    );
    setState(() => _done = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _done = false);
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: _onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _done
            ? AppColors.correct.withOpacity(0.15)
            : AppColors.surfaceLight,
      ),
      child: Icon(
        _done ? Icons.check_rounded : Icons.share_rounded,
        color: _done ? AppColors.correct : AppColors.textSecondary,
        size: 14,
      ),
    ),
  );
}

/// Daily challenge share button — Wordle-style output.
class DailyShareButton extends StatefulWidget {
  final String playerName;
  final int score;
  final int total;
  final String dateKey;

  const DailyShareButton({
    super.key,
    required this.playerName,
    required this.score,
    required this.total,
    required this.dateKey,
  });

  @override
  State<DailyShareButton> createState() => _DailyShareButtonState();
}

class _DailyShareButtonState extends State<DailyShareButton> {
  bool _copied = false;

  Future<void> _onTap() async {
    await ShareService.shareDailyChallenge(
      playerName: widget.playerName,
      score:      widget.score,
      total:      widget.total,
      dateKey:    widget.dateKey,
    );
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: _onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: _copied
            ? AppColors.correct.withOpacity(0.12)
            : const Color(0xFF7C6FFF).withOpacity(0.12),
        border: Border.all(
          color: _copied
              ? AppColors.correct.withOpacity(0.4)
              : const Color(0xFF7C6FFF).withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(
          _copied ? Icons.check_rounded : Icons.adaptive.share,
          color: _copied ? AppColors.correct : const Color(0xFF7C6FFF),
          size: 18,
        ),
        const SizedBox(width: 8),
        Text(
          _copied ? 'Copied!' : 'Share Result',
          style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w700,
            color: _copied ? AppColors.correct : const Color(0xFF7C6FFF),
          ),
        ),
      ]),
    ),
  );
}
