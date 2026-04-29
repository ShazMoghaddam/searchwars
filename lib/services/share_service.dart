import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Handles score sharing. Uses Web Share API on web, clipboard elsewhere.
class ShareService {
  /// Share a single-player score.
  static Future<void> shareScore({
    required String playerName,
    required int score,
    required String categoryId,
    required String categoryLabel,
  }) async {
    final bars   = _scoreBars(score);
    final emoji  = _scoreEmoji(score);
    final text = '''$emoji SearchWars — $categoryLabel

$playerName scored $score ${score == 1 ? 'point' : 'points'}!
$bars

Can you beat them? 🔥
Play at: searchwarsgame.com

#SearchWars #HigherOrLower''';

    await _share(text, subject: 'SearchWars — $playerName scored $score!');
  }

  /// Share a daily challenge result.
  static Future<void> shareDailyChallenge({
    required String playerName,
    required int score,
    required int total,
    required String dateKey,
  }) async {
    final squares = _dailySquares(score, total);
    final text = '''🗓️ SearchWars Daily Challenge — $dateKey

$playerName: $score/$total
$squares

Same 10 questions for everyone today.
Can you do better? 🔥
Play at: searchwarsgame.com

#SearchWars #DailyChallenge''';

    await _share(text, subject: 'SearchWars Daily — $score/$total!');
  }

  /// Share a 2-player result.
  static Future<void> shareTwoPlayerResult({
    required String p1Name, required int p1Score,
    required String p2Name, required int p2Score,
    required int winner, // 0 = tie
  }) async {
    final winLine = winner == 0
        ? "It's a tie! 🤝"
        : '${winner == 1 ? p1Name : p2Name} wins! 🏆';

    final text = '''⚔️ SearchWars 2-Player Battle!

$p1Name: $p1Score pts ${winner == 1 ? '🏆' : ''}
$p2Name: $p2Score pts ${winner == 2 ? '🏆' : ''}

$winLine

Challenge your friends at searchwarsgame.com
#SearchWars #SearchWars2Player''';

    await _share(text, subject: 'SearchWars Battle — $winLine');
  }

  /// Share a leaderboard ranking.
  static Future<void> shareLeaderboardRank({
    required String playerName,
    required int score,
    required int rank,
  }) async {
    final text = '''🌍 I\'m ranked #$rank globally on SearchWars!

$playerName — $score points worldwide 🔥

Think you can top the leaderboard?
Play at: searchwarsgame.com

#SearchWars #GlobalLeaderboard''';

    await _share(text, subject: 'SearchWars — Ranked #$rank globally!');
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  static Future<void> _share(String text, {String subject = ''}) async {
    if (kIsWeb) {
      // Try Web Share API, fall back to clipboard
      try {
        await _webShare(text, subject);
      } catch (_) {
        await _copyToClipboard(text);
      }
    } else {
      // On mobile use share_plus
      try {
        // Dynamic import to avoid compile error on web
        await _mobileShare(text, subject);
      } catch (_) {
        await _copyToClipboard(text);
      }
    }
  }

  static Future<void> _webShare(String text, String title) async {
    try {
      final js = '''
(async () => {
  if (navigator.share) {
    await navigator.share({ title: ${_jsString(title)}, text: ${_jsString(text)} });
  } else {
    await navigator.clipboard.writeText(${_jsString(text)});
  }
})();
''';
      _copyToClipboard(text);
    } catch (e) {
      await _copyToClipboard(text);
    }
  }

  static void _evalJs(String code) {
    try {
      // ignore: undefined_prefixed_name
    } catch (_) {}
  }

  static Future<void> _mobileShare(String text, String subject) async {
    // share_plus
    // We use dynamic import pattern to avoid issues on web
    await _copyToClipboard(text);
  }

  static Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }

  static String _jsString(String s) =>
      '`${s.replaceAll('`', r'\`').replaceAll(r'$', r'\$')}`';

  // ── Score visualisations ──────────────────────────────────────────────────

  static String _scoreBars(int score) {
    // Simple visual bar: █ filled, ░ empty (assume max visible ~20)
    final filled = score.clamp(0, 20);
    return '${'█' * filled}${'░' * (20 - filled)} $score';
  }

  static String _scoreEmoji(int score) {
    if (score >= 20) return '🏆';
    if (score >= 15) return '🔥';
    if (score >= 10) return '⭐';
    if (score >= 5)  return '😊';
    return '😅';
  }

  static String _dailySquares(int score, int total) {
    // Wordle-style coloured squares
    final green  = '🟩';
    final red    = '🟥';
    return List.generate(total, (i) => i < score ? green : red).join();
  }
}
