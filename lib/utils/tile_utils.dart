import 'dart:math';

class TileUtils {
  static const int tileSize = 256;

  /// Convert latitude/longitude to tile coordinates at given zoom
  static TileCoordinate latLngToTile(double lat, double lng, int zoom) {
    final latRad = lat * pi / 180;
    final n = pow(2, zoom);
    
    final x = ((lng + 180) / 360 * n).floor();
    final y = ((1 - log(tan(latRad) + 1 / cos(latRad)) / pi) / 2 * n).floor();
    
    return TileCoordinate(x, y, zoom);
  }

  /// Convert tile coordinates to latitude/longitude (top-left corner)
  static LatLng tileToLatLng(int x, int y, int zoom) {
    final n = pow(2, zoom);
    
    final lng = x / n * 360 - 180;
    final latRad = atan(sinh(pi * (1 - 2 * y / n)));
    final lat = latRad * 180 / pi;
    
    return LatLng(lat, lng);
  }

  /// Get tile bounds
  static TileBounds getTileBounds(int x, int y, int zoom) {
    final nw = tileToLatLng(x, y, zoom);
    final se = tileToLatLng(x + 1, y + 1, zoom);
    
    return TileBounds(
      north: nw.lat,
      south: se.lat,
      east: se.lng,
      west: nw.lng,
    );
  }

  /// Get surrounding tiles
  static List<TileCoordinate> getSurroundingTiles(
    int x,
    int y,
    int zoom,
    int radius,
  ) {
    final tiles = <TileCoordinate>[];
    
    for (int dx = -radius; dx <= radius; dx++) {
      for (int dy = -radius; dy <= radius; dy++) {
        tiles.add(TileCoordinate(x + dx, y + dy, zoom));
      }
    }
    
    return tiles;
  }

  /// Calculate distance between two lat/lng points in meters
  static double distanceBetween(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const earthRadius = 6371000; // meters
    
    final dLat = (lat2 - lat1) * pi / 180;
    final dLng = (lng2 - lng1) * pi / 180;
    
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLng / 2) *
            sin(dLng / 2);
    
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }

  /// Convert zoom level to approximate meters per pixel
  static double metersPerPixel(double latitude, int zoom) {
    return 156543.03392 * cos(latitude * pi / 180) / pow(2, zoom);
  }

  /// Get tile key for caching
  static String getTileKey(int x, int y, int zoom) {
    return '$zoom/$x/$y';
  }
}

class TileCoordinate {
  final int x;
  final int y;
  final int z;

  const TileCoordinate(this.x, this.y, this.z);

  String get key => TileUtils.getTileKey(x, y, z);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TileCoordinate &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y &&
          z == other.z;

  @override
  int get hashCode => x.hashCode ^ y.hashCode ^ z.hashCode;

  @override
  String toString() => 'TileCoordinate($x, $y, $z)';
}

class LatLng {
  final double lat;
  final double lng;

  const LatLng(this.lat, this.lng);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LatLng &&
          runtimeType == other.runtimeType &&
          lat == other.lat &&
          lng == other.lng;

  @override
  int get hashCode => lat.hashCode ^ lng.hashCode;
}

class TileBounds {
  final double north;
  final double south;
  final double east;
  final double west;

  const TileBounds({
    required this.north,
    required this.south,
    required this.east,
    required this.west,
  });

  bool contains(LatLng point) {
    return point.lat >= south &&
        point.lat <= north &&
        point.lng >= west &&
        point.lng <= east;
  }

  LatLng get center => LatLng(
        (north + south) / 2,
        (east + west) / 2,
      );

  double get width => east - west;
  double get height => north - south;
}
