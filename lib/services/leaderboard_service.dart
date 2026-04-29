import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../firebase_config.dart';

class LeaderboardEntry {
  final String id;
  final String name;
  final int score;
  final String category;
  final int timestamp;
  final String countryCode; // e.g. "GB", "US"
  final String weekKey;     // e.g. "2026-W18"

  const LeaderboardEntry({
    required this.id,
    required this.name,
    required this.score,
    required this.category,
    required this.timestamp,
    this.countryCode = '',
    this.weekKey = '',
  });

  factory LeaderboardEntry.fromJson(String id, Map<String, dynamic> json) {
    return LeaderboardEntry(
      id:          id,
      name:        (json['name']        as String? ?? 'Anonymous').trim(),
      score:       (json['score']       as num?)?.toInt() ?? 0,
      category:    json['category']     as String? ?? 'shuffle',
      timestamp:   (json['timestamp']   as num?)?.toInt() ?? 0,
      countryCode: json['countryCode']  as String? ?? '',
      weekKey:     json['weekKey']      as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'name':        name,
    'score':       score,
    'category':    category,
    'timestamp':   timestamp,
    'countryCode': countryCode,
    'weekKey':     weekKey,
  };

  /// Verified tier based on score.
  VerifiedTier get verifiedTier {
    if (score >= 50) return VerifiedTier.legendary;
    if (score >= 30) return VerifiedTier.gold;
    if (score >= 20) return VerifiedTier.verified;
    return VerifiedTier.none;
  }
}

enum VerifiedTier { none, verified, gold, legendary }

class LeaderboardService {
  static const String _node = 'leaderboard';
  static String get _url => '\$kFirebaseUrl/\$_node.json';

  /// Current ISO week key — "2026-W18"
  static String get currentWeekKey {
    final now  = DateTime.now().toUtc();
    // ISO week number: Jan 4 is always in week 1
    final jan4 = DateTime.utc(now.year, 1, 4);
    final week1Monday = jan4.subtract(Duration(days: jan4.weekday - 1));
    final diff = now.difference(week1Monday).inDays;
    final weekNum = (diff ~/ 7) + 1;
    return "${now.year}-W${weekNum.toString().padLeft(2, '0')}";
  }

  /// Auto-detect country code from browser language tag (e.g. en-GB → GB).
  static String detectCountryCode(BuildContext context) {
    try {
      // Try browser language first (most accurate on web)
      final lang = _browserLanguage();
      if (lang.contains('-')) {
        final code = lang.split('-').last.toUpperCase();
        if (code.length == 2) return code;
      }
      // Fall back to Flutter locale
      final locale = Localizations.localeOf(context);
      return locale.countryCode ?? '';
    } catch (_) {
      return '';
    }
  }

  static String _browserLanguage() {
    try {
      // ignore: avoid_web_libraries_in_flutter
      final result = _evalJs('navigator.language || navigator.userLanguage || ""');
      return result ?? '';
    } catch (_) {
      return '';
    }
  }

  static String? _evalJs(String expr) {
    try {
      // ignore: undefined_prefixed_name
      // We use a JS eval trick that's silent on non-web
      return null; // overridden per-platform
    } catch (_) { return null; }
  }

  // ── Fetch ─────────────────────────────────────────────────────────────────

