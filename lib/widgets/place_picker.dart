import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_models.dart';
import '../models/dashboard_models.dart';
import '../providers/content_provider.dart';
import '../theme/app_theme.dart';
import 'reward_dialog.dart';

/// Bottom sheet listing places, nearest first. Returns the one tapped.
Future<Place?> pickPlace(BuildContext context, {required String title}) {
  final places = [...context.read<ContentProvider>().places]
    ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
  return showModalBottomSheet<Place>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink),
            ),
          ),
          for (final p in places)
            ListTile(
              leading: Icon(p.category.icon, color: AppColors.terracotta),
              title: Text(p.name),
              subtitle: Text('${p.category.label} · ${p.distanceKm.toStringAsFixed(1)} km away'),
              onTap: () => Navigator.pop(ctx, p),
            ),
        ],
      ),
    ),
  );
}

/// "I found it" for the Mystery Mission, used on Home and Missions.
Future<void> finishMysteryMission(BuildContext context) async {
  final content = context.read<ContentProvider>();
  final place = await pickPlace(context, title: 'Which place did you find?');
  if (place == null || !context.mounted) return;
  final List<MissionReward> rewards = await content.completeMystery(place);
  if (context.mounted) await showRewards(context, rewards);
}
