import 'dart:math';
import 'package:flutter/material.dart';

class CompassWidget extends StatelessWidget {
  final double heading;
  final double size;

  const CompassWidget({
    super.key,
    required this.heading,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black87,
        border: Border.all(
          color: Colors.grey.shade600,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: Stack(
          children: [
            // Compass background with directions
            CustomPaint(
              size: Size(size, size),
              painter: CompassBackgroundPainter(),
            ),
            // Rotating needle
            Center(
              child: Transform.rotate(
                angle: -heading * (pi / 180),
                child: CustomPaint(
                  size: Size(size * 0.8, size * 0.8),
                  painter: CompassNeedlePainter(),
                ),
              ),
            ),
            // Center dot
            Center(
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
            ),
            // Heading text
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Text(
                '${heading.toInt()}°',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Minecraft',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CompassBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw cardinal directions
    final textStyle = TextStyle(
      color: Colors.grey.shade400,
      fontSize: 12,
      fontWeight: FontWeight.bold,
      fontFamily: 'Minecraft',
    );

    // North
    _drawText(canvas, 'N', Offset(center.dx, 5), textStyle);
    // South
    _drawText(canvas, 'S', Offset(center.dx, size.height - 18), textStyle);
    // East
    _drawText(canvas, 'E', Offset(size.width - 15, center.dy - 6), textStyle);
    // West
    _drawText(canvas, 'W', Offset(5, center.dy - 6), textStyle);

    // Draw degree marks
    final markPaint = Paint()
      ..color = Colors.grey.shade600
      ..strokeWidth = 1;

    for (int i = 0; i < 360; i += 15) {
      final angle = i * (pi / 180);
      final isMajor = i % 90 == 0;
      final innerRadius = radius - (isMajor ? 15 : 10);
      
      final startX = center.dx + innerRadius * sin(angle);
      final startY = center.dy - innerRadius * cos(angle);
      final endX = center.dx + (radius - 5) * sin(angle);
      final endY = center.dy - (radius - 5) * cos(angle);

      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        markPaint..strokeWidth = isMajor ? 2 : 1,
      );
    }
  }

  void _drawText(Canvas canvas, String text, Offset position, TextStyle style) {
    final textSpan = TextSpan(text: text, style: style);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(position.dx - textPainter.width / 2, position.dy),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CompassNeedlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final length = size.width / 2 - 5;

    // North (red) part of needle
    final northPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    final northPath = Path()
      ..moveTo(center.dx, center.dy - length)
      ..lineTo(center.dx - 6, center.dy)
      ..lineTo(center.dx + 6, center.dy)
      ..close();

    canvas.drawPath(northPath, northPaint);

    // South (white) part of needle
    final southPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final southPath = Path()
      ..moveTo(center.dx, center.dy + length)
      ..lineTo(center.dx - 6, center.dy)
      ..lineTo(center.dx + 6, center.dy)
      ..close();

    canvas.drawPath(southPath, southPaint);

    // Outline
    final outlinePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawPath(northPath, outlinePaint);
    canvas.drawPath(southPath, outlinePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
