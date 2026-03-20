import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/graphic_item.dart';

class GraphicLineHelper {
  static const double baseSize = 100;

  /// ================= LINE TYPE CHECK =================
  static bool isLineType(GraphicItem item) {
    return item.type == GraphicType.line ||
        item.type == GraphicType.thickLine ||
        item.type == GraphicType.dashedLine ||
        item.type == GraphicType.arrowLine ||
        item.type == GraphicType.doubleLine;
  }

  /// ================= BUILD LINE =================
  static Widget buildLine({required GraphicItem item}) {
    return CustomPaint(
      size: Size(baseSize * item.scale, 20),
      painter: _getPainter(item),
    );
  }

  static CustomPainter _getPainter(GraphicItem item) {
    switch (item.type) {
      case GraphicType.line:
        return LinePainter(item.safeColor, 2);
      case GraphicType.thickLine:
        return LinePainter(item.safeColor, 6);
      case GraphicType.dashedLine:
        return DashedLinePainter(item.safeColor, 3);
      case GraphicType.arrowLine:
        return ArrowLinePainter(item.safeColor);
      case GraphicType.doubleLine:
        return DoubleLinePainter(item.safeColor);
      default:
        return LinePainter(Colors.transparent, 1);
    }
  }
}






/// ================= LINE RESIZE HANDLES =================

class LineResizeHandles extends StatefulWidget {
  final double currentScale;
  final double rotation;

  final double canvasWidth;
  final double itemX;

  final Function(double newScale, bool isLeft) onUpdateScale;

  const LineResizeHandles({
    super.key,
    required this.currentScale,
    required this.rotation,
    required this.canvasWidth,
    required this.itemX,
    required this.onUpdateScale,
  });

  @override
  State<LineResizeHandles> createState() => _LineResizeHandlesState();
}

class _LineResizeHandlesState extends State<LineResizeHandles> {
  static const double handleSize = 14.0;
  static const double hitHeight = 20.0;

  /// ================= ROTATED CURSOR =================
  MouseCursor _getRotatedCursor() {
    double angle = widget.rotation % 180;
    if (angle < 0) angle += 180;

    if ((angle >= 0 && angle < 22.5) ||
        (angle >= 157.5 && angle <= 180)) {
      return SystemMouseCursors.resizeLeftRight;
    } else if (angle >= 22.5 && angle < 67.5) {
      return SystemMouseCursors.resizeUpLeftDownRight;
    } else if (angle >= 67.5 && angle < 112.5) {
      return SystemMouseCursors.resizeUpDown;
    } else {
      return SystemMouseCursors.resizeUpRightDownLeft;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scaledWidth =
        GraphicLineHelper.baseSize * widget.currentScale;

    return SizedBox(
      width: scaledWidth,
      height: hitHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [

          /// LEFT HANDLE
          Positioned(
            left: -handleSize / 2,
            top: (hitHeight - handleSize) / 2,
            child: _handle(isLeft: true),
          ),

          /// RIGHT HANDLE
          Positioned(
            right: -handleSize / 2,
            top: (hitHeight - handleSize) / 2,
            child: _handle(isLeft: false),
          ),
        ],
      ),
    );
  }






  Widget _handle({required bool isLeft}) {
    return MouseRegion(
      cursor: _getRotatedCursor(),
      child: GestureDetector(
        onPanUpdate: (details) {

          final angleRad =
              widget.rotation * math.pi / 180;

          final dx = details.delta.dx;
          final dy = details.delta.dy;

          /// Project movement on rotated axis
          final projectedDelta =
              dx * math.cos(angleRad) +
                  dy * math.sin(angleRad);

          final deltaScale = isLeft
              ? -projectedDelta / GraphicLineHelper.baseSize
              : projectedDelta / GraphicLineHelper.baseSize;

          double newScale =
              widget.currentScale + deltaScale;

          /// ================= CANVAS BOUNDARY =================

          final maxWidth =
              widget.canvasWidth - widget.itemX;

          final maxScale =
              maxWidth / GraphicLineHelper.baseSize;

          newScale = newScale.clamp(0.2, maxScale);

          widget.onUpdateScale(newScale, isLeft);
        },
        child: Container(
          width: handleSize,
          height: handleSize,
          decoration: BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
}






/// ================= PAINTERS =================

class LinePainter extends CustomPainter {
  final Color color;
  final double thickness;

  LinePainter(this.color, this.thickness);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(_) => true;
}






class DashedLinePainter extends CustomPainter {
  final Color color;
  final double thickness;

  DashedLinePainter(this.color, this.thickness);

  @override
  void paint(Canvas canvas, Size size) {

    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;

    double x = 0;

    const dash = 8;
    const gap = 6;

    while (x < size.width) {

      canvas.drawLine(
        Offset(x, size.height / 2),
        Offset(x + dash, size.height / 2),
        paint,
      );

      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_) => true;
}






class ArrowLinePainter extends CustomPainter {
  final Color color;

  ArrowLinePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {

    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final y = size.height / 2;

    canvas.drawLine(
      Offset(0, y),
      Offset(size.width - 12, y),
      paint,
    );

    final path = Path()
      ..moveTo(size.width - 12, y - 6)
      ..lineTo(size.width, y)
      ..lineTo(size.width - 12, y + 6);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => true;
}






class DoubleLinePainter extends CustomPainter {
  final Color color;

  DoubleLinePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(0, size.height / 2 - 4),
      Offset(size.width, size.height / 2 - 4),
      paint,
    );

    canvas.drawLine(
      Offset(0, size.height / 2 + 4),
      Offset(size.width, size.height / 2 + 4),
      paint,
    );
  }

  @override
  bool shouldRepaint(_) => true;
}