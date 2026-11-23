import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_models.dart';
import '../models/dashboard_models.dart';
import '../providers/content_provider.dart';
import '../providers/tab_navigator.dart';
import '../theme/app_theme.dart';
import '../widgets/place_picker.dart';
import '../widgets/reward_dialog.dart';
import 'write_story_screen.dart';

const badgeIcons = <String, IconData>{
  'story': Icons.auto_stories_outlined,
  'food': Icons.ramen_dining_outlined,
  'support': Icons.volunteer_activism_outlined,
  'mystery': Icons.explore_outlined,
  'history': Icons.history_edu_outlined,
  'legend': Icons.workspace_premium_outlined,
};

/// Missions tab: daily and weekly missions with points, a Mystery
/// Mission, and badges.
class MissionsScreen extends StatefulWidget {
  const MissionsScreen({super.key});

  @override
  State<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends State<MissionsScreen> {
  MissionPeriod _period = MissionPeriod.daily;

  /// Each mission's button takes you to where you can do it.
  void _goDo(Mission m) {
    final nav = context.read<TabNavigator>();
    switch (m.id) {
      case 'd1':
        nav.openExplore(category: GemCategory.streetFood);
      case 'd2':
        WriteStoryScreen.open(context);
      case 'd3':
        nav.openExplore();
      case 'w1':
        nav.openExplore(category: GemCategory.smallBusiness);
      case 'w2':
        nav.open(HomeTabs.collections);
      default:
        showMessage(context, 'Finish any daily missions to fill this one.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = context.watch<ContentProvider>();
    final missions = content.missions.where((m) => m.period == _period).toList();
    final unlocked = content.badges.where((b) => b.unlocked).length;
    final toNextLevel = 100 - content.points % 100;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          const Text(
            'Missions',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.ink),
          ),
          const SizedBox(height: 12),
          // Points and level
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.teal,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${content.points} pts',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      'Level ${content.level} · $toNextLevel pts to Level ${content.level + 1}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
                const Spacer(),
                const Icon(Icons.emoji_events_outlined, color: Colors.white, size: 36),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SegmentedButton<MissionPeriod>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: MissionPeriod.daily, label: Text('Daily')),
              ButtonSegment(value: MissionPeriod.weekly, label: Text('Weekly')),
            ],
            selected: {_period},
            onSelectionChanged: (s) => setState(() => _period = s.first),
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: AppColors.terracotta,
              selectedForegroundColor: Colors.white,
              side: const BorderSide(color: AppColors.border),
            ),
          ),
          const SizedBox(height: 16),
          _MysteryCard(
            clue: content.currentClue?.clue,
            accepted: content.mysteryAccepted,
            doneToday: content.mysteryDoneToday,
            onReveal: content.acceptMystery,
            onFound: () => finishMysteryMission(context),
          ),
          const SizedBox(height: 16),
          Text(
            _period == MissionPeriod.daily ? 'Today · resets at midnight' : 'This week · resets Monday',
            style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink),
          ),
          const SizedBox(height: 10),
          for (final m in missions)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _MissionTile(mission: m, onStart: () => _goDo(m)),
            ),
          const SizedBox(height: 12),
          Text(
            'Badges · $unlocked of ${content.badges.length}',
            style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink),
          ),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1,
            children: [
              for (final b in content.badges)
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => showMessage(
                    context,
                    b.unlocked ? '${b.name}: unlocked!' : '${b.name}: ${b.howTo}',
                  ),
                  child: _BadgeTile(badge: b),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MysteryCard extends StatelessWidget {
  const _MysteryCard({
    required this.clue,
    required this.accepted,
    required this.doneToday,
    required this.onReveal,
    required this.onFound,
  });

  final String? clue;
  final bool accepted;
  final bool doneToday;
  final VoidCallback onReveal;
  final VoidCallback onFound;

  @override
  Widget build(BuildContext context) {
    final String subtitle;
    final Widget action;
    if (doneToday) {
      subtitle = 'Solved today. A new mystery unlocks tomorrow.';
      action = const Icon(Icons.check_circle, color: AppColors.teal);
    } else if (accepted) {
      subtitle = clue ?? 'Find the hidden spot.';
      action = TextButton(onPressed: onFound, child: const Text('I found it'));
    } else {
      subtitle = 'A random spot nearby. Revealed when you accept. +${ContentProvider.mysteryPoints} pts';
      action = TextButton(onPressed: onReveal, child: const Text('Reveal'));
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.terracotta),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              accepted || doneToday ? '!' : '?',
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.terracotta),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Mystery Mission',
                    style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              ],
            ),
          ),
          action,
        ],
      ),
    );
  }
}

class _MissionTile extends StatelessWidget {
  const _MissionTile({required this.mission, required this.onStart});

  final Mission mission;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final done = mission.isComplete;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mission.title,
                      style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink),
                    ),
                    const SizedBox(height: 2),
                    Text(mission.detail,
                        style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '+${mission.points} pts',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.terracotta),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: mission.progress,
              minHeight: 6,
              backgroundColor: AppColors.border,
              color: AppColors.teal,
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${mission.done} of ${mission.goal}',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ),
              TextButton(
                onPressed: done ? null : onStart,
                child: Text(done ? 'Completed' : (mission.done > 0 ? 'Continue' : 'Go')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.badge});

  final MissionBadge badge;

  @override
  Widget build(BuildContext context) {
    final on = badge.unlocked;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: on ? AppColors.cream : const Color(0xFFF1EDE7),
            child: Icon(
              on ? (badgeIcons[badge.icon] ?? Icons.star_outline) : Icons.lock_outline,
              color: on ? AppColors.terracotta : AppColors.muted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            badge.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(fontSize: 11, color: on ? AppColors.ink : AppColors.muted),
          ),
        ],
      ),
    );
  }
}
