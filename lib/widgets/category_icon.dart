import 'package:flutter/material.dart';
import '../theme.dart';

class CategoryIcon extends StatelessWidget {
  final String categoryId;
  final double size;
  final bool showBackground;

  const CategoryIcon({
    super.key,
    required this.categoryId,
    this.size = 32,
    this.showBackground = false,
  });

  static const Map<String, IconData> _icons = {
    'shuffle':    Icons.shuffle_rounded,
    'sports':     Icons.emoji_events_rounded,
    'celebrity':  Icons.star_rounded,
    'culture':    Icons.movie_rounded,
    'tech':       Icons.devices_rounded,
    'gaming':     Icons.sports_esports_rounded,
    'food':       Icons.restaurant_rounded,
    'geography':  Icons.public_rounded,
    'history':    Icons.account_balance_rounded,
    'politics':   Icons.how_to_vote_rounded,
    'science':    Icons.biotech_rounded,
    'automotive': Icons.directions_car_rounded,
    // Sports sub
    'formula1':   Icons.speed_rounded,
    'football':   Icons.sports_soccer_rounded,
    'basketball': Icons.sports_basketball_rounded,
    'tennis':     Icons.sports_tennis_rounded,
    'combat':     Icons.sports_martial_arts_rounded,
  };

  static IconData iconFor(String id) =>
      _icons[id] ?? Icons.help_outline_rounded;

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.categoryColor(categoryId);
    final icon = Icon(iconFor(categoryId), color: color, size: size);

    if (!showBackground) return icon;

    return Container(
      width: size * 1.8,
      height: size * 1.8,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(size * 0.5),
      ),
      child: Center(child: icon),
    );
  }
}

/// Compact icon row used in stats screen
class SubCategoryIcon extends StatelessWidget {
  final String subcategoryId;
  final double size;

  const SubCategoryIcon({super.key, required this.subcategoryId, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return Icon(CategoryIcon.iconFor(subcategoryId), size: size,
        color: AppTheme.categoryColor(subcategoryId));
  }
}
