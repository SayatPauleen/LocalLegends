import '../models/dashboard_models.dart';

/// Made-up sample data so the dashboard runs before Firestore is set up.
/// Later, replace load() with Firestore queries (stories near the user via
/// GeoFlutterFire2, the user's mission progress and support history).
class SampleDashboardRepository {
  DashboardData load() {
    return const DashboardData(
      storiesShared: 4,
      placesSupported: 12,
      missionsCompletedThisWeek: 3,
      weeklyMissionGoal: 5,
      missionClues: [
        MissionClue(
          clue: 'Find the lomi stall where the owner remembers every regular\'s order.',
          radiusKm: 1.5,
        ),
        MissionClue(
          clue: 'Look for a tiny shop that has repaired shoes on the same corner for 30 years.',
          radiusKm: 2.0,
        ),
        MissionClue(
          clue: 'Visit a wall that tells the town\'s history in paint.',
          radiusKm: 3.0,
        ),
      ],
      stories: [
        Story(
          id: 's1',
          placeName: 'Aling Rosa\'s Lomi House',
          category: GemCategory.streetFood,
          authorName: 'Mika D.',
          excerpt:
              'Rainy afternoon, steaming bowl, and Aling Rosa telling me how she started with one pot in 1998. Ask for extra chicharon on top.',
          distanceKm: 0.6,
          supportCount: 38,
          postedAgo: '2h ago',
        ),
        Story(
          id: 's2',
          placeName: 'Kapeng Barako Corner',
          category: GemCategory.smallBusiness,
          authorName: 'Jhon R.',
          excerpt:
              'The beans come from the owner\'s family farm in Lipa. He roasted a batch while I waited and let me smell every stage.',
          distanceKm: 1.2,
          supportCount: 21,
          postedAgo: '5h ago',
        ),
        Story(
          id: 's3',
          placeName: 'Old Town Heritage Mural',
          category: GemCategory.cultural,
          authorName: 'Andrea P.',
          excerpt:
              'Local art students painted this over a whole summer. Each panel is a different decade of the barangay.',
          distanceKm: 2.4,
          supportCount: 54,
          postedAgo: 'Yesterday',
        ),
        Story(
          id: 's4',
          placeName: 'Mang Tonyo\'s Shoe Repair',
          category: GemCategory.smallBusiness,
          authorName: 'Carlo M.',
          excerpt:
              'Fixed my thesis-defense shoes in 20 minutes and refused to charge extra for the rush. Still uses his father\'s tools.',
          distanceKm: 0.9,
          supportCount: 17,
          postedAgo: '2d ago',
        ),
      ],
    );
  }
}
