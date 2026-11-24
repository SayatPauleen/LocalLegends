class MapConfig {
  static const maptilerKey = String.fromEnvironment('MAPTILER_KEY');
  static const style = 'openstreetmap'; // or 'streets-v2'

  static bool get hasKey => maptilerKey.isNotEmpty;

  static String get tileUrl =>
      'https://api.maptiler.com/maps/$style/{z}/{x}/{y}{r}.png?key=$maptilerKey';
}