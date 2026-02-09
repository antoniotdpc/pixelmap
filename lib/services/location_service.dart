import 'dart:async';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/explored_area.dart';
import 'supabase_service.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  StreamSubscription<Position>? _positionStream;
  final _locationController = StreamController<UserLocation>.broadcast();
  final List<LatLng> _currentTrack = [];
  DateTime? _lastUpload;

  Stream<UserLocation> get locationStream => _locationController.stream;
  List<LatLng> get currentTrack => List.unmodifiable(_currentTrack);

  Future<bool> requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }

    if (permission == LocationPermission.deniedForever) return false;

    return true;
  }

  Future<Position?> getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
    } catch (e) {
      return null;
    }
  }

  void startTracking({
    required String userId,
    Function(UserLocation)? onLocationUpdate,
    Function(List<LatLng>)? onTrackUpdate,
  }) {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 5, // Update every 5 meters
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((position) async {
      final location = UserLocation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        altitude: position.altitude,
        speed: position.speed,
        heading: position.heading,
        recordedAt: DateTime.now(),
      );

      _locationController.add(location);
      _currentTrack.add(LatLng(position.latitude, position.longitude));

      onLocationUpdate?.call(location);
      onTrackUpdate?.call(List.unmodifiable(_currentTrack));

      // Batch upload every 30 seconds or every 50 points
      await _maybeUploadTrack(userId);
    });
  }

  Future<void> _maybeUploadTrack(String userId) async {
    final now = DateTime.now();
    if (_lastUpload != null && now.difference(_lastUpload!).inSeconds < 30) {
      if (_currentTrack.length < 50) return;
    }

    if (_currentTrack.length < 2) return;

    try {
      await SupabaseService().uploadTrackSegment(userId, _currentTrack);
      _currentTrack.clear();
      _lastUpload = now;
    } catch (e) {
      // Keep points for retry
    }
  }

  void stopTracking() {
    _positionStream?.cancel();
    _positionStream = null;
  }

  void clearTrack() {
    _currentTrack.clear();
  }

  void dispose() {
    stopTracking();
    _locationController.close();
  }
}
