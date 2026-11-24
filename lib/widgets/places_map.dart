import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../config/map_config.dart';
import '../theme/app_theme.dart';

const _fallbackCenter = LatLng(13.7565, 121.0583); // Batangas City

class PlacesMap<T> extends StatelessWidget {
  const PlacesMap({
    super.key,
    required this.places,
    required this.latLngOf,
    this.mapController,
    this.userLocation,
    this.fitPadding = const EdgeInsets.all(40),
    this.onPlaceTap,
  });

  final List<T> places;
  final LatLng Function(T place) latLngOf;
  final MapController? mapController;
  final LatLng? userLocation;
  final EdgeInsets fitPadding;
  final void Function(T place)? onPlaceTap;

  @override
  Widget build(BuildContext context) {
    final points = [for (final p in places) latLngOf(p)];

    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: points.length == 1 ? points.first : _fallbackCenter,
        initialZoom: points.length == 1 ? 15 : 14,
        initialCameraFit: points.length >= 2
            ? CameraFit.coordinates(
                coordinates: points,
                padding: fitPadding,
                maxZoom: 16,
              )
            : null,
        minZoom: 3,
        maxZoom: 19,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: MapConfig.hasKey
              ? MapConfig.tileUrl
              : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.local_legends',
          retinaMode: MapConfig.hasKey && RetinaMode.isHighDensity(context),
        ),
        MarkerLayer(
          markers: [
            for (final p in places)
              Marker(
                point: latLngOf(p),
                width: 44,
                height: 44,
                alignment: Alignment.topCenter,
                child: GestureDetector(
                  onTap: onPlaceTap == null ? null : () => onPlaceTap!(p),
                  child: const Icon(
                    Icons.location_on,
                    size: 44,
                    color: AppColors.terracotta,
                  ),
                ),
              ),
          ],
        ),
        if (userLocation != null)
          MarkerLayer(
            markers: [
              Marker(
                point: userLocation!,
                width: 24,
                height: 24,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A73E8),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: const [
                      BoxShadow(blurRadius: 6, color: Colors.black38),
                    ],
                  ),
                ),
              ),
            ],
          ),
        const RichAttributionWidget(
          alignment: AttributionAlignment.bottomLeft,
          attributions: [
            TextSourceAttribution('© MapTiler'),
            TextSourceAttribution('© OpenStreetMap contributors'),
          ],
        ),
      ],
    );
  }
}