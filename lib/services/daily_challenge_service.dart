import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_models.dart';
import '../data/dataset_loader.dart';

class DailyChallengeService {
  static const int questionsPerDay = 10;
  static const String _completedPrefix = 'daily_completed_';
  static const String _scorePrefix     = 'daily_score_';
  static const String _streakKey       = 'daily_streak';
  static const String _lastPlayedKey   = 'daily_last_played';

  // ── Date helpers ──────────────────────────────────────────────────────────

  /// Today's date string in UTC — "2026-04-27"
  static String get todayKey {
    final now = DateTime.now().toUtc();
    return '${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}';
  }

  /// Seconds until next UTC midnight
  static int get secondsUntilReset {
    final now = DateTime.now().toUtc();
    final tomorrow = DateTime.utc(now.year, now.month, now.day + 1);
    return tomorrow.difference(now).inSeconds;
  }

  static String get countdownString {
    final s = secondsUntilReset;
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    return '${h.toString().padLeft(2,'0')}:${m.toString().padLeft(2,'0')}:${sec.toString().padLeft(2,'0')}';
  }

  // ── Seeded question selection ─────────────────────────────────────────────

  /// Deterministic seed from date — same for all players on same day.
  static int _dateSeed(String dateKey) {
    // Convert "2026-04-27" → integer seed
    final parts = dateKey.split('-');
    final y = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    final d = int.parse(parts[2]);
    return y * 10000 + m * 100 + d;
  }

  /// Simple seeded LCG — Dart's Random isn't seeded deterministically across platforms.
  static List<int> _seededShuffle(int count, int seed) {
    // LCG parameters (same as Numerical Recipes)
    const a = 1664525;
    const c = 1013904223;
    const m = 4294967296; // 2^32

    var state = seed;
    int next() {
      state = (a * state + c) % m;
      return state;
    }

    // Fisher-Yates with LCG
    final indices = List.generate(count, (i) => i);
    for (var i = count - 1; i > 0; i--) {
      final j = next() % (i + 1);
      final tmp = indices[i];
      indices[i] = indices[j];
      indices[j] = tmp;
    }
    return indices;
  }

  /// Returns today's 10 questions — identical for everyone worldwide.
  static List<GamePair> getTodaysPairs() {
    final all = DatasetLoader.getPairs(categoryId: 'shuffle');
    if (all.isEmpty) return [];

    final seed    = _dateSeed(todayKey);
    final indices = _seededShuffle(all.length, seed);
    return indices
        .take(questionsPerDay)
        .map((i) => all[i])
        .toList();
  }

  // ── Completion & scoring ──────────────────────────────────────────────────

  static Future<bool> hasCompletedToday() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool('$_completedPrefix$todayKey') ?? false;
  }

  static Future<int?> getTodaysScore() async {
    final p = await SharedPreferences.getInstance();
    final completed = p.getBool('$_completedPrefix$todayKey') ?? false;
    if (!completed) return null;
    return p.getInt('$_scorePrefix$todayKey');
  }

  static Future<void> recordCompletion({required int score}) async {
    final p    = await SharedPreferences.getInstance();
    final key  = todayKey;
    await p.setBool('$_completedPrefix$key', true);
    await p.setInt('$_scorePrefix$key', score);

    // Update streak
    final lastPlayed = p.getString(_lastPlayedKey);
    final yesterday  = _yesterday();
    int streak = p.getInt(_streakKey) ?? 0;
    if (lastPlayed == yesterday) {
      streak++; // consecutive day
    } else if (lastPlayed == key) {
      // Already recorded today — don't change streak
    } else {
      streak = 1; // streak broken
    }
    await p.setInt(_streakKey, streak);
    await p.setString(_lastPlayedKey, key);
  }

  static Future<int> getStreak() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_streakKey) ?? 0;
  }

  static String _yesterday() {
    final now  = DateTime.now().toUtc();
    final yest = now.subtract(const Duration(days: 1));
    return '${yest.year}-${yest.month.toString().padLeft(2,'0')}-${yest.day.toString().padLeft(2,'0')}';
  }

  // ── Best score across all days ────────────────────────────────────────────

  static Future<int> getBestScore() async {
    final p    = await SharedPreferences.getInstance();
    final keys = p.getKeys().where((k) => k.startsWith(_scorePrefix));
    if (keys.isEmpty) return 0;
    return keys
        .map((k) => p.getInt(k) ?? 0)
        .reduce((a, b) => a > b ? a : b);
  }
}
