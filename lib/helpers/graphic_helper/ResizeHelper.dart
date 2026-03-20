import 'package:flutter/material.dart';
import '../../models/graphic_item.dart';
import 'graphic_line_helper.dart';
import 'Resize_Handles.dart';

class ResizeHelper {

  /// Build resize handles for any GraphicItem
  static Widget build({
    required GraphicItem item,
    required bool isLine,
    required double canvasWidth,
    required double canvasHeight,
    required VoidCallback onUpdate,
  }) {

    /// ================= LINE =================
    if (isLine) {

      return LineResizeHandles(
        rotation: item.rotation,
        currentScale: item.scale,

        /// important
        canvasWidth: canvasWidth,
        itemX: item.position.dx,

        onUpdateScale: (newScale, isLeft) {

          final base = GraphicLineHelper.baseSize;

          double newWidth = base * newScale;
          double oldWidth = base * item.scale;

          double diff = newWidth - oldWidth;

          double newLeft =
          isLeft ? item.position.dx - diff : item.position.dx;

          double newRight = newLeft + newWidth;

          /// ================= LEFT BOUNDARY =================
          if (newLeft < 0) {

            newLeft = 0;
            newWidth = newRight - newLeft;

            newScale = newWidth / base;
          }

          /// ================= RIGHT BOUNDARY =================
          if (newRight > canvasWidth) {

            newWidth = canvasWidth - newLeft;

            newScale = newWidth / base;
          }

          /// ================= APPLY =================
          if (isLeft) {
            item.position = Offset(newLeft, item.position.dy);
          }

          item.scale = newScale;

          onUpdate();
        },
      );
    }






    /// ================= ICON / SHAPE =================

    return ResizeHandles(
      width: item.width,
      height: item.height,
      rotation: item.rotation,

      onUpdateSize:
          (newWidth, newHeight, shiftX, shiftY, handleType) {

        newWidth = newWidth.clamp(10.0, canvasWidth);
        newHeight = newHeight.clamp(10.0, canvasHeight);

        double newX = item.position.dx;
        double newY = item.position.dy;

        final oldRight =
            item.position.dx + item.width;

        final oldBottom =
            item.position.dy + item.height;

        switch (handleType) {

          case HandleType.middleLeft:
            newX = oldRight - newWidth;
            break;

          case HandleType.middleRight:
            newX = item.position.dx;
            break;

          case HandleType.middleTop:
            newY = oldBottom - newHeight;
            break;

          case HandleType.middleBottom:
            newY = item.position.dy;
            break;

          case HandleType.topLeft:
            newX = oldRight - newWidth;
            newY = oldBottom - newHeight;
            break;

          case HandleType.topRight:
            newX = item.position.dx;
            newY = oldBottom - newHeight;
            break;

          case HandleType.bottomLeft:
            newX = oldRight - newWidth;
            newY = item.position.dy;
            break;

          case HandleType.bottomRight:
            newX = item.position.dx;
            newY = item.position.dy;
            break;
        }

        /// ================= CANVAS CLAMP =================

        newX = newX.clamp(0.0, canvasWidth - newWidth);
        newY = newY.clamp(0.0, canvasHeight - newHeight);

        /// ================= APPLY =================

        item.width = newWidth;
        item.height = newHeight;
        item.position = Offset(newX, newY);

        onUpdate();
      },
    );
  }
}