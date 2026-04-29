import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import '../models/game_models.dart';

class DatasetLoader {
  static List<GamePair>? _allPairs;

  static final List<Category> categories = [
    const Category(
      id: 'shuffle',
      label: 'Shuffle',
      emoji: '🔀',
      subcategories: [],
    ),
    const Category(
      id: 'sports',
      label: 'Sports',
      emoji: '🏅',
      subcategories: [
        SubCategory(id: 'formula1', label: 'Formula 1', emoji: '🏎️'),
        SubCategory(id: 'football', label: 'Football', emoji: '⚽'),
        SubCategory(id: 'basketball', label: 'Basketball', emoji: '🏀'),
        SubCategory(id: 'tennis', label: 'Tennis & Golf', emoji: '🎾'),
        SubCategory(id: 'combat', label: 'Boxing & MMA', emoji: '🥊'),
      ],
    ),
    const Category(
      id: 'celebrity',
      label: 'Celebrity',
      emoji: '⭐',
      subcategories: [],
    ),
    const Category(
      id: 'culture',
      label: 'TV & Music',
      emoji: '🎬',
      subcategories: [],
    ),
    const Category(
      id: 'tech',
      label: 'Tech',
      emoji: '💻',
      subcategories: [],
    ),
    const Category(
      id: 'gaming',
      label: 'Gaming',
      emoji: '🎮',
      subcategories: [],
    ),
    const Category(
      id: 'food',
      label: 'Food & Drink',
      emoji: '🍔',
      subcategories: [],
    ),
    const Category(
      id: 'geography',
      label: 'Geography',
      emoji: '🌍',
      subcategories: [],
    ),
    const Category(
      id: 'history',
      label: 'History',
      emoji: '🏛️',
      subcategories: [],
    ),
    const Category(
      id: 'politics',
      label: 'Politics',
      emoji: '🗳️',
      subcategories: [],
    ),
    const Category(
      id: 'science',
      label: 'Science',
      emoji: '🔬',
      subcategories: [],
    ),
    const Category(
      id: 'automotive',
      label: 'Automotive',
      emoji: '🚗',
      subcategories: [],
    ),
  ];

  static Future<void> load() async {
    if (_allPairs != null) return;
    final raw = await rootBundle.loadString('assets/data/dataset.json');
    final list = jsonDecode(raw) as List;
    _allPairs = list.map((e) => GamePair.fromJson(e as Map<String, dynamic>)).toList();
  }

  static List<GamePair> getPairs({
    required String categoryId,
    String? subcategoryId,
  }) {
    if (_allPairs == null) return [];

    List<GamePair> filtered;

    if (categoryId == 'shuffle') {
      filtered = List.from(_allPairs!);
    } else if (subcategoryId != null && subcategoryId.isNotEmpty) {
      // Map subcategory IDs to actual subcategory values in dataset
      final subMap = {
        'formula1': 'formula1',
        'football': 'football',
        'basketball': 'basketball',
        'tennis': 'tennis',
        'combat': 'boxing',
      };
      final mapped = subMap[subcategoryId] ?? subcategoryId;
      filtered = _allPairs!
          .where((p) => p.category == categoryId && p.subcategory.contains(mapped))
          .toList();
      if (filtered.isEmpty) {
        filtered = _allPairs!.where((p) => p.category == categoryId).toList();
      }
    } else {
      filtered = _allPairs!.where((p) => p.category == categoryId).toList();
    }

    // Remove trivially equal pairs
    filtered = filtered.where((p) => p.itemA.searchVolume != p.itemB.searchVolume).toList();

    // Shuffle
    filtered.shuffle(Random());
    return filtered;
  }

  static int totalPairs() => _allPairs?.length ?? 0;
}
