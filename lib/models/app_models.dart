import 'dashboard_models.dart';

/// A hidden gem shown in Explore. "Support" works like a favorite.
class Place {
  const Place({
    required this.id,
    required this.name,
    required this.category,
    required this.distanceKm,
    required this.storyCount,
    required this.blurb,
    required this.lat,
    required this.lng,
  });

  final String id;
  final String name;
  final GemCategory category;
  final double distanceKm;
  final int storyCount;
  final String blurb;
  final double lat;
  final double lng;
}
enum MissionPeriod { daily, weekly }

/// A daily or weekly mission that earns points (revision 2).
class Mission {
  const Mission({
    required this.id,
    required this.title,
    required this.detail,
    required this.points,
    required this.period,
    this.done = 0,
    this.goal = 1,
  });

  final String id;
  final String title;
  final String detail;
  final int points;
  final MissionPeriod period;
  final int done;
  final int goal;

  double get progress => goal == 0 ? 0 : (done / goal).clamp(0.0, 1.0);
  bool get isComplete => done >= goal;
}

/// Named MissionBadge because Flutter already has a Badge widget.
class MissionBadge {
  const MissionBadge({
    required this.name,
    required this.icon,
    this.unlocked = false,
    this.howTo = '',
  });

  final String name;
  final String icon; // key into badgeIcons in missions_screen.dart
  final bool unlocked;

  /// How to unlock it, shown when the badge is tapped.
  final String howTo;
}

enum CollectionKind { business, town, city }

extension CollectionKindLabel on CollectionKind {
  String get label {
    switch (this) {
      case CollectionKind.business:
        return 'Business';
      case CollectionKind.town:
        return 'Town';
      case CollectionKind.city:
        return 'City';
    }
  }
}

/// One photo in a Neighborhood Transformation timeline.
class TimelineEntry {
  const TimelineEntry({required this.year, required this.caption});

  final int year;
  final String caption;
}

/// Historical transformation of a business, town or city.
class TransformationCollection {
  const TransformationCollection({
    required this.id,
    required this.title,
    required this.kind,
    required this.timeline,
  });

  final String id;
  final String title;
  final CollectionKind kind;
  final List<TimelineEntry> timeline;

  int get fromYear => timeline.first.year;
  int get toYear => timeline.last.year;
}

/// A story the user started but did not post. Can be continued or discarded.
class StoryDraft {
  const StoryDraft({
    required this.id,
    required this.placeName,
    required this.text,
    required this.savedAgo,
    this.placeId,
    this.whoTheyMet = '',
    this.whatMakesItSpecial = '',
    this.savedAt,
  });

  final String id;
  final String placeName;
  final String text;
  final String savedAgo;
  final String? placeId;
  final String whoTheyMet;
  final String whatMakesItSpecial;
  final DateTime? savedAt;
}

/// Points earned from one action, shown in the "Mission completed" dialog.
class MissionReward {
  const MissionReward({required this.title, required this.points});

  final String title;
  final int points;
}