import 'package:flutter/material.dart';
import '../../models/graphic_item.dart';
import '../graphic_helper/Resize_Handles.dart';

class GraphicIconHelper {

  /// ================= ICON BUILD =================
  /// 🔥 Now width/height based like image
  static Widget build({
    required GraphicItem item,
  }) {
    return SizedBox(
      width: item.width,
      height: item.height,
      child: FittedBox(
        fit: BoxFit.fill,
        child: Icon(
          item.icon,
          color: item.safeColor,
        ),
      ),
    );
  }

  /// ================= RESIZE HANDLES =================
  static Widget buildResizeHandles({
    required double width,
    required double height,
    required double rotation,
    required Function(
        double newWidth,
        double newHeight,
        double shiftX,
        double shiftY,
        HandleType handleType,
        ) onUpdateSize,
  }) {
    return ResizeHandles(
      width: width,
      height: height,
      rotation: rotation,
      onUpdateSize: onUpdateSize,
    );
  }
}