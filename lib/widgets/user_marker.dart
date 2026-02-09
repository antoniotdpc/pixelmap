import 'dart:math';
import 'package:flutter/material.dart';

class UserMarker extends StatelessWidget {
  final double heading;

  const UserMarker({
    super.key,
    required this.heading,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: heading * (pi / 180),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.blue.withOpacity(0.3),
          border: Border.all(
            color: Colors.blue,
            width: 2,
          ),
        ),
        child: Center(
          child: Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue,
            ),
          ),
        ),
      ),
    );
  }
}

class DirectionIndicator extends StatelessWidget {
  final double heading;
  final double size;

  const DirectionIndicator({
    super.key,
    required this.heading,
    this.size = 30,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: heading * (pi / 180),
      child: CustomPaint(
        size: Size(size, size),
        painter: ArrowPainter(),
      ),
    );
  }
}

class ArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width / 2, size.height * 0.7)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);

    // Add white outline
    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
