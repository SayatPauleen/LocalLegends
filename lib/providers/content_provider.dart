import 'package:flutter/foundation.dart';

import '../data/activity_store.dart';
import '../data/sample_content_repository.dart';
import '../data/sample_dashboard_repository.dart';
import '../models/app_models.dart';
import '../models/dashboard_models.dart';

/// Shared state for every tab, so an action on one screen shows up on the
/// others right away:
///
/// - Support (favorite) a place  -> Home stats, Profile > Supported, mission d3
/// - Check in at a place         -> missions d1 and w1, badges
/// - Post a story                -> Home feed, Profile > Stories, mission d2
/// - Save a draft                -> Profile > Drafts (Continue opens the editor)
/// - Mystery Mission             -> Home card and Missions tab, +80 pts
/// - Points and level            -> Home points card, Missions, Profile
///
/// The user's activity is saved in Firestore (users/{uid}/private/activity)
/// and stories in the `stories` collection, through [ActivityStore].
/// Places, mission definitions, badges, collections and the mystery clues
/// are app content from the sample repositories.
class ContentProvider extends ChangeNotifier {
  ContentProvider({
    required ActivityStore store,
    SampleContentRepository repo = const SampleContentRepository(),
    DashboardData? seed,
    DateTime Function()? clock,
  })  : _store = store,
        _repo = repo,
        _seed = seed ?? SampleDashboardRepository().load(),
        _clock = clock ?? DateTime.now;

  static const mysteryPoints = 80;
  static const maxStoryLength = 1000;

  final ActivityStore _store;
  final SampleContentRepository _repo;
  final DashboardData _seed;
  final DateTime Function() _clock;

  String? _uid;
  String _authorName = 'Explorer';
  bool _loading = false;
  String? _syncError;

  // Saved per user.
  int _points = 0;
  final Set<String> _supported = {};
  final Map<String, String> _lastCheckIn = {}; // placeId -> day key
  final Map<GemCategory, int> _checkInsByCategory = {};
  String _dailyKey = '';
  String _weeklyKey = '';
  final Map<String, int> _dailyProgress = {};
  final Map<String, int> _weeklyProgress = {};
  int _clueIndex = 0;
  bool _mysteryAccepted = false;
  String _mysteryDoneDay = '';
  int _mysterySolved = 0;
  final List<StoryDraft> _drafts = [];

  // Shared with everyone.
  List<Story> _communityStories = [];

  // ---------------------------------------------------------------- session

  String? get uid => _uid;
  bool get isLoading => _loading;

  /// Set when saving or loading from Firestore failed.
  String? get syncError => _syncError;

  /// Called by the ProxyProvider in main.dart whenever AuthProvider changes.
  void attachUser(String? uid, String authorName) {
    _authorName = authorName;
    if (uid == _uid) return;
    _uid = uid;
    _resetUserState();
    if (uid == null) {
      Future.microtask(notifyListeners);
    } else {
      _loading = true;
      Future.microtask(() => _load(uid));
    }
  }

  /// Loads the user's activity and the community stories again.
  Future<void> refresh() async {
    final id = _uid;
    if (id != null) await _load(id);
  }

