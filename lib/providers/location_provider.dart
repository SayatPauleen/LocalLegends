import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../services/location_service.dart';

/// Holds the user's live GPS position for any screen to watch.
class LocationProvider extends ChangeNotifier {
  LocationProvider([LocationService? service])
      : _service = service ?? LocationService();

  final LocationService _service;
  StreamSubscription<LatLng>? _sub;

  LatLng? _userLocation;
  LocationStatus _status = LocationStatus.loading;

  LatLng? get userLocation => _userLocation;
  LocationStatus get status => _status;

  Future<void> start() async {
    _status = LocationStatus.loading;
    notifyListeners();

    final result = await _service.ensurePermission();
    if (result != LocationStatus.granted) {
      _status = result;
      notifyListeners();
      return;
    }

    _status = LocationStatus.granted;
    try {
      _userLocation = await _service.current();
    } catch (_) {
      // The stream below will deliver a position when one is available.
    }
    notifyListeners();

    await _sub?.cancel();
    _sub = _service.positions().listen(
      (pos) {
        _userLocation = pos;
        notifyListeners();
      },
      onError: (_) {},
    );
  }

  Future<void> openSettings() {
    return _status == LocationStatus.serviceOff
        ? _service.openLocationSettings()
        : _service.openAppSettings();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}