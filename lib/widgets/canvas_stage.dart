import 'package:flutter/material.dart';
import '../common/canvas_orientation.dart';
import 'red_dashed_border.dart';

class CanvasStage extends StatelessWidget {
  final double widthCm;
  final double heightCm;
  final double pxPerCm;
  final bool showGrid;
  final Color backgroundColor;
  final String? backgroundImage;
  final CanvasOrientation orientation;
  final Widget child;
  final VoidCallback onRemoveBackground;

  const CanvasStage({
    super.key,
    required this.widthCm,
    required this.heightCm,
    required this.pxPerCm,
    required this.showGrid,
    required this.backgroundColor,
    required this.backgroundImage,
    required this.orientation,
    required this.child,
    required this.onRemoveBackground,
  });

  static const double _borderPadding = 10;

  @override
  Widget build(BuildContext context) {
    final widthPx = widthCm * pxPerCm;
    final heightPx = heightCm * pxPerCm;

    return Stack(
      alignment: Alignment.center,
      children: [
        /// 🔴 RED BORDER
        RedDashedBorder(
          widthPx: widthPx,
          heightPx: heightPx,
          widthCm: widthCm,
          heightCm: heightCm,
          color: Colors.red,
          strokeWidth: 2,
          dashWidth: 6,
          dashSpace: 4,
          showLabels: true,
        ),

        /// 🧱 CANVAS
        SizedBox(
          width: widthPx - 2 * _borderPadding,
          height: heightPx - 2 * _borderPadding,
          child: Padding(
            padding: const EdgeInsets.all(_borderPadding),
            child: Container(
              decoration: BoxDecoration(
                color: backgroundImage == null
                    ? backgroundColor
                    : Colors.transparent,
                image: backgroundImage != null
                    ? DecorationImage(
                  image: NetworkImage(backgroundImage!),
                  fit: BoxFit.cover,
                )
                    : null,
              ),
              child: GestureDetector(
                onDoubleTap: backgroundImage != null
                    ? onRemoveBackground
                    : null,
                child: Stack(
                  children: [
                    if (showGrid) const _GridOverlay(),
                    child,
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// ================= GRID =================
class _GridOverlay extends StatelessWidget {
  const _GridOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _GridPainter(),
        size: Size.infinite,
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black12
      ..strokeWidth = 0.5;

    const step = 20.0;

    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
