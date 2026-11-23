import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_models.dart';
import '../models/dashboard_models.dart';
import '../providers/content_provider.dart';
import '../providers/tab_navigator.dart';
import '../theme/app_theme.dart';
import '../widgets/place_picker.dart';
import '../widgets/reward_dialog.dart';
import '../widgets/story_card.dart';
import 'place_detail_screen.dart';
import 'story_detail_screen.dart';
import 'write_story_screen.dart';

// Older files import HomeTabs from here.
export '../providers/tab_navigator.dart' show HomeTabs;

/// The Home dashboard. Everything on it reads the shared ContentProvider,
/// so it stays in sync with Explore, Missions and Profile:
///
/// 1. Greeting and account menu (My profile, Log out)
/// 2. Points summary card (points, level, badges)       -> Missions tab
/// 3. Search (text + Enter)                              -> Explore, pre-filled
/// 4. Stats: stories shared, places supported, weekly missions
/// 5. Today's Mystery Mission: Accept, Different one, I found it, Give up
/// 6. Hidden gems near you (tap = place page)           -> See all = Explore
/// 7. Map preview                                        -> Explore
/// 8. Stories near you with category chips (tap = full story), Write a Story
///
/// It takes the name and sign-out as plain values instead of reading
/// AuthProvider, so it can be widget tested without Firebase.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.userName,
    required this.onSignOut,
  });

  final String userName;
  final VoidCallback onSignOut;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  GemCategory? _filter; // null means "All"
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  void _openTab(int tab) => context.read<TabNavigator>().open(tab);

  void _submitSearch(String text) {
    context.read<TabNavigator>().openExplore(query: text.trim(), category: _filter);
    _search.clear();
    FocusScope.of(context).unfocus();
  }

  Future<void> _toggleSupport(ContentProvider content, Place place) async {
    final rewards = await content.toggleSupport(place.id);
    if (mounted) await showRewards(context, rewards);
  }

  @override
  Widget build(BuildContext context) {
    final content = context.watch<ContentProvider>();
    final feed = content.feedStories;
    final stories = _filter == null ? feed : feed.where((s) => s.category == _filter).toList();
    final nearby = [...content.places]..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: content.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            _Header(
              greeting: _greeting,
              userName: widget.userName,
              onProfile: () => _openTab(HomeTabs.profile),
              onSignOut: widget.onSignOut,
            ),
            if (content.isLoading) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(minHeight: 3, color: AppColors.terracotta),
            ],
            if (content.syncError != null) ...[
              const SizedBox(height: 12),
              _ErrorBanner(text: content.syncError!, onRetry: content.refresh),
            ],
            const SizedBox(height: 16),
            _PointsCard(
              points: content.points,
              level: content.level,
              progress: content.levelProgress,
              toNext: content.pointsToNextLevel,
              badges: content.badgesUnlocked,
              totalBadges: content.badges.length,
              onTap: () => _openTab(HomeTabs.missions),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              onSubmitted: _submitSearch,
              decoration: InputDecoration(
                hintText: 'Search places, food, or tags',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  tooltip: 'Search in Explore',
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: () => _submitSearch(_search.text),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    icon: Icons.auto_stories_outlined,
                    value: '${content.storiesSharedCount}',
                    label: 'Stories shared',
                    onTap: () => _openTab(HomeTabs.profile),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatTile(
                    icon: Icons.volunteer_activism_outlined,
                    value: '${content.supportedCount}',
                    label: 'Places supported',
                    onTap: () => _openTab(HomeTabs.profile),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatTile(
                    icon: Icons.flag_outlined,
                    value: '${content.weeklyMissionsDone}/${content.weeklyMissionGoal}',
                    label: 'Missions this week',
                    onTap: () => _openTab(HomeTabs.missions),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (content.currentClue != null)
              _MissionCard(
                clue: content.currentClue!,
                accepted: content.mysteryAccepted,
                doneToday: content.mysteryDoneToday,
                dailyDone: content.dailyMissionsDone,
                dailyTotal: content.missions.where((m) => m.period == MissionPeriod.daily).length,
                onAccept: content.acceptMystery,
                onDifferent: content.nextClue,
                onFound: () => finishMysteryMission(context),
                onGiveUp: content.giveUpMystery,
                onSeeMissions: () => _openTab(HomeTabs.missions),
              ),
            const SizedBox(height: 24),
            _SectionTitle(
              title: 'Hidden gems near you',
              action: 'See all',
              onAction: () => _openTab(HomeTabs.explore),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 172,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: nearby.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) {
                  final p = nearby[i];
                  return _GemCard(
                    place: p,
                    supported: content.isSupported(p.id),
                    onTap: () => PlaceDetailScreen.open(context, p),
                    onSupport: () => _toggleSupport(content, p),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            _SectionTitle(
              title: 'Gems around you',
              action: 'Open map',
              onAction: () => _openTab(HomeTabs.explore),
            ),
            const SizedBox(height: 10),
            _MapPreview(
              label: '${nearby.where((p) => p.distanceKm <= 3).length} gems'
                  '${content.mysteryAccepted ? ' and 1 mission' : ''} nearby',
              onTap: () => _openTab(HomeTabs.explore),
            ),
            const SizedBox(height: 24),
            _SectionTitle(
              title: 'Stories near you',
              action: 'Write a Story',
              onAction: () => WriteStoryScreen.open(context),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _chip(null, 'All'),
                  for (final c in GemCategory.values) _chip(c, c.label),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (stories.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    const Text(
                      'No stories in this category yet. Be the first to share one.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted),
                    ),
                    TextButton(
                      onPressed: () => WriteStoryScreen.open(context),
                      child: const Text('Write a Story'),
                    ),
                  ],
                ),
              )
            else
              for (final story in stories)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: StoryCard(
                    story: story,
                    onTap: () => StoryDetailScreen.open(context, story),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _chip(GemCategory? category, String label) {
    final selected = _filter == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _filter = category),
        selectedColor: AppColors.terracotta,
        labelStyle: TextStyle(
          color: selected ? Colors.white : AppColors.ink,
          fontWeight: FontWeight.w600,
        ),
        showCheckmark: false,
        backgroundColor: Colors.white,
        side: BorderSide(color: selected ? AppColors.terracotta : AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.greeting,
    required this.userName,
    required this.onProfile,
    required this.onSignOut,
  });

  final String greeting;
  final String userName;
  final VoidCallback onProfile;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final initial = userName.isEmpty ? '?' : userName[0].toUpperCase();
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting, $userName',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Find a hidden gem near you today.',
                style: TextStyle(color: AppColors.muted),
              ),
            ],
          ),
        ),
        PopupMenuButton<String>(
          tooltip: 'Account',
          onSelected: (value) {
            if (value == 'profile') onProfile();
            if (value == 'logout') onSignOut();
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'profile', child: Text('My profile')),
            PopupMenuItem(value: 'logout', child: Text('Log out')),
          ],
          child: CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.teal,
            child: Text(
              initial,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.text, required this.onRetry});

  final String text;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_outlined, size: 18, color: Color(0xFFB3261E)),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: AppColors.ink))),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

