import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../models/explored_area.dart';
import '../providers/map_providers.dart';
import '../services/supabase_service.dart';
import '../utils/tile_utils.dart';
import 'fog_overlay.dart';
import 'user_marker.dart';
import 'compass_widget.dart';

class PixelMap extends ConsumerStatefulWidget {
  const PixelMap({super.key});

  @override
  ConsumerState<PixelMap> createState() => _PixelMapState();
}

class _PixelMapState extends ConsumerState<PixelMap> {
  final MapController _mapController = MapController();
  List<LatLng> _currentTrack = [];

  @override
  void initState() {
    super.initState();
    _initTracking();
  }

  Future<void> _initTracking() async {
    final locationService = ref.read(locationServiceProvider);
    final hasPermission = await locationService.requestPermission();

    if (hasPermission) {
      ref.read(trackingEnabledProvider.notifier).state = true;

      final position = await locationService.getCurrentPosition();
      if (position != null && mounted) {
        final latLng = LatLng(position.latitude, position.longitude);
        ref.read(currentPositionProvider.notifier).state = latLng;
        _mapController.move(latLng, ref.read(zoomLevelProvider.notifier).flutterMapZoom);
      }

      locationService.startTracking(
        userId: SupabaseService().currentUserId ?? 'anonymous',
        onLocationUpdate: (location) {
          if (mounted) {
            ref.read(currentPositionProvider.notifier).state =
                LatLng(location.latitude, location.longitude);
            ref.read(headingProvider.notifier).state = location.heading;
          }
        },
        onTrackUpdate: (track) {
          if (mounted) {
            setState(() => _currentTrack = track);
          }
        },
      );
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentPosition = ref.watch(currentPositionProvider);
    final heading = ref.watch(headingProvider);
    final zoomLevel = ref.watch(zoomLevelProvider);
    final showFog = ref.watch(showFogOverlayProvider);
    final showTrack = ref.watch(showTrackProvider);

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: currentPosition ?? const LatLng(0, 0),
            initialZoom: zoomLevel.notifier.flutterMapZoom,
            onPositionChanged: (position, hasGesture) {
              if (hasGesture) {
                // Update zoom level based on map zoom
                final newZoom = _mapZoomToMinecraftZoom(position.zoom);
                if (newZoom != zoomLevel) {
                  ref.read(zoomLevelProvider.notifier).setZoom(newZoom);
                }
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.pixelmap.app',
              tileBuilder: _pixelatedTileBuilder,
            ),
            if (showTrack && _currentTrack.length > 1)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _currentTrack,
                    strokeWidth: 3,
                    color: Colors.amber.withOpacity(0.8),
                  ),
                ],
              ),
            if (currentPosition != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: currentPosition,
                    width: 40,
                    height: 40,
                    child: UserMarker(heading: heading),
                  ),
                ],
              ),
            if (showFog)
              FogOverlay(
                mapController: _mapController,
                exploredPolygons: _getExploredPolygons(),
              ),
          ],
        ),
        Positioned(
          top: 16,
          right: 16,
          child: CompassWidget(heading: heading),
        ),
        Positioned(
          bottom: 100,
          right: 16,
          child: _ZoomControls(
            zoomLevel: zoomLevel,
            onZoomIn: () => _zoomIn(),
            onZoomOut: () => _zoomOut(),
          ),
        ),
      ],
    );
  }

  Widget _pixelatedTileBuilder(BuildContext context, Widget tileWidget, TileImage tile) {
    // Apply pixelation effect based on zoom level
    final zoomLevel = ref.read(zoomLevelProvider);
    final pixelationFactor = _getPixelationFactor(zoomLevel);

    return LayoutBuilder(
      builder: (context, constraints) {
        return ShaderMask(
          shaderCallback: (Rect bounds) {
            return LinearGradient(
              colors: [Colors.white, Colors.white],
            ).createShader(bounds);
          },
          child: ImageFiltered(
            imageFilter: pixelationFactor > 0
                ? PixelizationFilter(pixelationFactor)
                : const ColorFilter.matrix([
                    1, 0, 0, 0, 0,
                    0, 1, 0, 0, 0,
                    0, 0, 1, 0, 0,
                    0, 0, 0, 1, 0,
                  ]),
            child: tileWidget,
          ),
        );
      },
    );
  }

  double _getPixelationFactor(int minecraftZoom) {
    // Higher zoom = more pixelation
    switch (minecraftZoom) {
      case 0: return 0.0;    // No pixelation
      case 1: return 0.3;
      case 2: return 0.6;
      case 3: return 1.2;
      case 4: return 2.0;    // Heavy pixelation
      default: return 0.5;
    }
  }

  int _mapZoomToMinecraftZoom(double mapZoom) {
    if (mapZoom >= 18) return 0;
    if (mapZoom >= 15) return 1;
    if (mapZoom >= 12) return 2;
    if (mapZoom >= 9) return 3;
    return 4;
  }

  void _zoomIn() {
    final newZoom = ref.read(zoomLevelProvider.notifier).state - 1;
    if (newZoom >= 0) {
      ref.read(zoomLevelProvider.notifier).setZoom(newZoom);
      _mapController.move(
        _mapController.camera.center,
        ref.read(zoomLevelProvider.notifier).flutterMapZoom,
      );
    }
  }

  void _zoomOut() {
    final newZoom = ref.read(zoomLevelProvider.notifier).state + 1;
    if (newZoom <= 4) {
      ref.read(zoomLevelProvider.notifier).setZoom(newZoom);
      _mapController.move(
        _mapController.camera.center,
        ref.read(zoomLevelProvider.notifier).flutterMapZoom,
      );
    }
  }

  List<List<LatLng>> _getExploredPolygons() {
    // This will be populated from the provider
    return [];
  }
}

class _ZoomControls extends StatelessWidget {
  final int zoomLevel;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  const _ZoomControls({
    required this.zoomLevel,
    required this.onZoomIn,
    required this.onZoomOut,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade700),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: zoomLevel > 0 ? onZoomIn : null,
            tooltip: 'Zoom In',
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.shade700),
                bottom: BorderSide(color: Colors.grey.shade700),
              ),
            ),
            child: Text(
              'Zoom: $zoomLevel',
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Minecraft',
                fontSize: 12,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove, color: Colors.white),
            onPressed: zoomLevel < 4 ? onZoomOut : null,
            tooltip: 'Zoom Out',
          ),
        ],
      ),
    );
  }
}

class PixelizationFilter extends ImageFilter {
  final double factor;

  const PixelizationFilter(this.factor);

  @override
  ImageFilterInterface createInterface() {
    throw UnimplementedError();
  }
}
