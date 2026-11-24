import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../models/app_models.dart';
import '../models/dashboard_models.dart';
import '../providers/content_provider.dart';
import '../providers/location_provider.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import '../widgets/place_tile.dart';
import '../widgets/places_map.dart';

const _fitPadding = EdgeInsets.fromLTRB(40, 190, 40, 280);

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _mapController = MapController();
  final _sheetExtent = ValueNotifier<double>(0.25);

  GemCategory? _filter; // null means "All"
  String _query = '';
  String? _lastSig;
  bool _centeredOnUser = false;

  @override
  void dispose() {
    _mapController.dispose();
    _sheetExtent.dispose();
    super.dispose();
  }

  void _moveTo(LatLng point, double zoom) {
    try {
      _mapController.move(point, zoom);
    } catch (_) {
      // Map not ready yet; ignore.
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocationProvider>();
    final user = loc.userLocation;
    final q = _query.trim().toLowerCase();

    // Filter, attach live distance, sort nearest first.
    final ranked = [
      for (final p in context.watch<ContentProvider>().places)
        if ((_filter == null || p.category == _filter) &&
            (q.isEmpty ||
                p.name.toLowerCase().contains(q) ||
                p.blurb.toLowerCase().contains(q)))
          (
            place: p,
            km: user == null
                ? p.distanceKm
                : distanceBetweenKm(user, LatLng(p.lat, p.lng)),
          ),
    ]..sort((a, b) => a.km.compareTo(b.km));
    final places = [for (final r in ranked) r.place];

    // Re-fit the camera when the search/filter result set changes.
    final sig = (places.map((p) => p.id).toList()..sort()).join('|');
    if (_lastSig != null && _lastSig != sig) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (places.length == 1) {
          _moveTo(LatLng(places.first.lat, places.first.lng), 15);
        } else if (places.length >= 2) {
          try {
            _mapController.fitCamera(CameraFit.coordinates(
              coordinates: [for (final p in places) LatLng(p.lat, p.lng)],
              padding: _fitPadding,
              maxZoom: 16,
            ));
          } catch (_) {}
        }
      });
    }
    _lastSig = sig;

    // Center on the user once, when the first GPS fix arrives.
    if (!_centeredOnUser && user != null) {
      _centeredOnUser = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _moveTo(user, 15);
      });
    }

    final showBanner = loc.status == LocationStatus.denied ||
        loc.status == LocationStatus.deniedForever ||
        loc.status == LocationStatus.serviceOff;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // 1) Map fills the whole tab.
            Positioned.fill(
              child: PlacesMap<Place>(
                places: places,
                latLngOf: (p) => LatLng(p.lat, p.lng),
                mapController: _mapController,
                userLocation: user,
                fitPadding: _fitPadding,
                onPlaceTap: (p) => _showPlace(p, user),
              ),
            ),

            // 2) Search + chips (+ permission banner) floating on top.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Column(
                    children: [
                      Material(
                        elevation: 3,
                        borderRadius: BorderRadius.circular(16),
                        child: TextField(
                          onChanged: (v) => setState(() => _query = v),
                          decoration: const InputDecoration(
                            hintText: 'Search places, food, or tags',
                            prefixIcon: Icon(Icons.search),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _chip(null, 'All'),
                            for (final c in GemCategory.values)
                              _chip(c, c.label),
                          ],
                        ),
                      ),
                      if (showBanner) ...[
                        const SizedBox(height: 8),
                        _LocationBanner(
                          status: loc.status,
                          onAction: () {
                            if (loc.status == LocationStatus.denied) {
                              loc.start();
                            } else {
                              loc.openSettings();
                            }
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // 3) My-location button that rides above the sheet.
            ValueListenableBuilder<double>(
              valueListenable: _sheetExtent,
              builder: (context, extent, _) {
                if (extent > 0.5) return const SizedBox.shrink();
                return Positioned(
                  right: 16,
                  bottom: constraints.maxHeight * extent + 12,
                  child: FloatingActionButton.small(
                    heroTag: 'my_location',
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.teal,
                    onPressed: () {
                      final u = context.read<LocationProvider>().userLocation;
                      if (u != null) {
                        _moveTo(u, 16);
                      } else {
                        context.read<LocationProvider>().start();
                      }
                    },
                    child: const Icon(Icons.my_location),
                  ),
                );
              },
            ),

            // 4) Draggable places list.
            Positioned.fill(
              child: NotificationListener<DraggableScrollableNotification>(
                onNotification: (n) {
                  _sheetExtent.value = n.extent;
                  return false;
                },
                child: DraggableScrollableSheet(
                  initialChildSize: 0.25,
                  minChildSize: 0.10,
                  maxChildSize: 0.85,
                  snap: true,
                  snapSizes: const [0.10, 0.25, 0.85],
                  builder: (context, scrollController) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(24)),
                        boxShadow: const [
                          BoxShadow(blurRadius: 12, color: Colors.black26),
                        ],
                      ),
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                        children: [
                          Center(
                            child: Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: AppColors.border,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${places.length} places nearby',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (ranked.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 32),
                              child: Text(
                                'No places match. Try another word or category.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppColors.muted),
                              ),
                            )
                          else
                            for (final r in ranked)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: PlaceTile(
                                  place: r.place,
                                  distanceKm: user == null ? null : r.km,
                                ),
                              ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showPlace(Place place, LatLng? user) {
    final km = user == null
        ? null
        : distanceBetweenKm(user, LatLng(place.lat, place.lng));
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: PlaceTile(place: place, distanceKm: km),
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
        side: BorderSide(
            color: selected ? AppColors.terracotta : AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}

class _LocationBanner extends StatelessWidget {
  const _LocationBanner({required this.status, required this.onAction});

  final LocationStatus status;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final (message, action) = switch (status) {
      LocationStatus.serviceOff => ('Turn on GPS to see gems near you.', 'Settings'),
      LocationStatus.deniedForever => ('Location is blocked for this app.', 'Settings'),
      _ => ('Allow location to see real distances.', 'Allow'),
    };
    return Material(
      color: Colors.white,
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
        child: Row(
          children: [
            const Icon(Icons.location_off, size: 18, color: AppColors.muted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message,
                  style: const TextStyle(fontSize: 12, color: AppColors.ink)),
            ),
            TextButton(onPressed: onAction, child: Text(action)),
          ],
        ),
      ),
    );
  }
}