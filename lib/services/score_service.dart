import 'package:shared_preferences/shared_preferences.dart';

class ScoreService {
  static const _hsPrefix       = 'hs_';
  static const _gamesKey       = 'total_games';
  static const _correctKey     = 'total_correct';
  static const _questionsKey   = 'total_questions';
  static const _bestAllKey     = 'best_all_time';
  // Per-category accuracy
  static const _catCorrectPfx  = 'cat_correct_';
  static const _catQuestionPfx = 'cat_questions_';
  // Play streak (any game, any category)
  static const _playStreakKey   = 'play_streak';
  static const _lastPlayDateKey = 'last_play_date';

  // ── High scores ───────────────────────────────────────────────────────────

  static Future<int> getHighScore(String categoryId) async {
    final p = await SharedPreferences.getInstance();
    return p.getInt('$_hsPrefix$categoryId') ?? 0;
  }

  static Future<bool> setHighScoreIfBeaten(String categoryId, int score) async {
    final current = await getHighScore(categoryId);
    if (score > current) {
      final p = await SharedPreferences.getInstance();
      await p.setInt('$_hsPrefix$categoryId', score);
      final allTime = p.getInt(_bestAllKey) ?? 0;
      if (score > allTime) await p.setInt(_bestAllKey, score);
      return true;
    }
    return false;
  }

  // ── Record game ───────────────────────────────────────────────────────────

  static Future<void> recordGame({
    required int correct,
    required int totalQuestions,
    String categoryId = 'shuffle',
  }) async {
    final p   = await SharedPreferences.getInstance();
    final now = _todayKey();

    // Global totals
    await p.setInt(_gamesKey,     (p.getInt(_gamesKey)     ?? 0) + 1);
    await p.setInt(_correctKey,   (p.getInt(_correctKey)   ?? 0) + correct);
    await p.setInt(_questionsKey, (p.getInt(_questionsKey) ?? 0) + totalQuestions);

    // Per-category accuracy
    final catCKey = '$_catCorrectPfx$categoryId';
    final catQKey = '$_catQuestionPfx$categoryId';
    await p.setInt(catCKey, (p.getInt(catCKey) ?? 0) + correct);
    await p.setInt(catQKey, (p.getInt(catQKey) ?? 0) + totalQuestions);

    // Play streak (any game counts)
    final last   = p.getString(_lastPlayDateKey);
    final yest   = _yesterdayKey();
    int streak   = p.getInt(_playStreakKey) ?? 0;
    if (last == yest)  { streak++; }
    else if (last != now) { streak = 1; }
    await p.setInt(_playStreakKey,   streak);
    await p.setString(_lastPlayDateKey, now);
  }

  // ── Stats ─────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getStats(List<String> categoryIds) async {
    final p = await SharedPreferences.getInstance();

    // High scores per category
    final highScores = <String, int>{};
    for (final id in categoryIds) {
      highScores[id] = p.getInt('$_hsPrefix$id') ?? 0;
    }

    // Per-category accuracy
    final catAccuracy = <String, Map<String, int>>{};
    for (final id in categoryIds) {
      catAccuracy[id] = {
        'correct':   p.getInt('$_catCorrectPfx$id')   ?? 0,
        'questions': p.getInt('$_catQuestionPfx$id')  ?? 0,
      };
    }

    final totalQ = p.getInt(_questionsKey) ?? 0;
    final totalC = p.getInt(_correctKey)   ?? 0;

    return {
      'totalGames':     p.getInt(_gamesKey)     ?? 0,
      'totalCorrect':   totalC,
      'totalQuestions': totalQ,
      'accuracy':       totalQ == 0 ? 0.0 : totalC / totalQ,
      'bestAllTime':    p.getInt(_bestAllKey)    ?? 0,
      'playStreak':     p.getInt(_playStreakKey) ?? 0,
      'highScores':     highScores,
      'catAccuracy':    catAccuracy,
    };
  }

  static Future<void> resetAll() async {
    final p = await SharedPreferences.getInstance();
    await p.clear();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String _todayKey() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2,'0')}-${n.day.toString().padLeft(2,'0')}';
  }

  static String _yesterdayKey() {
    final y = DateTime.now().subtract(const Duration(days: 1));
    return '${y.year}-${y.month.toString().padLeft(2,'0')}-${y.day.toString().padLeft(2,'0')}';
  }
}
