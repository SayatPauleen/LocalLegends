import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/dashboard_models.dart';
import '../providers/content_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/reward_dialog.dart';
import 'place_detail_screen.dart';

/// The full story: text, who they met, what makes the place special,
/// and buttons to support or open the place.
class StoryDetailScreen extends StatelessWidget {
  const StoryDetailScreen({super.key, required this.story, this.fromPlacePage = false});

  final Story story;

  /// True when opened from that place's page, so "View place" just goes back.
  final bool fromPlacePage;

  static Future<void> open(BuildContext context, Story story, {bool fromPlacePage = false}) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StoryDetailScreen(story: story, fromPlacePage: fromPlacePage),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = context.watch<ContentProvider>();
    final place = content.placeForStory(story);
    final supported = place != null && content.isSupported(place.id);
    final isMine = story.authorUid != null && story.authorUid == content.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Story')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.teal,
                child: Text(
                  story.authorName.replaceAll('@', '').isEmpty
                      ? '?'
                      : story.authorName.replaceAll('@', '')[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isMine ? '${story.authorName} (you)' : story.authorName,
                      style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink),
                    ),
                    Text(
                      'at ${story.placeName} · ${story.postedAgo}',
                      style: const TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            story.excerpt,
            style: const TextStyle(fontSize: 16, height: 1.5, color: AppColors.ink),
          ),
          if ((story.whoTheyMet ?? '').isNotEmpty) ...[
            const SizedBox(height: 18),
            _Section(icon: Icons.people_outline, title: 'Who I met', text: story.whoTheyMet!),
          ],
          if ((story.whatMakesItSpecial ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            _Section(
              icon: Icons.auto_awesome_outlined,
              title: 'What makes it special',
              text: story.whatMakesItSpecial!,
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              Icon(story.category.icon, size: 18, color: AppColors.terracotta),
              const SizedBox(width: 6),
              Text(
                '${story.category.label} · ${story.distanceKm.toStringAsFixed(1)} km away',
                style: const TextStyle(color: AppColors.muted),
              ),
            ],
          ),
          if (place != null) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final rewards = await content.toggleSupport(place.id);
                      if (context.mounted) await showRewards(context, rewards);
                    },
                    icon: Icon(supported ? Icons.favorite : Icons.favorite_border, size: 18),
                    label: Text(supported ? 'Supported' : 'Support this place'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 46),
                      foregroundColor: AppColors.teal,
                      side: const BorderSide(color: AppColors.teal),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      if (fromPlacePage) {
                        Navigator.of(context).pop();
                      } else {
                        PlaceDetailScreen.open(context, place);
                      }
                    },
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 46),
                      backgroundColor: AppColors.terracotta,
                    ),
                    child: const Text('View place'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.icon, required this.title, required this.text});

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.terracotta),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
                const SizedBox(height: 4),
                Text(text, style: const TextStyle(height: 1.4, color: AppColors.ink)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