/// Points summary at the top (revision 2).
class _PointsCard extends StatelessWidget {
  const _PointsCard({
    required this.points,
    required this.level,
    required this.progress,
    required this.toNext,
    required this.badges,
    required this.totalBadges,
    required this.onTap,
  });

  final int points;
  final int level;
  final double progress;
  final int toNext;
  final int badges;
  final int totalBadges;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.terracotta,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$points pts',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Level $level · $toNext pts to Level ${level + 1}',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      const Icon(Icons.military_tech_outlined, color: Colors.white, size: 30),
                      Text(
                        '$badges/$totalBadges badges',
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.white24,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String value;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: AppColors.terracotta),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 2,
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Today's Mystery Mission (F-07). Three states:
/// not accepted (Accept / Different one), accepted (I found it / Give up),
/// and solved today.
class _MissionCard extends StatelessWidget {
  const _MissionCard({
    required this.clue,
    required this.accepted,
    required this.doneToday,
    required this.dailyDone,
    required this.dailyTotal,
    required this.onAccept,
    required this.onDifferent,
    required this.onFound,
    required this.onGiveUp,
    required this.onSeeMissions,
  });

  final MissionClue clue;
  final bool accepted;
  final bool doneToday;
  final int dailyDone;
  final int dailyTotal;
  final VoidCallback onAccept;
  final VoidCallback onDifferent;
  final VoidCallback onFound;
  final VoidCallback onGiveUp;
  final VoidCallback onSeeMissions;

