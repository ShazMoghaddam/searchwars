import 'package:flutter/material.dart';
import '../theme.dart';

/// Renders a faint, large category icon as a card background watermark.
class CategoryBackground extends StatelessWidget {
  final String categoryId;

  const CategoryBackground({super.key, required this.categoryId});

  static const Map<String, IconData> _icons = {
    'sports':     Icons.emoji_events_rounded,
    'shuffle':    Icons.shuffle_rounded,
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
    // sports subcats
    'formula1':   Icons.speed_rounded,
    'football':   Icons.sports_soccer_rounded,
    'basketball': Icons.sports_basketball_rounded,
    'tennis':     Icons.sports_tennis_rounded,
    'combat':     Icons.sports_martial_arts_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final icon  = _icons[categoryId] ?? Icons.search_rounded;
    final color = AppTheme.categoryColor(categoryId);

    return Positioned(
      right: -18,
      bottom: -18,
      child: Icon(icon, size: 120,
          color: color.withOpacity(0.07)),
    );
  }
}
