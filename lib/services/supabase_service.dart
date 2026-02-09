import 'dart:convert';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/explored_area.dart';
import '../models/user.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  final SupabaseClient _client = Supabase.instance.client;

  // User operations
  Future<User?> getUser(String userId) async {
    final response = await _client
        .from('users')
        .select('*, settings:user_settings(*), stats:user_stats(*)')
        .eq('id', userId)
        .single();

    if (response == null) return null;
    return User.fromJson(response);
  }

  Future<void> updateUserSettings(String userId, UserSettings settings) async {
    await _client
        .from('user_settings')
        .upsert({
          'user_id': userId,
          ...settings.toJson(),
          'updated_at': DateTime.now().toIso8601String(),
        });
  }

  // Location tracking
  Future<void> saveLocation(UserLocation location) async {
    await _client.from('user_locations').insert({
      'id': location.id,
      'user_id': location.userId,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'accuracy': location.accuracy,
      'altitude': location.altitude,
      'speed': location.speed,
      'heading': location.heading,
      'recorded_at': location.recordedAt.toIso8601String(),
    });
  }

  Future<void> uploadTrackSegment(String userId, List<LatLng> track) async {
    if (track.length < 2) return;

    final coordinates = track
        .map((p) => '[${p.longitude},${p.latitude}]')
        .join(',');
    
    final geoJson = '{"type":"LineString","coordinates":[$coordinates]}';

    await _client.rpc('process_track_segment', params: {
      'p_user_id': userId,
      'p_track_geojson': geoJson,
    });
  }

  // Explored areas
  Future<List<ExploredArea>> getExploredAreas(
    String userId, {
    required LatLngBounds bounds,
    int? zoomLevel,
  }) async {
    var query = _client
        .from('explored_areas')
        .select()
        .eq('user_id', userId)
        .gte('min_lat', bounds.south)
        .lte('max_lat', bounds.north)
        .gte('min_lng', bounds.west)
        .lte('max_lng', bounds.east);

    if (zoomLevel != null) {
      query = query.eq('zoom_level', zoomLevel);
    }

    final response = await query;
    
    return (response as List)
        .map((json) => ExploredArea.fromJson(json))
        .toList();
  }

  Future<bool> isLocationExplored(String userId, LatLng location) async {
    final response = await _client.rpc('is_location_explored', params: {
      'p_user_id': userId,
      'p_latitude': location.latitude,
      'p_longitude': location.longitude,
    });

    return response as bool;
  }

  // Fog of war
  Future<List<Map<String, dynamic>>> getFogPolygons(
    String userId, {
    required LatLngBounds bounds,
  }) async {
    final response = await _client.rpc('get_fog_polygons', params: {
      'p_user_id': userId,
      'p_min_lat': bounds.south,
      'p_max_lat': bounds.north,
      'p_min_lng': bounds.west,
      'p_max_lng': bounds.east,
    });

    return (response as List).cast<Map<String, dynamic>>();
  }

  // Tile cache
  Future<void> cacheTile(MapTile tile, List<int> pixelatedData) async {
    await _client.from('tile_cache').upsert({
      'tile_key': tile.key,
      'x': tile.x,
      'y': tile.y,
      'z': tile.z,
      'pixelated_data': base64Encode(pixelatedData),
      'processed_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<int>?> getCachedTile(String tileKey) async {
    final response = await _client
        .from('tile_cache')
        .select('pixelated_data')
        .eq('tile_key', tileKey)
        .single();

    if (response == null || response['pixelated_data'] == null) return null;
    
    return base64Decode(response['pixelated_data']);
  }

  // Auth
  Future<AuthResponse> signIn(String email, String password) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUp(String email, String password) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  User? get currentUser => _client.auth.currentUser;
  String? get currentUserId => _client.auth.currentUser?.id;
}

class LatLngBounds {
  final double north;
  final double south;
  final double east;
  final double west;

  LatLngBounds({
    required this.north,
    required this.south,
    required this.east,
    required this.west,
  });

  bool contains(LatLng point) {
    return point.latitude >= south &&
        point.latitude <= north &&
        point.longitude >= west &&
        point.longitude <= east;
  }
}
