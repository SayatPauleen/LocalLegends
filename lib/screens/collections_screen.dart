import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_models.dart';
import '../providers/content_provider.dart';
import '../theme/app_theme.dart';

/// Collections tab: Neighborhood Transformation timelines showing how a
/// business, town or city changed over the years.
class CollectionsScreen extends StatefulWidget {
  const CollectionsScreen({super.key});

  @override
  State<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends State<CollectionsScreen> {
  CollectionKind? _filter; // null means "All"

  @override
  Widget build(BuildContext context) {
    final all = context.watch<ContentProvider>().collections;
    final items = _filter == null ? all : all.where((c) => c.kind == _filter).toList();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Collections',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.ink),
                ),
              ),
              IconButton.filled(
                tooltip: 'Start a collection',
                style: IconButton.styleFrom(backgroundColor: AppColors.terracotta),
                onPressed: () => ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    const SnackBar(content: Text('Starting a collection is coming soon.')),
                  ),
                icon: const Icon(Icons.add, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'How our businesses, towns and cities changed over time, told in photos by the community.',
            style: TextStyle(color: AppColors.muted, height: 1.4),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              _chip(null, 'All'),
              for (final k in CollectionKind.values) _chip(k, k.label),
            ],
          ),
          const SizedBox(height: 16),
          for (final c in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _CollectionCard(collection: c),
            ),
        ],
      ),
    );
  }

  Widget _chip(CollectionKind? kind, String label) {
    final selected = _filter == kind;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _filter = kind),
      selectedColor: AppColors.terracotta,
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppColors.ink,
        fontWeight: FontWeight.w600,
      ),
      showCheckmark: false,
      backgroundColor: Colors.white,
      side: BorderSide(color: selected ? AppColors.terracotta : AppColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}

class _CollectionCard extends StatefulWidget {
  const _CollectionCard({required this.collection});

  final TransformationCollection collection;

  @override
  State<_CollectionCard> createState() => _CollectionCardState();
}

class _CollectionCardState extends State<_CollectionCard> {
  late int _era = widget.collection.timeline.length - 1;

  @override
  Widget build(BuildContext context) {
    final c = widget.collection;
    final then = c.timeline.first;
    final now = c.timeline[_era];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _PhotoBox(label: 'Then', year: then.year)),
              const SizedBox(width: 8),
              Expanded(child: _PhotoBox(label: 'Era', year: now.year, highlight: true)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  c.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.ink),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(c.kind.label,
                    style: const TextStyle(fontSize: 12, color: AppColors.terracotta)),
              ),
            ],
          ),
          Text(
            '${c.timeline.length} eras · ${c.fromYear}–${c.toYear}',
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          Slider(
            value: _era.toDouble(),
            min: 0,
            max: (c.timeline.length - 1).toDouble(),
            divisions: c.timeline.length - 1,
            label: '${now.year}',
            activeColor: AppColors.terracotta,
            inactiveColor: AppColors.border,
            onChanged: (v) => setState(() => _era = v.round()),
          ),
          Text(
            '${now.year}: ${now.caption}',
            style: const TextStyle(height: 1.4, color: AppColors.ink),
          ),
        ],
      ),
    );
  }
}

/// Stand-in for a then/now photo. Swap for Image.network later.
class _PhotoBox extends StatelessWidget {
  const _PhotoBox({required this.label, required this.year, this.highlight = false});

  final String label;
  final int year;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: highlight ? const Color(0xFFE4EFEA) : AppColors.cream,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_outlined, color: highlight ? AppColors.teal : AppColors.terracotta),
          const SizedBox(height: 4),
          Text('$label · $year', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        ],
      ),
    );
  }
}
