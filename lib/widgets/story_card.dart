import 'package:flutter/material.dart';

import '../models/dashboard_models.dart';
import '../theme/app_theme.dart';

/// One story in the feed. Shows the story text and a support count,
/// never a star rating.
class StoryCard extends StatelessWidget {
  const StoryCard({super.key, required this.story, this.onTap});

  final Story story;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.cream,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(story.category.icon, color: AppColors.terracotta),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          story.placeName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${story.category.label} · ${story.distanceKm.toStringAsFixed(1)} km away',
                          style: const TextStyle(fontSize: 12, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                story.excerpt,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(height: 1.4, color: AppColors.ink),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    '${story.authorName} · ${story.postedAgo}',
                    style: const TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                  const Spacer(),
                  const Icon(Icons.volunteer_activism, size: 16, color: AppColors.teal),
                  const SizedBox(width: 4),
                  Text(
                    '${story.supportCount} supported',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.teal,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
