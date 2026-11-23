import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../theme/app_theme.dart';

/// The "Mission completed" screen from the wireframe, as a dialog.
/// Does nothing when [rewards] is empty.
Future<void> showRewards(BuildContext context, List<MissionReward> rewards) async {
  if (rewards.isEmpty || !context.mounted) return;
  final total = rewards.fold<int>(0, (sum, r) => sum + r.points);
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: const Icon(Icons.emoji_events, color: AppColors.terracotta, size: 44),
      title: Text(rewards.length == 1 ? 'Mission completed!' : 'Missions completed!'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '+$total pts',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.terracotta,
            ),
          ),
          const SizedBox(height: 12),
          for (final r in rewards)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, size: 18, color: AppColors.teal),
                  const SizedBox(width: 8),
                  Expanded(child: Text(r.title, style: const TextStyle(color: AppColors.ink))),
                  Text('+${r.points}', style: const TextStyle(color: AppColors.muted)),
                ],
              ),
            ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Nice!')),
      ],
    ),
  );
}

/// One-line message at the bottom of the screen.
void showMessage(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}