  @override
  Widget build(BuildContext context) {
    final progress = dailyTotal == 0 ? 0.0 : (dailyDone / dailyTotal).clamp(0.0, 1.0);
    final whiteFilled = FilledButton.styleFrom(
      minimumSize: const Size(0, 44),
      backgroundColor: Colors.white,
      foregroundColor: AppColors.teal,
    );
    final whiteOutlined = OutlinedButton.styleFrom(
      minimumSize: const Size(0, 44),
      foregroundColor: Colors.white,
      side: const BorderSide(color: Colors.white70),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );

    final String title;
    final String body;
    final List<Widget> buttons;
    if (doneToday) {
      title = 'Mystery solved today';
      body = 'Nice work, legend! A new mystery unlocks tomorrow.';
      buttons = [
        Expanded(
          child: FilledButton(
            onPressed: onSeeMissions,
            style: whiteFilled,
            child: const Text('See daily missions'),
          ),
        ),
      ];
    } else if (accepted) {
      title = 'Mission accepted';
      body = clue.clue;
      buttons = [
        Expanded(
          child: FilledButton(onPressed: onFound, style: whiteFilled, child: const Text('I found it')),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton(onPressed: onGiveUp, style: whiteOutlined, child: const Text('Give up')),
        ),
      ];
    } else {
      title = "Today's Mystery Mission";
      body = clue.clue;
      buttons = [
        Expanded(
          child: FilledButton(onPressed: onAccept, style: whiteFilled, child: const Text('Accept')),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton(
            onPressed: onDifferent,
            style: whiteOutlined,
            child: const Text('Different one'),
          ),
        ),
      ];
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.teal,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(doneToday ? Icons.emoji_events_outlined : Icons.explore_outlined,
                  color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                doneToday
                    ? '+${ContentProvider.mysteryPoints} pts earned'
                    : '+${ContentProvider.mysteryPoints} pts · ${clue.radiusKm.toStringAsFixed(1)} km',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(body, style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.35)),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white24,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$dailyDone of $dailyTotal daily missions done today',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 14),
          Row(children: buttons),
        ],
      ),
    );
  }
}

/// A place card in "Hidden gems near you".
class _GemCard extends StatelessWidget {
  const _GemCard({
    required this.place,
    required this.supported,
    required this.onTap,
    required this.onSupport,
  });

  final Place place;
  final bool supported;
  final VoidCallback onTap;
  final VoidCallback onSupport;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 156,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Container(
                      height: 92,
                      width: double.infinity,
                      color: AppColors.cream,
                      child: Icon(place.category.icon, size: 36, color: AppColors.terracotta),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: IconButton(
                        tooltip: supported ? 'Supported' : 'Support',
                        visualDensity: VisualDensity.compact,
                        style: IconButton.styleFrom(backgroundColor: Colors.white),
                        onPressed: onSupport,
                        icon: Icon(
                          supported ? Icons.favorite : Icons.favorite_border,
                          size: 18,
                          color: AppColors.teal,
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                  child: Text(
                    place.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 2, 10, 0),
                  child: Text(
                    '${place.distanceKm.toStringAsFixed(1)} km · ${place.storyCount} stories',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: AppColors.muted),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A drawn stand-in for the map. Replace with a small GoogleMap widget
/// when F-04 (map-based discovery) is built.
class _MapPreview extends StatelessWidget {
  const _MapPreview({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFE4EFEA),
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 160,
          child: Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: _StreetsPainter())),
              const Align(alignment: Alignment(-0.6, -0.4), child: _Pin(color: AppColors.terracotta)),
              const Align(alignment: Alignment(0.3, -0.6), child: _Pin(color: AppColors.terracotta)),
              const Align(
                alignment: Alignment(0.7, 0.3),
                child: _Pin(color: AppColors.teal, icon: Icons.question_mark),
              ),
              const Align(alignment: Alignment(-0.1, 0.5), child: _Pin(color: AppColors.terracotta)),
              const Align(alignment: Alignment(0.0, 0.05), child: _MeDot()),
              Positioned(
                left: 12,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pin extends StatelessWidget {
  const _Pin({required this.color, this.icon = Icons.place});

  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Icon(icon, size: 16, color: Colors.white),
    );
  }
}

class _MeDot extends StatelessWidget {
  const _MeDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: const Color(0xFF2F6FED),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
      ),
    );
  }
}

class _StreetsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final road = Paint()
      ..color = Colors.white
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    final lane = Paint()
      ..color = Colors.white
      ..strokeWidth = 5;
    canvas.drawLine(Offset(0, size.height * 0.55), Offset(size.width, size.height * 0.45), road);
    canvas.drawLine(Offset(size.width * 0.4, 0), Offset(size.width * 0.55, size.height), road);
    canvas.drawLine(Offset(size.width * 0.8, 0), Offset(size.width * 0.75, size.height), lane);
    canvas.drawLine(Offset(0, size.height * 0.15), Offset(size.width * 0.45, size.height * 0.2), lane);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ),
        if (action != null) TextButton(onPressed: onAction, child: Text(action!)),
      ],
    );
  }
}
