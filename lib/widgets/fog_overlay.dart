import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class FogOverlay extends StatefulWidget {
  final MapController mapController;
  final List<List<LatLng>> exploredPolygons;

  const FogOverlay({
    super.key,
    required this.mapController,
    required this.exploredPolygons,
  });

  @override
  State<FogOverlay> createState() => _FogOverlayState();
}

class _FogOverlayState extends State<FogOverlay> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: FogPainter(
            mapController: widget.mapController,
            exploredPolygons: widget.exploredPolygons,
          ),
        );
      },
    );
  }
}

class FogPainter extends CustomPainter {
  final MapController mapController;
  final List<List<LatLng>> exploredPolygons;

  FogPainter({
    required this.mapController,
    required this.exploredPolygons,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw fog background
    final fogPaint = Paint()
      ..color = const Color(0xDD1a1a2e) // Dark blue-grey fog
      ..style = PaintingStyle.fill;

    // Fill entire canvas with fog
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      fogPaint,
    );

    // Cut out explored areas using差集 (difference)
    final path = Path();
    path.addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // Create path for explored areas
    final exploredPath = Path();
    for (final polygon in exploredPolygons) {
      if (polygon.isEmpty) continue;

      final firstPoint = _latLngToOffset(polygon.first);
      exploredPath.moveTo(firstPoint.dx, firstPoint.dy);

      for (int i = 1; i < polygon.length; i++) {
        final point = _latLngToOffset(polygon[i]);
        exploredPath.lineTo(point.dx, point.dy);
      }
      exploredPath.close();
    }

    // Apply the explored path as a mask
    final combinedPath = Path.combine(
      PathOperation.difference,
      path,
      exploredPath,
    );

    // Draw fog only on unexplored areas
    canvas.drawPath(combinedPath, fogPaint);

    // Add fog texture/grid pattern
    _drawFogTexture(canvas, size);
  }

  void _drawFogTexture(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0x10FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    const gridSize = 20.0;

    // Draw vertical lines
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // Draw horizontal lines
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  Offset _latLngToOffset(LatLng latLng) {
    final point = mapController.camera.project(latLng);
    return Offset(point.x.toDouble(), point.y.toDouble());
  }

  @override
  bool shouldRepaint(covariant FogPainter oldDelegate) {
    return oldDelegate.exploredPolygons != exploredPolygons ||
           oldDelegate.mapController.camera != mapController.camera;
  }
}

// Alternative: Use a shader-based fog effect
class FogShaderWidget extends StatelessWidget {
  final Widget child;
  final List<List<LatLng>> exploredAreas;

  const FogShaderWidget({
    super.key,
    required this.child,
    required this.exploredAreas,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.5,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                  stops: const [0.3, 1.0],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
