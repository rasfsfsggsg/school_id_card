import 'dart:math' as math;
import 'package:flutter/material.dart';

enum HandleType {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  middleLeft,
  middleRight,
  middleTop,
  middleBottom,
}

class ResizeHandles extends StatefulWidget {
  final double width;
  final double height;
  final double rotation;

  final Function(
      double newWidth,
      double newHeight,
      double shiftX,
      double shiftY,
      HandleType handleType,
      ) onUpdateSize;

  const ResizeHandles({
    super.key,
    required this.width,
    required this.height,
    required this.rotation,
    required this.onUpdateSize,
  });

  @override
  State<ResizeHandles> createState() => _ResizeHandlesState();
}

class _ResizeHandlesState extends State<ResizeHandles> {
  static const double cornerSize = 14;
  static const double sideWidth = 20;
  static const double sideHeight = 8;

  static const double minSize = 20;
  static const double maxSize = 4000;

  static const double hitSize = 40;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [

          /// ===== Corners =====
          _corner(HandleType.topLeft, -hitSize/2, -hitSize/2, null, null),
          _corner(HandleType.topRight, -hitSize/2, null, -hitSize/2, null),
          _corner(HandleType.bottomLeft, null, -hitSize/2, null, -hitSize/2),
          _corner(HandleType.bottomRight, null, null, -hitSize/2, -hitSize/2),

          /// ===== Sides =====
          _side(
            HandleType.middleLeft,
            widget.height / 2 - hitSize / 2,
            -hitSize / 2,
            null,
            null,
          ),
          _side(
            HandleType.middleRight,
            widget.height / 2 - hitSize / 2,
            null,
            -hitSize / 2,
            null,
          ),
          _side(
            HandleType.middleTop,
            -hitSize / 2,
            widget.width / 2 - hitSize / 2,
            null,
            null,
          ),
          _side(
            HandleType.middleBottom,
            null,
            widget.width / 2 - hitSize / 2,
            null,
            -hitSize / 2,
          ),
        ],
      ),
    );
  }

  /// Cursor rotation support
  MouseCursor _getCornerCursor(HandleType type) {
    final angle = widget.rotation % 360;

    bool swap =
        (angle > 45 && angle < 135) ||
            (angle > 225 && angle < 315);

    switch (type) {
      case HandleType.topLeft:
      case HandleType.bottomRight:
        return swap
            ? SystemMouseCursors.resizeUpRightDownLeft
            : SystemMouseCursors.resizeUpLeftDownRight;

      case HandleType.topRight:
      case HandleType.bottomLeft:
        return swap
            ? SystemMouseCursors.resizeUpLeftDownRight
            : SystemMouseCursors.resizeUpRightDownLeft;

      default:
        return SystemMouseCursors.basic;
    }
  }

  Widget _corner(
      HandleType type,
      double? top,
      double? left,
      double? right,
      double? bottom,
      ) {
    return _handle(
      type,
      cursor: _getCornerCursor(type),
      isCorner: true,
      top: top,
      left: left,
      right: right,
      bottom: bottom,
    );
  }

  Widget _side(
      HandleType type,
      double? top,
      double? left,
      double? right,
      double? bottom,
      ) {
    MouseCursor cursor;

    switch (type) {
      case HandleType.middleLeft:
      case HandleType.middleRight:
        cursor = SystemMouseCursors.resizeLeftRight;
        break;

      case HandleType.middleTop:
      case HandleType.middleBottom:
        cursor = SystemMouseCursors.resizeUpDown;
        break;

      default:
        cursor = SystemMouseCursors.basic;
    }

    return _handle(
      type,
      cursor: cursor,
      isCorner: false,
      top: top,
      left: left,
      right: right,
      bottom: bottom,
    );
  }

  Widget _handle(
      HandleType type, {
        double? top,
        double? left,
        double? right,
        double? bottom,
        required bool isCorner,
        required MouseCursor cursor,
      }) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: MouseRegion(
        cursor: cursor,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanUpdate: _onDrag(type),
          child: SizedBox(
            width: hitSize,
            height: hitSize,
            child: Center(
              child: Container(
                width: isCorner ? cornerSize : sideWidth,
                height: isCorner ? cornerSize : sideHeight,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.blue, width: 2),
                  borderRadius: BorderRadius.circular(isCorner ? 50 : 3),
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 6,
                      color: Colors.black26,
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// ===== DRAG ENGINE =====
  Function(DragUpdateDetails) _onDrag(HandleType type) {
    return (details) {
      final dx = details.delta.dx;
      final dy = details.delta.dy;

      double width = widget.width;
      double height = widget.height;

      double shiftX = 0;
      double shiftY = 0;

      final rad = widget.rotation * math.pi / 180;

      final axisX = Offset(math.cos(rad), math.sin(rad));
      final axisY = Offset(-math.sin(rad), math.cos(rad));

      final localDx = dx * axisX.dx + dy * axisX.dy;
      final localDy = dx * axisY.dx + dy * axisY.dy;

      switch (type) {

      /// SIDES
        case HandleType.middleLeft:
          width = (width - localDx).clamp(minSize, maxSize);
          shiftX = -localDx;
          break;

        case HandleType.middleRight:
          width = (width + localDx).clamp(minSize, maxSize);
          break;

        case HandleType.middleTop:
          height = (height - localDy).clamp(minSize, maxSize);
          shiftY = -localDy;
          break;

        case HandleType.middleBottom:
          height = (height + localDy).clamp(minSize, maxSize);
          break;

      /// CORNERS
        case HandleType.topLeft:
          width = (width - dx).clamp(minSize, maxSize);
          height = (height - dy).clamp(minSize, maxSize);
          shiftX = -dx;
          shiftY = -dy;
          break;

        case HandleType.topRight:
          width = (width + dx).clamp(minSize, maxSize);
          height = (height - dy).clamp(minSize, maxSize);
          shiftY = -dy;
          break;

        case HandleType.bottomLeft:
          width = (width - dx).clamp(minSize, maxSize);
          height = (height + dy).clamp(minSize, maxSize);
          shiftX = -dx;
          break;

        case HandleType.bottomRight:
          width = (width + dx).clamp(minSize, maxSize);
          height = (height + dy).clamp(minSize, maxSize);
          break;
      }

      widget.onUpdateSize(
        width,
        height,
        shiftX,
        shiftY,
        type,
      );
    };
  }
}