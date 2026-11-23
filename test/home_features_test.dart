import 'package:flutter_test/flutter_test.dart';
import 'package:local_legends/data/activity_store.dart';
import 'package:local_legends/models/app_models.dart';
import 'package:local_legends/models/dashboard_models.dart';
import 'package:local_legends/providers/content_provider.dart';
import 'package:local_legends/providers/tab_navigator.dart';

/// Checks that the Home features are connected: one action updates points,
/// missions, badges and the other tabs, and everything is saved.
void main() {
  late MemoryActivityStore store;
  late DateTime now;

  Future<ContentProvider> loggedIn({String uid = 'u1'}) async {
    final c = ContentProvider(store: store, clock: () => now);
    c.attachUser(uid, 'Pauleen');
    // Let the microtask load finish.
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    return c;
  }

  Place place(ContentProvider c, GemCategory category) =>
      c.places.firstWhere((p) => p.category == category);

  setUp(() {
    store = MemoryActivityStore();
    now = DateTime(2026, 11, 24, 10); // a Tuesday
  });

  test('a new user starts at 0 points, level 1, no badges', () async {
    final c = await loggedIn();
    expect(c.points, 0);
    expect(c.level, 1);
    expect(c.badgesUnlocked, 0);
    expect(c.isLoading, isFalse);
  });

  test('Support awards the daily mission once and counts in stats', () async {
    final c = await loggedIn();
    final first = await c.toggleSupport('p1');
    expect(first.single.points, 20);
    expect(c.supportedCount, 1);

    await c.toggleSupport('p1'); // un-support
    final again = await c.toggleSupport('p1');
    expect(again, isEmpty); // mission already done today
    expect(c.points, 20);
  });

  test('posting a story shows on Home and Profile and gives points', () async {
    final c = await loggedIn();
    final lomi = c.placeById('p1')!;
    final rewards = await c.publishStory(place: lomi, text: 'Best lomi in town.');

    expect(rewards.first.points, 30);
    expect(c.myStories, hasLength(1));
    expect(c.feedStories.first.excerpt, 'Best lomi in town.');
    expect(c.storiesForPlace(lomi).first.authorName, 'Pauleen');
    expect(c.badges.firstWhere((b) => b.icon == 'story').unlocked, isTrue);
  });

  test('empty stories are rejected', () async {
    final c = await loggedIn();
    await expectLater(
      c.publishStory(place: c.places.first, text: '   '),
      throwsArgumentError,
    );
  });

  test('check in counts once a day and completes street food mission', () async {
    final c = await loggedIn();
    final food = place(c, GemCategory.streetFood);
    final r1 = await c.checkIn(food);
    expect(r1.single.points, 50);
    expect(c.checkedInToday(food.id), isTrue);
    expect(await c.checkIn(food), isEmpty);
  });

  test('three daily missions also move weekly mission w3', () async {
    final c = await loggedIn();
    await c.toggleSupport('p1'); // d3
    await c.checkIn(place(c, GemCategory.streetFood)); // d1
    await c.publishStory(place: c.places.first, text: 'Hello'); // d2
    final w3 = c.missions.firstWhere((m) => m.id == 'w3');
    expect(w3.done, 3);
    expect(c.dailyMissionsDone, 3);
  });

  test('Mystery Mission: accept, find, +80 pts, done for today', () async {
    final c = await loggedIn();
    final clue = c.currentClue;
    await c.acceptMystery();
    expect(c.mysteryAccepted, isTrue);

    final rewards = await c.completeMystery(place(c, GemCategory.cultural));
    expect(rewards.first.points, ContentProvider.mysteryPoints);
    expect(c.points, ContentProvider.mysteryPoints);
    expect(c.mysteryDoneToday, isTrue);
    expect(c.currentClue, isNot(same(clue)));
    expect(c.badges.firstWhere((b) => b.icon == 'mystery').unlocked, isTrue);

    await c.acceptMystery(); // not again today
    expect(c.mysteryAccepted, isFalse);
  });

  test('daily progress resets the next day, points stay', () async {
    final c = await loggedIn();
    await c.toggleSupport('p1');
    expect(c.dailyMissionsDone, 1);

    now = now.add(const Duration(days: 1));
    expect(c.dailyMissionsDone, 0);
    expect(c.points, 20);
    expect(c.mysteryDoneToday, isFalse);
  });

  test('drafts: save, continue, post removes the draft', () async {
    final c = await loggedIn();
    final p = c.places.first;
    final id = await c.saveDraft(place: p, text: 'Half a story');
    expect(c.drafts.single.text, 'Half a story');

    await c.saveDraft(draftId: id, place: p, text: 'A longer story');
    expect(c.drafts.single.text, 'A longer story');

    await c.publishStory(place: p, text: 'A longer story', fromDraftId: id);
    expect(c.drafts, isEmpty);
  });

  test('everything is saved and loads again after logging back in', () async {
    final c = await loggedIn();
    await c.toggleSupport('p4');
    await c.saveDraft(place: c.places.first, text: 'Saved for later');
    await c.publishStory(place: c.places.first, text: 'Posted');

    final again = await loggedIn();
    expect(again.isSupported('p4'), isTrue);
    expect(again.points, c.points);
    expect(again.drafts.single.text, 'Saved for later');
    expect(again.myStories, hasLength(1));
  });

  test('logging out clears the screen data', () async {
    final c = await loggedIn();
    await c.toggleSupport('p1');
    c.attachUser(null, 'Explorer');
    expect(c.supportedCount, 0);
    expect(c.points, 0);
  });

  test('another user sees my story but not my points', () async {
    final me = await loggedIn();
    await me.publishStory(place: me.places.first, text: 'Shared with everyone');
    await me.toggleSupport('p2');

    final friend = await loggedIn(uid: 'u2');
    expect(friend.feedStories.first.excerpt, 'Shared with everyone');
    expect(friend.myStories, isEmpty);
    expect(friend.isSupported('p2'), isFalse);
  });

  test('TabNavigator hands the Home search to Explore once', () {
    final nav = TabNavigator();
    nav.openExplore(query: 'lomi', category: GemCategory.streetFood);
    expect(nav.index, HomeTabs.explore);
    final search = nav.takeExploreSearch();
    expect(search?.query, 'lomi');
    expect(search?.category, GemCategory.streetFood);
    expect(nav.takeExploreSearch(), isNull);
  });

  test('MissionReward totals', () {
    const rewards = [
      MissionReward(title: 'a', points: 20),
      MissionReward(title: 'b', points: 30),
    ];
    expect(rewards.fold<int>(0, (s, r) => s + r.points), 50);
  });
}