  Future<void> _load(String uid) async {
    _loading = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        _store.loadActivity(uid),
        _store.loadStories(),
      ]);
      if (uid != _uid) return; // logged out or switched user meanwhile
      _applyActivity(results[0] as Map<String, dynamic>);
      _communityStories = results[1] as List<Story>;
      _syncError = null;
    } catch (e) {
      debugPrint('Could not load activity: $e');
      if (uid == _uid) _syncError = 'Could not load your data. Pull down to try again.';
    } finally {
      if (uid == _uid) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  void _resetUserState() {
    _points = 0;
    _supported.clear();
    _lastCheckIn.clear();
    _checkInsByCategory.clear();
    _dailyKey = '';
    _weeklyKey = '';
    _dailyProgress.clear();
    _weeklyProgress.clear();
    _clueIndex = 0;
    _mysteryAccepted = false;
    _mysteryDoneDay = '';
    _mysterySolved = 0;
    _drafts.clear();
    _communityStories = [];
    _syncError = null;
    _loading = false;
  }

  // ------------------------------------------------------------- app content

  List<Place> get places => _repo.places();
  List<TransformationCollection> get collections => _repo.collections();
  List<MissionClue> get missionClues => _seed.missionClues;

  Place? placeById(String? id) {
    if (id == null) return null;
    for (final p in places) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Finds the place for a story (sample stories only have a name).
  Place? placeForStory(Story story) {
    final byId = placeById(story.placeId);
    if (byId != null) return byId;
    for (final p in places) {
      if (p.name == story.placeName) return p;
    }
    return null;
  }

  // ------------------------------------------------------------------ points

  int get points => _points;
  int get level => _points ~/ 100 + 1;
  int get pointsToNextLevel => 100 - _points % 100;
  double get levelProgress => (_points % 100) / 100;

  // ----------------------------------------------------------------- stories

  /// Home feed: real stories first (newest), then the sample stories.
  List<Story> get feedStories => [..._communityStories, ..._seed.stories];

  List<Story> get myStories =>
      _communityStories.where((s) => s.authorUid != null && s.authorUid == _uid).toList();

  int get storiesSharedCount => myStories.length;

  List<Story> storiesForPlace(Place place) => feedStories
      .where((s) => s.placeId == place.id || s.placeName == place.name)
      .toList();

  /// Posts a story and returns the points it earned (may be empty).
  Future<List<MissionReward>> publishStory({
    required Place place,
    required String text,
    String whoTheyMet = '',
    String whatMakesItSpecial = '',
    String? fromDraftId,
  }) async {
    final uid = _uid;
    if (uid == null) throw StateError('Log in first.');
    final body = text.trim();
    if (body.isEmpty || body.length > maxStoryLength) {
      throw ArgumentError('A story needs 1 to $maxStoryLength characters.');
    }
    final now = _clock();
    final draft = Story(
      id: '',
      placeId: place.id,
      placeName: place.name,
      category: place.category,
      authorUid: uid,
      authorName: _authorName,
      excerpt: body,
      whoTheyMet: whoTheyMet.trim(),
      whatMakesItSpecial: whatMakesItSpecial.trim(),
      distanceKm: place.distanceKm,
      supportCount: 0,
      postedAgo: 'Just now',
      createdAt: now,
    );
    final saved = await _store.publishStory(draft);
    _communityStories = [saved, ..._communityStories];
    if (fromDraftId != null) _drafts.removeWhere((d) => d.id == fromDraftId);
    final rewards = _progress('d2');
    await _save();
    return rewards;
  }

  // ------------------------------------------------------------------ drafts

  List<StoryDraft> get drafts {
    final now = _clock();
    return [
      for (final d in _drafts)
        StoryDraft(
          id: d.id,
          placeId: d.placeId,
          placeName: d.placeName,
          text: d.text,
          whoTheyMet: d.whoTheyMet,
          whatMakesItSpecial: d.whatMakesItSpecial,
          savedAt: d.savedAt,
          savedAgo: d.savedAt == null ? d.savedAgo : 'Saved ${timeAgo(d.savedAt!, now: now).toLowerCase()}',
        ),
    ];
  }

  /// Creates or updates a draft and returns its id.
  Future<String> saveDraft({
    String? draftId,
    required Place place,
    required String text,
    String whoTheyMet = '',
    String whatMakesItSpecial = '',
  }) async {
    final id = draftId ?? 'dr${_clock().microsecondsSinceEpoch}';
    final draft = StoryDraft(
      id: id,
      placeId: place.id,
      placeName: place.name,
      text: text.trim(),
      whoTheyMet: whoTheyMet.trim(),
      whatMakesItSpecial: whatMakesItSpecial.trim(),
      savedAgo: 'Saved just now',
      savedAt: _clock(),
    );
    final i = _drafts.indexWhere((d) => d.id == id);
    if (i >= 0) {
      _drafts[i] = draft;
    } else {
      _drafts.insert(0, draft);
    }
    await _save();
    return id;
  }

  Future<void> discardDraft(String draftId) async {
    _drafts.removeWhere((d) => d.id == draftId);
    await _save();
  }

  // ----------------------------------------------------------------- support

  bool isSupported(String placeId) => _supported.contains(placeId);
  int get supportedCount => _supported.length;
  List<Place> get supportedPlaces =>
      places.where((p) => _supported.contains(p.id)).toList();

  /// Toggles Support (favorite). Returns points earned when supporting.
  Future<List<MissionReward>> toggleSupport(String placeId) async {
    var rewards = const <MissionReward>[];
    if (!_supported.remove(placeId)) {
      _supported.add(placeId);
      rewards = _progress('d3');
    }
    await _save();
    return rewards;
  }

  // ---------------------------------------------------------------- check in

  bool checkedInToday(String placeId) => _lastCheckIn[placeId] == _dayKey(_clock());

  int checkInsFor(GemCategory category) => _checkInsByCategory[category] ?? 0;

  /// "I visited this place". Counts once per place per day.
  Future<List<MissionReward>> checkIn(Place place) async {
    if (checkedInToday(place.id)) return const [];
    _lastCheckIn[place.id] = _dayKey(_clock());
    _checkInsByCategory[place.category] = checkInsFor(place.category) + 1;
    final rewards = <MissionReward>[];
    if (place.category == GemCategory.streetFood) rewards.addAll(_progress('d1'));
    if (place.category == GemCategory.smallBusiness) rewards.addAll(_progress('w1'));
    await _save();
    return rewards;
  }

  // ---------------------------------------------------------------- missions

  /// Mission list with this user's progress for today / this week.
  List<Mission> get missions {
    _rollPeriods();
    return [
      for (final m in _repo.missions())
        Mission(
          id: m.id,
          title: m.title,
          detail: m.detail,
          points: m.points,
          period: m.period,
          goal: m.goal,
          done: (m.period == MissionPeriod.daily ? _dailyProgress : _weeklyProgress)[m.id] ?? 0,
        ),
    ];
  }

  int get weeklyMissionsDone =>
      missions.where((m) => m.period == MissionPeriod.weekly && m.isComplete).length;
  int get weeklyMissionGoal =>
      _repo.missions().where((m) => m.period == MissionPeriod.weekly).length;
  int get dailyMissionsDone =>
      missions.where((m) => m.period == MissionPeriod.daily && m.isComplete).length;

  /// Adds one step to a mission. Awards its points when it reaches the goal.
  List<MissionReward> _progress(String missionId) {
    _rollPeriods();
    Mission? def;
    for (final m in _repo.missions()) {
      if (m.id == missionId) def = m;
    }
    if (def == null) return const [];
    final map = def.period == MissionPeriod.daily ? _dailyProgress : _weeklyProgress;
    final before = map[missionId] ?? 0;
    if (before >= def.goal) return const [];
    map[missionId] = before + 1;
    if (before + 1 < def.goal) return const [];

    _points += def.points;
    final rewards = [MissionReward(title: def.title, points: def.points)];
    // Weekly w3: "Complete 5 daily missions".
    if (def.period == MissionPeriod.daily) rewards.addAll(_progress('w3'));
    return rewards;
  }

  /// Resets daily progress after midnight and weekly progress on Monday.
  void _rollPeriods() {
    final now = _clock();
    final day = _dayKey(now);
    if (_dailyKey != day) {
      _dailyKey = day;
      _dailyProgress.clear();
    }
    final week = _weekKey(now);
    if (_weeklyKey != week) {
      _weeklyKey = week;
      _weeklyProgress.clear();
    }
  }

  // ---------------------------------------------------------- mystery mission

  MissionClue? get currentClue =>
      missionClues.isEmpty ? null : missionClues[_clueIndex % missionClues.length];
  bool get mysteryAccepted => _mysteryAccepted;
  bool get mysteryDoneToday => _mysteryDoneDay == _dayKey(_clock());
  int get mysterySolved => _mysterySolved;

  Future<void> nextClue() async {
    if (_mysteryAccepted || missionClues.isEmpty) return;
    _clueIndex = (_clueIndex + 1) % missionClues.length;
    await _save();
  }

  Future<void> acceptMystery() async {
    if (mysteryDoneToday) return;
    _mysteryAccepted = true;
    await _save();
  }

  Future<void> giveUpMystery() async {
    _mysteryAccepted = false;
    await _save();
  }

  /// "I found it": checks in at the place and awards the mystery points.
  Future<List<MissionReward>> completeMystery(Place foundPlace) async {
    if (!_mysteryAccepted) return const [];
    final rewards = <MissionReward>[...await checkIn(foundPlace)];
    _mysteryAccepted = false;
    _mysteryDoneDay = _dayKey(_clock());
    _mysterySolved++;
    _points += mysteryPoints;
    rewards.insert(0, const MissionReward(title: 'Mystery Mission solved', points: mysteryPoints));
    if (missionClues.isNotEmpty) _clueIndex = (_clueIndex + 1) % missionClues.length;
    await _save();
    return rewards;
  }

  // ------------------------------------------------------------------ badges

  List<MissionBadge> get badges {
    final defs = _repo.badges();
    bool unlocked(String icon) {
      switch (icon) {
        case 'story':
          return storiesSharedCount >= 1;
        case 'food':
          return checkInsFor(GemCategory.streetFood) >= 1;
        case 'support':
          return supportedCount >= 3;
        case 'mystery':
          return _mysterySolved >= 1;
        case 'history':
          return checkInsFor(GemCategory.cultural) >= 3;
        case 'legend':
          return level >= 5;
      }
      return false;
    }

    const howTo = {
      'story': 'Post your first story.',
      'food': 'Check in at a street food spot.',
      'support': 'Support 3 places.',
      'mystery': 'Solve a Mystery Mission.',
      'history': 'Check in at 3 cultural spots.',
      'legend': 'Reach Level 5.',
    };
    return [
      for (final b in defs)
        MissionBadge(
          name: b.name,
          icon: b.icon,
          unlocked: unlocked(b.icon),
          howTo: howTo[b.icon] ?? '',
        ),
    ];
  }

  int get badgesUnlocked => badges.where((b) => b.unlocked).length;

  // ------------------------------------------------------------- persistence

  Map<String, dynamic> _toMap() => {
        'points': _points,
        'supported': _supported.toList(),
        'lastCheckIn': Map<String, String>.from(_lastCheckIn),
        'checkInsByCategory': {
          for (final e in _checkInsByCategory.entries) e.key.name: e.value,
        },
        'daily': {'key': _dailyKey, 'progress': Map<String, int>.from(_dailyProgress)},
        'weekly': {'key': _weeklyKey, 'progress': Map<String, int>.from(_weeklyProgress)},
        'mystery': {
          'clueIndex': _clueIndex,
          'accepted': _mysteryAccepted,
          'doneDay': _mysteryDoneDay,
          'solved': _mysterySolved,
        },
        'drafts': [
          for (final d in _drafts)
            {
              'id': d.id,
              'placeId': d.placeId,
              'placeName': d.placeName,
              'text': d.text,
              'whoTheyMet': d.whoTheyMet,
              'whatMakesItSpecial': d.whatMakesItSpecial,
              'savedAt': d.savedAt?.millisecondsSinceEpoch,
            },
        ],
      };

  void _applyActivity(Map<String, dynamic> m) {
    _resetActivityOnly();
    _points = (m['points'] as num?)?.toInt() ?? 0;
    _supported.addAll(List<String>.from(m['supported'] as List? ?? const []));
    _lastCheckIn.addAll(Map<String, String>.from(m['lastCheckIn'] as Map? ?? const {}));
    final byCat = Map<String, dynamic>.from(m['checkInsByCategory'] as Map? ?? const {});
    for (final c in GemCategory.values) {
      final n = (byCat[c.name] as num?)?.toInt();
      if (n != null) _checkInsByCategory[c] = n;
    }
    final daily = Map<String, dynamic>.from(m['daily'] as Map? ?? const {});
    _dailyKey = daily['key'] as String? ?? '';
    _dailyProgress.addAll(_intMap(daily['progress']));
    final weekly = Map<String, dynamic>.from(m['weekly'] as Map? ?? const {});
    _weeklyKey = weekly['key'] as String? ?? '';
    _weeklyProgress.addAll(_intMap(weekly['progress']));
    final mystery = Map<String, dynamic>.from(m['mystery'] as Map? ?? const {});
    _clueIndex = (mystery['clueIndex'] as num?)?.toInt() ?? 0;
    _mysteryAccepted = mystery['accepted'] as bool? ?? false;
    _mysteryDoneDay = mystery['doneDay'] as String? ?? '';
    _mysterySolved = (mystery['solved'] as num?)?.toInt() ?? 0;
    for (final raw in (m['drafts'] as List? ?? const [])) {
      final d = Map<String, dynamic>.from(raw as Map);
      final savedMs = (d['savedAt'] as num?)?.toInt();
      _drafts.add(StoryDraft(
        id: d['id'] as String? ?? 'dr${_drafts.length}',
        placeId: d['placeId'] as String?,
        placeName: d['placeName'] as String? ?? '',
        text: d['text'] as String? ?? '',
        whoTheyMet: d['whoTheyMet'] as String? ?? '',
        whatMakesItSpecial: d['whatMakesItSpecial'] as String? ?? '',
        savedAgo: 'Saved earlier',
        savedAt: savedMs == null ? null : DateTime.fromMillisecondsSinceEpoch(savedMs),
      ));
    }
    _rollPeriods();
  }

  void _resetActivityOnly() {
    final stories = _communityStories;
    _resetUserState();
    _communityStories = stories;
    _loading = true;
  }

  static Map<String, int> _intMap(Object? raw) {
    final m = Map<String, dynamic>.from(raw as Map? ?? const {});
    return {for (final e in m.entries) e.key: (e.value as num).toInt()};
  }

  /// Updates the screens first, then saves. If saving fails the change
  /// stays on screen and [syncError] explains it.
  Future<void> _save() async {
    notifyListeners();
    final uid = _uid;
    if (uid == null) return;
    try {
      await _store.saveActivity(uid, _toMap());
      if (_syncError != null) {
        _syncError = null;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Could not save activity: $e');
      _syncError = 'Could not save to the cloud. Check your connection.';
      notifyListeners();
    }
  }

  static String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// The Monday that starts this week.
  static String _weekKey(DateTime d) {
    final monday = DateTime(d.year, d.month, d.day).subtract(Duration(days: d.weekday - 1));
    return _dayKey(monday);
  }
}
