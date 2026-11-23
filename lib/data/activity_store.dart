import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/dashboard_models.dart';

/// Where a user's activity (points, supported places, mission progress,
/// drafts) and the community stories are saved.
///
/// The app uses [FirestoreActivityStore]. Tests use [MemoryActivityStore]
/// so they run without Firebase.
abstract class ActivityStore {
  /// The user's saved activity, or an empty map for a new user.
  Future<Map<String, dynamic>> loadActivity(String uid);

  Future<void> saveActivity(String uid, Map<String, dynamic> data);

  /// Newest community stories first.
  Future<List<Story>> loadStories();

  /// Saves a new story and returns it with its real id.
  Future<Story> publishStory(Story story);
}

/// Firestore layout:
///   users/{uid}/private/activity   one document, only the owner can read it
///   stories/{storyId}              every signed-in user can read
class FirestoreActivityStore implements ActivityStore {
  FirestoreActivityStore({FirebaseFirestore? db}) : _dbOverride = db;

  final FirebaseFirestore? _dbOverride;
  FirebaseFirestore get _db => _dbOverride ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _activityDoc(String uid) =>
      _db.collection('users').doc(uid).collection('private').doc('activity');

  @override
  Future<Map<String, dynamic>> loadActivity(String uid) async {
    final snap = await _activityDoc(uid).get();
    return snap.data() ?? <String, dynamic>{};
  }

  @override
  Future<void> saveActivity(String uid, Map<String, dynamic> data) {
    return _activityDoc(uid).set(data);
  }

  @override
  Future<List<Story>> loadStories() async {
    final snap = await _db
        .collection('stories')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();
    return snap.docs.map((d) => storyFromMap(d.id, d.data())).toList();
  }

  @override
  Future<Story> publishStory(Story story) async {
    final ref = await _db.collection('stories').add({
      ...storyToMap(story),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return copyStoryWithId(story, ref.id);
  }
}

/// Keeps everything in memory. Used by widget tests.
class MemoryActivityStore implements ActivityStore {
  MemoryActivityStore({List<Story>? stories}) : _stories = [...?stories];

  final Map<String, Map<String, dynamic>> _activity = {};
  final List<Story> _stories;
  int _nextId = 1;

  @override
  Future<Map<String, dynamic>> loadActivity(String uid) async =>
      Map<String, dynamic>.from(_activity[uid] ?? const {});

  @override
  Future<void> saveActivity(String uid, Map<String, dynamic> data) async {
    _activity[uid] = Map<String, dynamic>.from(data);
  }

  @override
  Future<List<Story>> loadStories() async => List.of(_stories);

  @override
  Future<Story> publishStory(Story story) async {
    final saved = copyStoryWithId(story, 'mem${_nextId++}');
    _stories.insert(0, saved);
    return saved;
  }
}

Map<String, dynamic> storyToMap(Story s) => {
      'authorUid': s.authorUid,
      'authorName': s.authorName,
      'placeId': s.placeId,
      'placeName': s.placeName,
      'category': s.category.name,
      'text': s.excerpt,
      'whoTheyMet': s.whoTheyMet ?? '',
      'whatMakesItSpecial': s.whatMakesItSpecial ?? '',
      'distanceKm': s.distanceKm,
    };

Story storyFromMap(String id, Map<String, dynamic> m) {
  final created = m['createdAt'];
  final createdAt = created is Timestamp ? created.toDate() : DateTime.now();
  final categoryName = m['category'] as String? ?? '';
  final category = GemCategory.values.firstWhere(
    (c) => c.name == categoryName,
    orElse: () => GemCategory.smallBusiness,
  );
  return Story(
    id: id,
    placeId: m['placeId'] as String?,
    placeName: m['placeName'] as String? ?? 'A local spot',
    category: category,
    authorUid: m['authorUid'] as String?,
    authorName: m['authorName'] as String? ?? 'A local',
    excerpt: m['text'] as String? ?? '',
    whoTheyMet: m['whoTheyMet'] as String?,
    whatMakesItSpecial: m['whatMakesItSpecial'] as String?,
    distanceKm: (m['distanceKm'] as num?)?.toDouble() ?? 0,
    supportCount: 0,
    postedAgo: timeAgo(createdAt),
    createdAt: createdAt,
  );
}

Story copyStoryWithId(Story s, String id) => Story(
      id: id,
      placeId: s.placeId,
      placeName: s.placeName,
      category: s.category,
      authorUid: s.authorUid,
      authorName: s.authorName,
      excerpt: s.excerpt,
      whoTheyMet: s.whoTheyMet,
      whatMakesItSpecial: s.whatMakesItSpecial,
      distanceKm: s.distanceKm,
      supportCount: s.supportCount,
      postedAgo: s.postedAgo,
      createdAt: s.createdAt,
    );

/// "Just now", "5m ago", "3h ago", "Yesterday", "4d ago", or a date.
String timeAgo(DateTime time, {DateTime? now}) {
  final diff = (now ?? DateTime.now()).difference(time);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  if (diff.inDays == 1) return 'Yesterday';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${time.month}/${time.day}/${time.year}';
}
