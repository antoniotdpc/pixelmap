import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../models/explored_area.dart';
import '../models/user.dart';
import '../services/location_service.dart';
import '../services/supabase_service.dart';

// Services
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService();
});

final locationServiceProvider = Provider<LocationService>((ref) {
  final service = LocationService();
  ref.onDispose(() => service.dispose());
  return service;
});

// Auth state
final authStateProvider = StreamProvider((ref) {
  return SupabaseService()._client.auth.onAuthStateChange;
});

final currentUserProvider = FutureProvider<User?>((ref) async {
  final userId = SupabaseService().currentUserId;
  if (userId == null) return null;
  return SupabaseService().getUser(userId);
});

// Location tracking
final currentPositionProvider = StateProvider<LatLng?>((ref) => null);

final headingProvider = StateProvider<double>((ref) => 0.0);

final trackingEnabledProvider = StateProvider<bool>((ref) => false);

final locationStreamProvider = StreamProvider<UserLocation?>((ref) {
  final isTracking = ref.watch(trackingEnabledProvider);
  if (!isTracking) return Stream.value(null);
  
  final userId = SupabaseService().currentUserId;
  if (userId == null) return Stream.value(null);

  return LocationService().locationStream;
});

// Fog of war
final fogRevealRadiusProvider = StateProvider<double>((ref) => 50.0);

final exploredAreasProvider = FutureProvider.family<List<ExploredArea>, LatLngBounds>(
  (ref, bounds) async {
    final userId = SupabaseService().currentUserId;
    if (userId == null) return [];

    return SupabaseService().getExploredAreas(
      userId,
      bounds: bounds,
    );
  },
);

final currentTrackProvider = StateNotifierProvider<CurrentTrackNotifier, List<LatLng>>((ref) {
  return CurrentTrackNotifier();
});

class CurrentTrackNotifier extends StateNotifier<List<LatLng>> {
  CurrentTrackNotifier() : super([]);

  void addPoint(LatLng point) {
    state = [...state, point];
  }

  void clear() {
    state = [];
  }

  void setTrack(List<LatLng> track) {
    state = track;
  }
}

// Map settings
final zoomLevelProvider = StateNotifierProvider<ZoomLevelNotifier, int>((ref) {
  return ZoomLevelNotifier();
});

class ZoomLevelNotifier extends StateNotifier<int> {
  ZoomLevelNotifier() : super(2); // Start at medium zoom

  static const minZoom = 0;
  static const maxZoom = 4;

  void setZoom(int zoom) {
    state = zoom.clamp(minZoom, maxZoom);
  }

  void zoomIn() {
    if (state < maxZoom) state++;
  }

  void zoomOut() {
    if (state > minZoom) state--;
  }

  double get flutterMapZoom {
    // Convert Minecraft zoom (0-4) to Flutter Map zoom (1-19)
    switch (state) {
      case 0: return 19; // Very close
      case 1: return 16; // Close
      case 2: return 13; // Medium
      case 3: return 10; // Far
      case 4: return 6;  // World view
      default: return 13;
    }
  }
}

final mapStyleProvider = StateProvider<String>((ref) => 'minecraft');

// UI state
final showFogOverlayProvider = StateProvider<bool>((ref) => true);
final showTrackProvider = StateProvider<bool>((ref) => true);
final showCompassProvider = StateProvider<bool>((ref) => true);
final selectedLocationProvider = StateProvider<LatLng?>((ref) => null);
