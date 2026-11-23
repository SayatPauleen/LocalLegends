import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_models.dart';
import '../models/dashboard_models.dart';
import '../providers/content_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/reward_dialog.dart';
import '../widgets/story_card.dart';
import 'story_detail_screen.dart';
import 'write_story_screen.dart';

/// Shop / place page: details, Support (favorite), Check in, Write a Story,
/// and every story about this place.
class PlaceDetailScreen extends StatelessWidget {
  const PlaceDetailScreen({super.key, required this.place});

  final Place place;

  static Future<void> open(BuildContext context, Place place) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PlaceDetailScreen(place: place)),
    );
  }

  Future<void> _checkIn(BuildContext context) async {
    final content = context.read<ContentProvider>();
    final rewards = await content.checkIn(place);
    if (!context.mounted) return;
    if (rewards.isEmpty) {
      showMessage(context, 'Checked in at ${place.name}. Thanks for visiting!');
    } else {
      await showRewards(context, rewards);
    }
  }

  Future<void> _toggleSupport(BuildContext context) async {
    final content = context.read<ContentProvider>();
    final rewards = await content.toggleSupport(place.id);
    if (!context.mounted) return;
    if (rewards.isNotEmpty) await showRewards(context, rewards);
  }

  @override
  Widget build(BuildContext context) {
    final content = context.watch<ContentProvider>();
    final supported = content.isSupported(place.id);
    final checkedIn = content.checkedInToday(place.id);
    final stories = content.storiesForPlace(place);

    return Scaffold(
      appBar: AppBar(title: Text(place.name, overflow: TextOverflow.ellipsis)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Container(
            height: 170,
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(place.category.icon, size: 64, color: AppColors.terracotta),
          ),
          const SizedBox(height: 16),
          Text(
            place.name,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.ink),
          ),
          const SizedBox(height: 4),
          Text(
            '${place.category.label} · ${place.distanceKm.toStringAsFixed(1)} km away',
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          Text(place.blurb, style: const TextStyle(height: 1.4, color: AppColors.ink)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: supported
                    ? FilledButton.icon(
                        onPressed: () => _toggleSupport(context),
                        icon: const Icon(Icons.favorite, size: 18),
                        label: const Text('Supported'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 46),
                          backgroundColor: AppColors.teal,
                        ),
                      )
                    : OutlinedButton.icon(
                        onPressed: () => _toggleSupport(context),
                        icon: const Icon(Icons.favorite_border, size: 18),
                        label: const Text('Support'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 46),
                          foregroundColor: AppColors.teal,
                          side: const BorderSide(color: AppColors.teal),
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: checkedIn ? null : () => _checkIn(context),
                  icon: Icon(checkedIn ? Icons.check_circle : Icons.where_to_vote_outlined, size: 18),
                  label: Text(checkedIn ? 'Visited today' : 'I visited'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 46),
                    foregroundColor: AppColors.terracotta,
                    side: const BorderSide(color: AppColors.terracotta),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: () => WriteStoryScreen.open(context, place: place),
            icon: const Icon(Icons.edit_note),
            label: const Text('Write a Story'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              backgroundColor: AppColors.terracotta,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            stories.isEmpty ? 'Stories' : 'Stories (${stories.length})',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink),
          ),
          const SizedBox(height: 10),
          if (stories.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No stories yet. Be the first to tell what makes this place special.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted),
              ),
            )
          else
            for (final s in stories)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: StoryCard(
                  story: s,
                  onTap: () => StoryDetailScreen.open(context, s, fromPlacePage: true),
                ),
              ),
        ],
      ),
    );
  }
}
