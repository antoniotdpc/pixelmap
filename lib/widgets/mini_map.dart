import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MiniMap extends StatelessWidget {
  final LatLng? currentPosition;
  final double heading;
  final VoidCallback? onTap;

  const MiniMap({
    super.key,
    this.currentPosition,
    this.heading = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade700, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: FlutterMap(
            options: MapOptions(
              initialCenter: currentPosition ?? const LatLng(0, 0),
              initialZoom: 15,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.none,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.pixelmap.app',
                tileBuilder: _pixelatedTileBuilder,
              ),
              if (currentPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: currentPosition!,
                      width: 20,
                      height: 20,
                      child: Transform.rotate(
                        angle: heading * 3.14159 / 180,
                        child: const Icon(
                          Icons.navigation,
                          color: Colors.amber,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              // Viewport rectangle indicator
              if (currentPosition != null)
                PolygonLayer(
                  polygons: [
                    Polygon(
                      points: _getViewportPolygon(),
                      borderColor: Colors.amber,
                      borderStrokeWidth: 2,
                      color: Colors.transparent,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pixelatedTileBuilder(BuildContext context, Widget tileWidget, TileImage tile) {
    return ImageFiltered(
      imageFilter: const ColorFilter.matrix([
        0.5, 0, 0, 0, 0,
        0, 0.5, 0, 0, 0,
        0, 0, 0.5, 0, 0,
        0, 0, 0, 1, 0,
      ]),
      child: tileWidget,
    );
  }

  List<LatLng> _getViewportPolygon() {
    if (currentPosition == null) return [];

    // Approximate viewport rectangle
    const delta = 0.001;
    return [
      LatLng(currentPosition!.latitude - delta, currentPosition!.longitude - delta),
      LatLng(currentPosition!.latitude - delta, currentPosition!.longitude + delta),
      LatLng(currentPosition!.latitude + delta, currentPosition!.longitude + delta),
      LatLng(currentPosition!.latitude + delta, currentPosition!.longitude - delta),
    ];
  }
}
