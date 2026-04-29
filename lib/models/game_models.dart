class GameItem {
  final String name;
  final int searchVolume;

  const GameItem({required this.name, required this.searchVolume});

  factory GameItem.fromJson(Map<String, dynamic> json) {
    return GameItem(
      name: json['name'] as String,
      searchVolume: json['searchVolume'] as int,
    );
  }

  String get formattedVolume {
    if (searchVolume >= 1000000) {
      final val = searchVolume / 1000000;
      return '${val % 1 == 0 ? val.toInt() : val.toStringAsFixed(1)}M';
    } else if (searchVolume >= 1000) {
      final val = searchVolume / 1000;
      return '${val % 1 == 0 ? val.toInt() : val.toStringAsFixed(1)}K';
    }
    return searchVolume.toString();
  }
}

class GamePair {
  final String id;
  final String category;
  final String subcategory;
  final String subgroup;
  final GameItem itemA;
  final GameItem itemB;

  const GamePair({
    required this.id,
    required this.category,
    required this.subcategory,
    required this.subgroup,
    required this.itemA,
    required this.itemB,
  });

  factory GamePair.fromJson(Map<String, dynamic> json) {
    return GamePair(
      id: json['id'] as String,
      category: json['category'] as String,
      subcategory: json['subcategory'] as String,
      subgroup: json['subgroup'] as String,
      itemA: GameItem.fromJson(json['itemA'] as Map<String, dynamic>),
      itemB: GameItem.fromJson(json['itemB'] as Map<String, dynamic>),
    );
  }
}

class Category {
  final String id;
  final String label;
  final String emoji;
  final List<SubCategory> subcategories;

  const Category({
    required this.id,
    required this.label,
    required this.emoji,
    required this.subcategories,
  });
}

class SubCategory {
  final String id;
  final String label;
  final String emoji;

  const SubCategory({
    required this.id,
    required this.label,
    required this.emoji,
  });
}
