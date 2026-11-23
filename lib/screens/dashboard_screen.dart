import 'package:flutter/material.dart';

import '../models/dashboard_models.dart';
import '../theme/app_theme.dart';
import '../widgets/story_card.dart';

/// Tab indexes in HomeShell, so the dashboard can jump to other tabs.
/// Revision 2 tabs: Home, Explore, Missions, Collections, Profile.
class HomeTabs {
  static const home = 0;
  static const explore = 1;
  static const missions = 2;
  static const collections = 3;
  static const profile = 4;
}

/// The Home dashboard: greeting, stats, today's Mystery Mission,
/// a map preview, and the story feed.
///
/// It takes plain values instead of reading AuthProvider, so it can be
/// widget tested without Firebase.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.userName,
    required this.data,
    required this.onSignOut,
    required this.onOpenTab,
  });

  final String userName;
  final DashboardData data;
  final VoidCallback onSignOut;
  final ValueChanged<int> onOpenTab;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  GemCategory? _filter; // null means "All"
  int _clueIndex = 0;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  void _comingSoon(String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$feature is coming soon.')));
  }

  void _nextClue() {
    final clues = widget.data.missionClues;
    if (clues.isEmpty) return;
    setState(() => _clueIndex = (_clueIndex + 1) % clues.length);
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final stories = _filter == null
        ? data.stories
        : data.stories.where((s) => s.category == _filter).toList();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          _Header(
            greeting: _greeting,
            userName: widget.userName,
            onProfile: () => widget.onOpenTab(HomeTabs.profile),
            onSignOut: widget.onSignOut,
          ),
          const SizedBox(height: 16),
          TextField(
            readOnly: true,
            onTap: () => widget.onOpenTab(HomeTabs.explore),
            decoration: const InputDecoration(
              hintText: 'Search places, food, or tags',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.auto_stories_outlined,
                  value: '${data.storiesShared}',
                  label: 'Stories shared',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  icon: Icons.volunteer_activism_outlined,
                  value: '${data.placesSupported}',
                  label: 'Places supported',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  icon: Icons.flag_outlined,
                  value: '${data.missionsCompletedThisWeek}/${data.weeklyMissionGoal}',
                  label: 'Missions this week',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (data.missionClues.isNotEmpty)
            _MissionCard(
              clue: data.missionClues[_clueIndex],
              completed: data.missionsCompletedThisWeek,
              goal: data.weeklyMissionGoal,
              onAccept: () => widget.onOpenTab(HomeTabs.missions),
              onDifferent: _nextClue,
            ),
          const SizedBox(height: 24),
          _SectionTitle(
            title: 'Gems around you',
            action: 'Explore',
            onAction: () => widget.onOpenTab(HomeTabs.explore),
          ),
          const SizedBox(height: 10),
          _MapPreview(onTap: () => widget.onOpenTab(HomeTabs.explore)),
          const SizedBox(height: 24),
          const _SectionTitle(title: 'Stories near you'),
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
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Text(
                'No stories in this category yet. Be the first to share one.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted),
              ),
            )
          else
            for (final story in stories)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: StoryCard(
                  story: story,
                  onTap: () => _comingSoon('Full story view'),
                ),
              ),
        ],
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

class _StatTile extends StatelessWidget {
  const _StatTile({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
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
    );
  }
}

class _MissionCard extends StatelessWidget {
  const _MissionCard({
    required this.clue,
    required this.completed,
    required this.goal,
    required this.onAccept,
    required this.onDifferent,
  });

  final MissionClue clue;
  final int completed;
  final int goal;
  final VoidCallback onAccept;
  final VoidCallback onDifferent;

  @override
  Widget build(BuildContext context) {
    final progress = goal == 0 ? 0.0 : (completed / goal).clamp(0.0, 1.0);
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
              const Icon(Icons.explore_outlined, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text(
                "Today's Mystery Mission",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Text(
                'Within ${clue.radiusKm.toStringAsFixed(1)} km',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            clue.clue,
            style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.35),
          ),
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
            '$completed of $goal missions completed this week',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: onAccept,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.teal,
                  ),
                  child: const Text('Accept'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: onDifferent,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white70),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Different one'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A drawn stand-in for the map. Replace with a small GoogleMap widget
/// when F-04 (map-based discovery) is built.
class _MapPreview extends StatelessWidget {
  const _MapPreview({required this.onTap});

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
              const Align(alignment: Alignment(0.7, 0.3), child: _Pin(color: AppColors.teal, icon: Icons.question_mark)),
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
                  child: const Text(
                    '4 gems and 1 mission nearby',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink),
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
        if (action != null)
          TextButton(onPressed: onAction, child: Text(action!)),
      ],
    );
  }
}
