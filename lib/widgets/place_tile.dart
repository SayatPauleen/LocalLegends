import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_models.dart';
import '../models/dashboard_models.dart';
import '../providers/content_provider.dart';
import '../theme/app_theme.dart';

/// One place in Explore or Profile > Supported, with a Support toggle
/// that works like a favorite.
class PlaceTile extends StatelessWidget {
  const PlaceTile({super.key, required this.place, this.distanceKm});

  final Place place;
  final double? distanceKm; // live distance from GPS; falls back to place.distanceKm

  @override
  Widget build(BuildContext context) {
    final content = context.watch<ContentProvider>();
    final supported = content.isSupported(place.id);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(place.category.icon, color: AppColors.terracotta),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place.name,
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink),
                ),
                const SizedBox(height: 2),
                Text(
                  '${place.category.label} · ${(distanceKm ?? place.distanceKm).toStringAsFixed(1)} km · ${place.storyCount} stories',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
                const SizedBox(height: 4),
                Text(
                  place.blurb,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.ink),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _SupportButton(
            supported: supported,
            onPressed: () => content.toggleSupport(place.id),
          ),
        ],
      ),
    );
  }
}

class _SupportButton extends StatelessWidget {
  const _SupportButton({required this.supported, required this.onPressed});

  final bool supported;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final style = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(0, 38)),
      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 12)),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
    final icon = Icon(supported ? Icons.favorite : Icons.favorite_border, size: 16);

    return Semantics(
      toggled: supported,
      child: supported
          ? FilledButton.icon(
              onPressed: onPressed,
              icon: icon,
              label: const Text('Supported'),
              style: style.copyWith(
                backgroundColor: const WidgetStatePropertyAll(AppColors.teal),
              ),
            )
          : OutlinedButton.icon(
              onPressed: onPressed,
              icon: icon,
              label: const Text('Support'),
              style: style.copyWith(
                foregroundColor: const WidgetStatePropertyAll(AppColors.teal),
                side: const WidgetStatePropertyAll(BorderSide(color: AppColors.teal)),
              ),
            ),
    );
  }
}