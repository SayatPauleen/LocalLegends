import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

enum LocationStatus { loading, granted, denied, deniedForever, serviceOff }

class LocationService {
  /// Checks that GPS is on and asks for permission if needed.
  Future<LocationStatus> ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocationStatus.serviceOff;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      return LocationStatus.deniedForever;
    }
    if (permission == LocationPermission.denied) {
      return LocationStatus.denied;
    }
    return LocationStatus.granted;
  }

  Future<LatLng> current() async {
    final pos = await Geolocator.getCurrentPosition();
    return LatLng(pos.latitude, pos.longitude);
  }

  /// Emits a new position roughly every 10 meters of movement.
  Stream<LatLng> positions() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).map((p) => LatLng(p.latitude, p.longitude));
  }

  Future<void> openAppSettings() => Geolocator.openAppSettings();
  Future<void> openLocationSettings() => Geolocator.openLocationSettings();
}

double distanceBetweenKm(LatLng a, LatLng b) =>
    const Distance().distance(a, b) / 1000;