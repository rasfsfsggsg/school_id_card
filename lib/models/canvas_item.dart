import 'dart:ui';

abstract class CanvasItem {
  final String id;
  final double x;
  final double y;
  final double rotation;

  CanvasItem({
    required this.id,
    required this.x,
    required this.y,
    required this.rotation,
  });

  CanvasItem copyWith({
    double? x,
    double? y,
    double? rotation,
  });
}