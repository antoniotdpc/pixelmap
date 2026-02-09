import 'package:flutter_test/flutter_test.dart';
import 'package:pixelmap/utils/tile_utils.dart';

void main() {
  group('TileUtils', () {
    test('latLngToTile converts coordinates correctly', () {
      // Test coordinate conversion
      final tile = TileUtils.latLngToTile(51.5074, -0.1278, 10);
      
      expect(tile.x, isA<int>());
      expect(tile.y, isA<int>());
      expect(tile.z, equals(10));
    });

    test('tileToLatLng converts back correctly', () {
      const tileCoord = TileCoordinate(512, 340, 10);
      final latLng = TileUtils.tileToLatLng(tileCoord.x, tileCoord.y, tileCoord.z);
      
      expect(latLng.lat, isA<double>());
      expect(latLng.lng, isA<double>());
    });

    test('distanceBetween calculates correctly', () {
      // Distance between London and Paris (approx 344 km)
      final distance = TileUtils.distanceBetween(
        51.5074, -0.1278,  // London
        48.8566, 2.3522,   // Paris
      );
      
      expect(distance, greaterThan(340000)); // > 340 km
      expect(distance, lessThan(350000));    // < 350 km
    });

    test('getTileKey generates correct format', () {
      final key = TileUtils.getTileKey(1, 2, 3);
      expect(key, equals('3/1/2'));
    });

    test('getSurroundingTiles returns correct count', () {
      final tiles = TileUtils.getSurroundingTiles(100, 100, 10, 1);
      // 3x3 grid = 9 tiles
      expect(tiles.length, equals(9));
    });
  });

  group('TileCoordinate', () {
    test('equality works correctly', () {
      const tile1 = TileCoordinate(10, 20, 5);
      const tile2 = TileCoordinate(10, 20, 5);
      const tile3 = TileCoordinate(11, 20, 5);

      expect(tile1, equals(tile2));
      expect(tile1, isNot(equals(tile3)));
    });

    test('hashCode is consistent', () {
      const tile = TileCoordinate(10, 20, 5);
      expect(tile.hashCode, equals(tile.hashCode));
    });
  });
}
