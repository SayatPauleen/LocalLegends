import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/dashboard_models.dart';
import '../providers/content_provider.dart';
import '../providers/tab_navigator.dart';
import '../theme/app_theme.dart';
import '../widgets/place_tile.dart';

/// Explore tab: search, category filter, map preview, and nearby places
/// with a Support (favorite) button.
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  GemCategory? _filter; // null means "All"
  String _query = '';
  final _searchCtrl = TextEditingController();
  late final TabNavigator _nav;

  @override
  void initState() {
    super.initState();
    _nav = context.read<TabNavigator>();
    _nav.addListener(_takeSearchFromHome);
    _takeSearchFromHome();
  }

  @override
  void dispose() {
    _nav.removeListener(_takeSearchFromHome);
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Home's search bar sends its text (and category chip) here.
  void _takeSearchFromHome() {
    final search = _nav.takeExploreSearch();
    if (search == null || !mounted) return;
    setState(() {
      _query = search.query;
      _filter = search.category;
      _searchCtrl.text = search.query;
    });
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final places = context.watch<ContentProvider>().places.where((p) {
      final matchesCategory = _filter == null || p.category == _filter;
      final matchesQuery = q.isEmpty ||
          p.name.toLowerCase().contains(q) ||
          p.blurb.toLowerCase().contains(q) ||
          p.category.label.toLowerCase().contains(q);
      return matchesCategory && matchesQuery;
    }).toList()
      ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          const Text(
            'Explore',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.ink),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchCtrl,
            textInputAction: TextInputAction.search,
            onChanged: (v) => setState(() => _query = v),
            decoration: const InputDecoration(
              hintText: 'Search places, food, or tags',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          if (_query.isNotEmpty || _filter != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() {
                  _query = '';
                  _filter = null;
                  _searchCtrl.clear();
                }),
                icon: const Icon(Icons.close, size: 16),
                label: const Text('Clear search'),
              ),
            ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _chip(null, 'All'),
                for (final c in GemCategory.values) _chip(c, c.label),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _MapBanner(count: places.length),
          const SizedBox(height: 16),
          Text(
            '${places.length} places nearby',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink),
          ),
          const SizedBox(height: 10),
          if (places.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Text(
                'No places match. Try another word or category.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted),
              ),
            )
          else
            for (final p in places)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: PlaceTile(place: p),
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

/// Stand-in for the full map (F-04). Replace with GoogleMap later.
class _MapBanner extends StatelessWidget {
  const _MapBanner({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFE4EFEA),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Full map is coming soon.'))),
        child: SizedBox(
          height: 120,
          child: Row(
            children: [
              const SizedBox(width: 20),
              const Icon(Icons.map_outlined, size: 40, color: AppColors.teal),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'See them on the map',
                      style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink),
                    ),
                    Text(
                      '$count gems within 3 km',
                      style: const TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.teal),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }
}
