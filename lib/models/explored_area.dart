import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:latlong2/latlong.dart';

part 'explored_area.freezed.dart';
part 'explored_area.g.dart';

@freezed
class ExploredArea with _$ExploredArea {
  const factory ExploredArea({
    required String id,
    required String userId,
    required List<LatLng> polygon,
    required DateTime exploredAt,
    required int zoomLevel,
    String? tileKey,
    double? accuracy,
  }) = _ExploredArea;

  factory ExploredArea.fromJson(Map<String, dynamic> json) =>
      _$ExploredAreaFromJson(json);
}

@freezed
class UserLocation with _$UserLocation {
  const factory UserLocation({
    required String id,
    required String userId,
    required double latitude,
    required double longitude,
    required double accuracy,
    required double altitude,
    required double speed,
    required double heading,
    required DateTime recordedAt,
  }) = _UserLocation;

  factory UserLocation.fromJson(Map<String, dynamic> json) =>
      _$UserLocationFromJson(json);
}

@freezed
class MapTile with _$MapTile {
  const factory MapTile({
    required String id,
    required int x,
    required int y,
    required int z,
    required String url,
    String? pixelatedUrl,
    DateTime? processedAt,
    required DateTime createdAt,
  }) = _MapTile;

  factory MapTile.fromJson(Map<String, dynamic> json) =>
      _$MapTileFromJson(json);
}

class TileCoordinates {
  final int x;
  final int y;
  final int z;

  const TileCoordinates(this.x, this.y, this.z);

  String get key => '$z/$x/$y';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TileCoordinates &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y &&
          z == other.z;

  @override
  int get hashCode => x.hashCode ^ y.hashCode ^ z.hashCode;

  @override
  String toString() => 'TileCoordinates($x, $y, $z)';
}
