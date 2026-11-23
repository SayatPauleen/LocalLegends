import 'package:flutter/material.dart';

/// The three kinds of hidden gems shown in the mockup's filter chips.
enum GemCategory { streetFood, smallBusiness, cultural }

extension GemCategoryInfo on GemCategory {
  String get label {
    switch (this) {
      case GemCategory.streetFood:
        return 'Street food';
      case GemCategory.smallBusiness:
        return 'Small business';
      case GemCategory.cultural:
        return 'Cultural';
    }
  }

  IconData get icon {
    switch (this) {
      case GemCategory.streetFood:
        return Icons.ramen_dining_outlined;
      case GemCategory.smallBusiness:
        return Icons.storefront_outlined;
      case GemCategory.cultural:
        return Icons.account_balance_outlined;
    }
  }
}

/// A story-based review (F-03). No star rating on purpose.
class Story {
  const Story({
    required this.id,
    required this.placeName,
    required this.category,
    required this.authorName,
    required this.excerpt,
    required this.distanceKm,
    required this.supportCount,
    required this.postedAgo,
  });

  final String id;
  final String placeName;
  final GemCategory category;
  final String authorName;
  final String excerpt;
  final double distanceKm;
  final int supportCount;
  final String postedAgo;
}

/// A Mystery Mission clue (F-07).
class MissionClue {
  const MissionClue({required this.clue, required this.radiusKm});

  final String clue;
  final double radiusKm;
}

/// Everything the dashboard needs in one object, so the screen does not
/// care whether it came from sample data or Firestore.
class DashboardData {
  const DashboardData({
    required this.stories,
    required this.missionClues,
    required this.missionsCompletedThisWeek,
    required this.weeklyMissionGoal,
    required this.storiesShared,
    required this.placesSupported,
  });

  final List<Story> stories;
  final List<MissionClue> missionClues;
  final int missionsCompletedThisWeek;
  final int weeklyMissionGoal;
  final int storiesShared;
  final int placesSupported;
}
