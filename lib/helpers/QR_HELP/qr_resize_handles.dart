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
  final double rotation; // degrees
  final Function(
      double newWidth,
      double newHeight,
      double shiftX,
      double shiftY,
      HandleType handleType,
      ) onUpdateSize;

  const ResizeHandles({
    Key? key,
    required this.width,
    required this.height,
    required this.rotation,
    required this.onUpdateSize,
  }) : super(key: key);

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
          // Corners
          _corner(HandleType.topLeft, -hitSize / 2, -hitSize / 2, null, null),
          _corner(HandleType.topRight, -hitSize / 2, null, -hitSize / 2, null),
          _corner(HandleType.bottomLeft, null, -hitSize / 2, null, -hitSize / 2),
          _corner(HandleType.bottomRight, null, null, -hitSize / 2, -hitSize / 2),

          // Sides
          _side(HandleType.middleLeft, widget.height / 2 - hitSize / 2, -hitSize / 2, null, null),
          _side(HandleType.middleRight, widget.height / 2 - hitSize / 2, null, -hitSize / 2, null),
          _side(HandleType.middleTop, -hitSize / 2, widget.width / 2 - hitSize / 2, null, null),
          _side(HandleType.middleBottom, null, widget.width / 2 - hitSize / 2, null, -hitSize / 2),
        ],
      ),
    );
  }

  Widget _corner(HandleType type, double? top, double? left, double? right, double? bottom) {
    return _handle(
      type,
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      isCorner: true,
      cursor: _getCornerCursor(type),
    );
  }

  Widget _side(HandleType type, double? top, double? left, double? right, double? bottom) {
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
    return _handle(type, top: top, left: left, right: right, bottom: bottom, isCorner: false, cursor: cursor);
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
                  boxShadow: const [BoxShadow(blurRadius: 6, color: Colors.black26)],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Function(DragUpdateDetails) _onDrag(HandleType type) {
    return (details) {
      final dx = details.delta.dx;
      final dy = details.delta.dy;

      // rotation in radians
      final rad = widget.rotation * math.pi / 180;
      final cosR = math.cos(rad);
      final sinR = math.sin(rad);

      // convert to rotated local dx/dy
      final localDx = dx * cosR + dy * sinR;
      final localDy = -dx * sinR + dy * cosR;

      double newWidth = widget.width;
      double newHeight = widget.height;
      double shiftX = 0;
      double shiftY = 0;

      // central logic: resize based on handle type
      switch (type) {
        case HandleType.middleLeft:
          newWidth = (widget.width - localDx).clamp(minSize, maxSize);
          shiftX = localDx;
          break;
        case HandleType.middleRight:
          newWidth = (widget.width + localDx).clamp(minSize, maxSize);
          break;
        case HandleType.middleTop:
          newHeight = (widget.height - localDy).clamp(minSize, maxSize);
          shiftY = localDy;
          break;
        case HandleType.middleBottom:
          newHeight = (widget.height + localDy).clamp(minSize, maxSize);
          break;
        case HandleType.topLeft:
          newWidth = (widget.width - localDx).clamp(minSize, maxSize);
          newHeight = (widget.height - localDy).clamp(minSize, maxSize);
          shiftX = localDx;
          shiftY = localDy;
          break;
        case HandleType.topRight:
          newWidth = (widget.width + localDx).clamp(minSize, maxSize);
          newHeight = (widget.height - localDy).clamp(minSize, maxSize);
          shiftY = localDy;
          break;
        case HandleType.bottomLeft:
          newWidth = (widget.width - localDx).clamp(minSize, maxSize);
          newHeight = (widget.height + localDy).clamp(minSize, maxSize);
          shiftX = localDx;
          break;
        case HandleType.bottomRight:
          newWidth = (widget.width + localDx).clamp(minSize, maxSize);
          newHeight = (widget.height + localDy).clamp(minSize, maxSize);
          break;
      }

      widget.onUpdateSize(newWidth, newHeight, shiftX, shiftY, type);
    };
  }

  MouseCursor _getCornerCursor(HandleType type) {
    final angle = widget.rotation % 360;
    bool swap = (angle > 45 && angle < 135) || (angle > 225 && angle < 315);

    switch (type) {
      case HandleType.topLeft:
      case HandleType.bottomRight:
        return swap ? SystemMouseCursors.resizeUpRightDownLeft : SystemMouseCursors.resizeUpLeftDownRight;
      case HandleType.topRight:
      case HandleType.bottomLeft:
        return swap ? SystemMouseCursors.resizeUpLeftDownRight : SystemMouseCursors.resizeUpRightDownLeft;
      default:
        return SystemMouseCursors.basic;
    }
  }
}