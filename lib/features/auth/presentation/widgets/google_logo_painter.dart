import 'dart:math' as math;
import 'package:flutter/material.dart';

class GoogleLogoPainter extends CustomPainter {
  const GoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;
    final double sizeMin = math.min(width, height);
    final double radius = sizeMin / 2.0;

    // Center point
    final Offset center = Offset(width / 2.0, height / 2.0);

    // Google G Logo color specs
    final Paint bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;

    final Paint greenPaint = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.fill;

    final Paint yellowPaint = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.fill;

    final Paint redPaint = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.fill;

    // Define the bounding box for outer circle
    final Rect rect = Rect.fromCircle(center: center, radius: radius);

    // Thickness of the G segment (roughly 23% of total size)
    final double thickness = sizeMin * 0.23;
    final double innerRadius = radius - thickness;

    // Draw Blue segment (Top Right Arc + Horizontal Bar)
    // Blue arc from around -45 degrees (315) to 0 degrees, plus the horizontal bar
    final Path bluePath = Path();
    bluePath.moveTo(center.dx, center.dy);
    // Draw horizontal bar on the right
    bluePath.lineTo(center.dx + radius, center.dy);
    bluePath.lineTo(center.dx + radius, center.dy - thickness / 1.05);
    bluePath.lineTo(center.dx + thickness * 0.1, center.dy - thickness / 1.05);
    // Outer arc from 0 to -45 degrees (315 in positive angles)
    bluePath.arcTo(rect, 0.0, -math.pi / 4, false);
    bluePath.lineTo(
      center.dx + innerRadius * math.cos(-math.pi / 4),
      center.dy + innerRadius * math.sin(-math.pi / 4),
    );
    // Inner arc back to the bar
    bluePath.arcTo(
      Rect.fromCircle(center: center, radius: innerRadius),
      -math.pi / 4,
      math.pi / 4,
      false,
    );
    bluePath.close();
    canvas.drawPath(bluePath, bluePaint);

    // Draw Red segment (Top/Top-Left Arc)
    // Red arc from -45 degrees (315) to -135 degrees (225)
    final Path redPath = Path();
    redPath.moveTo(center.dx, center.dy);
    redPath.arcTo(rect, -math.pi / 4, -math.pi * 0.55, false);
    redPath.arcTo(
      Rect.fromCircle(center: center, radius: innerRadius),
      -math.pi / 4 - math.pi * 0.55,
      math.pi * 0.55,
      false,
    );
    redPath.close();
    canvas.drawPath(redPath, redPaint);

    // Draw Yellow segment (Left/Bottom-Left Arc)
    // Yellow arc from -135 degrees (225) to -225 degrees (135)
    final Path yellowPath = Path();
    yellowPath.moveTo(center.dx, center.dy);
    yellowPath.arcTo(rect, -math.pi / 4 - math.pi * 0.55, -math.pi * 0.28, false);
    yellowPath.arcTo(
      Rect.fromCircle(center: center, radius: innerRadius),
      -math.pi / 4 - math.pi * 0.55 - math.pi * 0.28,
      math.pi * 0.28,
      false,
    );
    yellowPath.close();
    canvas.drawPath(yellowPath, yellowPaint);

    // Draw Green segment (Bottom/Bottom-Right Arc)
    // Green arc from 135 degrees (or -225) to 0 degrees
    final Path greenPath = Path();
    greenPath.moveTo(center.dx, center.dy);
    greenPath.arcTo(
      rect,
      -math.pi / 4 - math.pi * 0.55 - math.pi * 0.28,
      -math.pi * 0.67,
      false,
    );
    greenPath.arcTo(
      Rect.fromCircle(center: center, radius: innerRadius),
      -math.pi / 4 - math.pi * 0.55 - math.pi * 0.28 - math.pi * 0.67,
      math.pi * 0.67,
      false,
    );
    greenPath.close();
    canvas.drawPath(greenPath, greenPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GoogleLogoWidget extends StatelessWidget {
  final double size;

  const GoogleLogoWidget({
    super.key,
    this.size = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: const CustomPaint(
        painter: GoogleLogoPainter(),
      ),
    );
  }
}
