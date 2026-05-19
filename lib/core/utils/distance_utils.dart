import 'dart:math';

/// İki koordinat arasındaki mesafeyi Haversine formülü ile hesaplar.
class DistanceUtils {
  /// İki GPS noktası arasındaki mesafeyi kilometre olarak döner.
  static double haversineKm(
      double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0; // Dünya yarıçapı (km)
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  static double _toRad(double deg) => deg * pi / 180;

  /// Mesafeyi kullanıcı dostu string'e dönüştürür.
  static String formatDistance(double km) {
    if (km < 1) return '${(km * 1000).round()} m';
    if (km < 10) return '${km.toStringAsFixed(1)} km';
    return '${km.round()} km';
  }
}
