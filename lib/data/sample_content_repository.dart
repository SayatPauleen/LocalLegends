import '../models/app_models.dart';
import '../models/dashboard_models.dart';

/// Made-up sample data for Explore, Missions, Collections and Profile,
/// like SampleDashboardRepository does for the dashboard. Replace each
/// getter with a Firestore query when that feature's collection exists.
class SampleContentRepository {
  const SampleContentRepository();

  List<Place> places() => const [
        Place(
          id: 'p1',
          name: 'Aling Rosa\'s Lomi House',
          category: GemCategory.streetFood,
          distanceKm: 0.6,
          storyCount: 12,
          blurb: 'Lomi since 1998. Ask for extra chicharon.',
        ),
        Place(
          id: 'p2',
          name: 'Mang Tonyo\'s Shoe Repair',
          category: GemCategory.smallBusiness,
          distanceKm: 0.9,
          storyCount: 5,
          blurb: 'Same corner, same tools, three decades.',
        ),
        Place(
          id: 'p3',
          name: 'Kapeng Barako Corner',
          category: GemCategory.smallBusiness,
          distanceKm: 1.2,
          storyCount: 8,
          blurb: 'Beans from the owner\'s family farm in Lipa.',
        ),
        Place(
          id: 'p4',
          name: 'Old Town Heritage Mural',
          category: GemCategory.cultural,
          distanceKm: 2.4,
          storyCount: 17,
          blurb: 'Each panel is a different decade of the barangay.',
        ),
        Place(
          id: 'p5',
          name: 'Kuya Ben\'s Fishball Cart',
          category: GemCategory.streetFood,
          distanceKm: 0.4,
          storyCount: 9,
          blurb: 'Three sauces. The spicy one is homemade.',
        ),
      ];

  List<Mission> missions() => const [
        Mission(
          id: 'd1',
          title: 'Try a street food vendor you’ve never visited',
          detail: 'Any vendor within 2 km',
          points: 50,
          period: MissionPeriod.daily,
        ),
        Mission(
          id: 'd2',
          title: 'Share one story about a local spot',
          detail: 'At least one photo',
          points: 30,
          period: MissionPeriod.daily,
        ),
        Mission(
          id: 'd3',
          title: 'Support one local business',
          detail: 'Tap Support on a place you love',
          points: 20,
          period: MissionPeriod.daily,
          done: 1,
        ),
        Mission(
          id: 'w1',
          title: 'Visit 3 independent businesses',
          detail: 'Check in at each place',
          points: 150,
          period: MissionPeriod.weekly,
          done: 1,
          goal: 3,
        ),
        Mission(
          id: 'w2',
          title: 'Add a photo to a Neighborhood Collection',
          detail: 'A then or now photo',
          points: 100,
          period: MissionPeriod.weekly,
        ),
        Mission(
          id: 'w3',
          title: 'Complete 5 daily missions',
          detail: 'Any 5 this week',
          points: 120,
          period: MissionPeriod.weekly,
          done: 2,
          goal: 5,
        ),
      ];

  List<MissionBadge> badges() => const [
        MissionBadge(name: 'First Story', icon: 'story', unlocked: true),
        MissionBadge(name: 'Street Food Scout', icon: 'food', unlocked: true),
        MissionBadge(name: 'Local Patron', icon: 'support', unlocked: true),
        MissionBadge(name: 'Mystery Solver', icon: 'mystery', unlocked: true),
        MissionBadge(name: 'Historian', icon: 'history'),
        MissionBadge(name: 'Legend', icon: 'legend'),
      ];

  /// Points already earned (sample). Level = every 100 points.
  int points() => 240;

  List<TransformationCollection> collections() => const [
        TransformationCollection(
          id: 'c1',
          title: 'Aling Rosa\'s Lomi House',
          kind: CollectionKind.business,
          timeline: [
            TimelineEntry(year: 1998, caption: 'One pot and a bench on the sidewalk.'),
            TimelineEntry(year: 2006, caption: 'First roof and four tables.'),
            TimelineEntry(year: 2015, caption: 'The family took over the building next door.'),
            TimelineEntry(year: 2026, caption: 'Still the same recipe, now with a second branch.'),
          ],
        ),
        TransformationCollection(
          id: 'c2',
          title: 'Alangilan town plaza',
          kind: CollectionKind.town,
          timeline: [
            TimelineEntry(year: 1965, caption: 'Open field used for fiestas.'),
            TimelineEntry(year: 1988, caption: 'Concrete stage and benches added.'),
            TimelineEntry(year: 2010, caption: 'Trees planted along the paths.'),
            TimelineEntry(year: 2026, caption: 'Night market every Friday.'),
          ],
        ),
        TransformationCollection(
          id: 'c3',
          title: 'Batangas City downtown',
          kind: CollectionKind.city,
          timeline: [
            TimelineEntry(year: 1975, caption: 'Jeepney terminal and wet market.'),
            TimelineEntry(year: 1995, caption: 'First malls open nearby.'),
            TimelineEntry(year: 2012, caption: 'Heritage houses restored.'),
            TimelineEntry(year: 2026, caption: 'Pedestrian-friendly streets on weekends.'),
          ],
        ),
      ];

  List<StoryDraft> drafts() => const [
        StoryDraft(
          id: 'dr1',
          placeName: 'Kuya Ben\'s Fishball Cart',
          text: 'He told me he started the cart to pay for his daughter’s nursing school...',
          savedAgo: 'Saved 2h ago',
        ),
        StoryDraft(
          id: 'dr2',
          placeName: 'Kapeng Barako Corner',
          text: 'The smell of the roasting beans reached the jeepney stop...',
          savedAgo: 'Saved yesterday',
        ),
      ];
}