  static Future<List<LeaderboardEntry>> fetchAll() async {
    if (!kLeaderboardEnabled) return _demoEntries();
    try {
      final res = await http.get(Uri.parse(_url))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200 || res.body == 'null' || res.body.isEmpty) return [];

      final raw = jsonDecode(res.body) as Map<String, dynamic>;
      return raw.entries
          .map((e) => LeaderboardEntry.fromJson(e.key, e.value as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Leaderboard fetch error: \$e');
      return [];
    }
  }

  /// Deduplicate by name keeping best score, then sort desc.
  static List<LeaderboardEntry> deduplicate(List<LeaderboardEntry> entries) {
    final best = <String, LeaderboardEntry>{};
    for (final e in entries) {
      final key = e.name.toLowerCase().trim();
      if (!best.containsKey(key) || e.score > best[key]!.score) {
        best[key] = e;
      }
    }
    final result = best.values.toList();
    result.sort((a, b) {
      final cmp = b.score.compareTo(a.score);
      return cmp != 0 ? cmp : a.timestamp.compareTo(b.timestamp);
    });
    return result;
  }

  /// All-time top — always fetches live from Firebase.
  static Future<List<LeaderboardEntry>> fetchAllTime({int limit = 200}) async {
    if (!kLeaderboardEnabled) return _demoEntries();
    final all = deduplicate(await fetchAll()).take(limit).toList();
    return all;
  }

  /// This week only — always fetches live from Firebase.
  static Future<List<LeaderboardEntry>> fetchThisWeek({int limit = 200}) async {
    if (!kLeaderboardEnabled) return _demoEntries()
        .where((e) => e.weekKey == currentWeekKey).take(limit).toList();
    final all  = await fetchAll();
    final week = currentWeekKey;
    return deduplicate(all.where((e) => e.weekKey == week).toList())
        .take(limit).toList();
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  static Future<({int rank, bool isNewBest})> submitScore({
    required String name,
    required int score,
    required String category,
    String countryCode = '',
  }) async {
    if (!kLeaderboardEnabled) return (rank: -1, isNewBest: false);
    try {
      final nameKey = name.toLowerCase().trim();

      // POST score directly — fast, no pre-check
      final body = jsonEncode({
        'name':        name.isEmpty ? 'Anonymous' : name,
        'score':       score,
        'category':    category,
        'timestamp':   DateTime.now().millisecondsSinceEpoch,
        'countryCode': countryCode,
        'weekKey':     currentWeekKey,
      });

      final res = await http.post(
        Uri.parse(_url),
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(const Duration(seconds: 12));

      debugPrint('[Leaderboard] POST status: \${res.statusCode}');
      if (res.statusCode != 200) {
        debugPrint('[Leaderboard] POST body: \${res.body}');
        return (rank: -1, isNewBest: false);
      }

      // Fetch fresh list to compute rank
      final fresh = deduplicate(await fetchAll());
      final idx   = fresh.indexWhere(
          (e) => e.name.toLowerCase().trim() == nameKey);
      final rank  = idx >= 0 ? idx + 1 : fresh.length;

      // Check if it was a new best (compare against all entries with same name)
      final sameNameEntries = fresh.where(
          (e) => e.name.toLowerCase().trim() == nameKey).toList();
      final wasNewBest = sameNameEntries.isEmpty ||
          sameNameEntries.every((e) => e.score <= score);

      return (rank: rank, isNewBest: wasNewBest);
    } catch (e) {
      debugPrint('[Leaderboard] Submit error: \$e');
      return (rank: -1, isNewBest: false);
    }
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  static Future<bool> deleteScore({required String name}) async {
    if (!kLeaderboardEnabled) return false;
    try {
      final res = await http.get(Uri.parse(_url))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200 || res.body == 'null') return false;

      final raw     = jsonDecode(res.body) as Map<String, dynamic>;
      final nameKey = name.toLowerCase().trim();
      final toDelete = raw.entries
          .where((e) {
            final v = e.value as Map<String, dynamic>;
            return (v['name'] as String? ?? '').toLowerCase().trim() == nameKey;
          })
          .map((e) => e.key)
          .toList();

      for (final id in toDelete) {
        await http.delete(
            Uri.parse('\$kFirebaseUrl/\$_node/\$id.json'))
            .timeout(const Duration(seconds: 8));
      }
      return toDelete.isNotEmpty;
    } catch (e) {
      debugPrint('Delete error: \$e');
      return false;
    }
  }

  // ── Demo entries ──────────────────────────────────────────────────────────

  static List<LeaderboardEntry> _demoEntries() {
    final data = [
      ('Alex',      34, 'GB', 'shuffle'),
      ('Sophia',    31, 'US', 'sports'),
      ('Marcus',    28, 'DE', 'gaming'),
      ('Isabella',  26, 'FR', 'culture'),
      ('Ethan',     25, 'AU', 'tech'),
      ('Olivia',    23, 'CA', 'celebrity'),
      ('Noah',      21, 'GB', 'geography'),
      ('Emma',      20, 'US', 'history'),
      ('Liam',      19, 'IE', 'food'),
      ('Ava',       18, 'NZ', 'science'),
      ('Mason',     17, 'ZA', 'politics'),
      ('Mia',       16, 'JP', 'automotive'),
      ('James',     15, 'BR', 'shuffle'),
      ('Charlotte', 14, 'MX', 'sports'),
      ('Elijah',    13, 'IN', 'gaming'),
      ('Amelia',    12, 'IT', 'culture'),
      ('Logan',     11, 'ES', 'tech'),
      ('Harper',    10, 'PT', 'celebrity'),
      ('Lucas',      9, 'SE', 'shuffle'),
      ('Evelyn',     8, 'NO', 'food'),
    ];
    final week = currentWeekKey;
    return List.generate(data.length, (i) {
      final (name, score, cc, cat) = data[i];
      return LeaderboardEntry(
        id: 'demo_\$i', name: name, score: score, category: cat,
        timestamp: DateTime.now().millisecondsSinceEpoch - i * 3600000,
        countryCode: cc,
        weekKey: i < 10 ? week : 'prev', // first 10 are "this week"
      );
    });
  }
}
