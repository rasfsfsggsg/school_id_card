import 'dart:math';
import 'package:flutter/material.dart';

class RedDashedBorder extends StatelessWidget {
  final double widthPx;
  final double heightPx;
  final double widthCm;
  final double heightCm;
  final double strokeWidth;
  final Color color;
  final double dashWidth;
  final double dashSpace;
  final double labelFontSize;
  final bool showLabels;

  const RedDashedBorder({
    super.key,
    required this.widthPx,
    required this.heightPx,
    required this.widthCm,
    required this.heightCm,
    this.strokeWidth = 3,
    this.color = Colors.red,
    this.dashWidth = 8,
    this.dashSpace = 6,
    this.labelFontSize = 18,
    this.showLabels = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widthPx,
      height: heightPx,
      child: CustomPaint(
        painter: _RedDashedBorderPainter(
          widthCm: widthCm,
          heightCm: heightCm,
          strokeWidth: strokeWidth,
          color: color,
          dashWidth: dashWidth,
          dashSpace: dashSpace,
          labelFontSize: labelFontSize,
          showLabels: showLabels,
        ),
      ),
    );
  }
}

class _RedDashedBorderPainter extends CustomPainter {
  final double widthCm;
  final double heightCm;
  final double strokeWidth;
  final Color color;
  final double dashWidth;
  final double dashSpace;
  final double labelFontSize;
  final bool showLabels;

  _RedDashedBorderPainter({
    required this.widthCm,
    required this.heightCm,
    required this.strokeWidth,
    required this.color,
    required this.dashWidth,
    required this.dashSpace,
    required this.labelFontSize,
    required this.showLabels,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    // ======= DASHED BORDER =======
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(
          Offset(x, 0),
          Offset(min(x + dashWidth, size.width), 0),
          borderPaint);
      canvas.drawLine(
          Offset(x, size.height),
          Offset(min(x + dashWidth, size.width), size.height),
          borderPaint);
      x += dashWidth + dashSpace;
    }

    double y = 0;
    while (y < size.height) {
      canvas.drawLine(
          Offset(0, y),
          Offset(0, min(y + dashWidth, size.height)),
          borderPaint);
      canvas.drawLine(
          Offset(size.width, y),
          Offset(size.width, min(y + dashWidth, size.height)),
          borderPaint);
      y += dashWidth + dashSpace;
    }

    if (!showLabels) return;

    final textStyle = TextStyle(
      color: color,
      fontSize: labelFontSize,
      fontWeight: FontWeight.bold,
    );

    // ======= COMMON GAP =======
    final double gap = 8; // border से text तक समान gap

    // ======= TOP TEXT =======
    final widthText = "<---- ${widthCm.toStringAsFixed(2)} cm ---->";
    final widthPainter = TextPainter(
      text: TextSpan(text: widthText, style: textStyle),
      textDirection: TextDirection.ltr,
    );
    widthPainter.layout();

    // Top border से ऊपर paint करना
    widthPainter.paint(
      canvas,
      Offset(size.width / 2 - widthPainter.width / 2, -widthPainter.height - gap),
    );

    // ======= RIGHT TEXT =======
    final heightText = "<---- ${heightCm.toStringAsFixed(2)} cm ---->";
    final heightPainter = TextPainter(
      text: TextSpan(text: heightText, style: textStyle),
      textDirection: TextDirection.ltr,
    );
    heightPainter.layout();

    // Right border के पास rotate करके paint करना
    canvas.save();
    // Translate to border + gap
    canvas.translate(size.width + gap, size.height / 2 + heightPainter.width / 2);
    canvas.rotate(-pi / 2);
    heightPainter.paint(canvas, Offset.zero);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}