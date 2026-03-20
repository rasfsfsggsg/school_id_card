import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/graphic_item.dart';

class GraphicShapeHelper {

  /// ================= MAIN BUILD =================
  static Widget build(GraphicItem item) {
    return SizedBox(
      width: item.width,
      height: item.height,
      child: _buildShape(item),
    );
  }

  /// ================= SHAPE SWITCH =================
  static Widget _buildShape(GraphicItem item) {
    switch (item.type) {

    /// 🔵 CIRCLE (will stretch to oval if resized vertically)
      case GraphicType.circle:
        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: item.safeColor,
            shape: BoxShape.rectangle, // rectangle + borderRadius gives stretch
            borderRadius: BorderRadius.circular(
              math.min(item.width, item.height) / 2,
            ),
          ),
        );

    /// 🟥 RECTANGLE
      case GraphicType.rectangle:
        return Container(
          width: double.infinity,
          height: double.infinity,
          color: item.safeColor,
        );

    /// ⭐ STAR
      case GraphicType.star:
        return CustomPaint(
          painter: _StarPainter(item.safeColor),
          size: Size.infinite,
        );

    /// 🔷 POLYGON
      case GraphicType.polygon:
        return CustomPaint(
          painter: _PolygonPainter(item.safeColor),
          size: Size.infinite,
        );

      default:
        return const SizedBox();
    }
  }
}

//////////////////////////////////////////////////////////////////
/// ================= STAR PAINTER =================
//////////////////////////////////////////////////////////////////

class _StarPainter extends CustomPainter {
  final Color color;
  _StarPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();

    final cx = size.width / 2;
    final cy = size.height / 2;

    final outerRadius = math.min(size.width, size.height) / 2;
    final innerRadius = outerRadius / 2;

    for (int i = 0; i < 10; i++) {
      final isOuter = i % 2 == 0;
      final radius = isOuter ? outerRadius : innerRadius;
      final angle = i * math.pi / 5;

      final x = cx + radius * math.cos(angle);
      final y = cy + radius * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

//////////////////////////////////////////////////////////////////
/// ================= POLYGON PAINTER =================
//////////////////////////////////////////////////////////////////

class _PolygonPainter extends CustomPainter {
  final Color color;
  _PolygonPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();

    const sides = 6;

    final cx = size.width / 2;
    final cy = size.height / 2;

    final rx = size.width / 2;
    final ry = size.height / 2;

    for (int i = 0; i < sides; i++) {
      final angle = i * 2 * math.pi / sides;

      final x = cx + rx * math.cos(angle);
      final y = cy + ry * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}