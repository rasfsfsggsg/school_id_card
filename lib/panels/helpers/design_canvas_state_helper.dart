import 'package:flutter/material.dart';

import '../../common/canvas_side.dart';
import '../../models/graphic_item.dart' show GraphicItem;
import '../../models/qr_item.dart';
import '../../models/table_item.dart';
import '../../models/text_item.dart';
import 'design_canvas_helpers.dart';

class DesignCanvasStateHelper {
  /// ================= CURRENT SIDE DATA =================

  static ValueNotifier<List<TextItem>> currentText({
    required ValueNotifier<CanvasSide> canvasSide,
    required ValueNotifier<List<TextItem>> front,
    required ValueNotifier<List<TextItem>> back,
  }) {
    return DesignCanvasHelper.currentText(
      canvasSide: canvasSide,
      front: front,
      back: back,
    );
  }

  static ValueNotifier<List<GraphicItem>> currentGraphics({
    required ValueNotifier<CanvasSide> canvasSide,
    required ValueNotifier<List<GraphicItem>> front,
    required ValueNotifier<List<GraphicItem>> back,
  }) {
    return DesignCanvasHelper.currentGraphics(
      canvasSide: canvasSide,
      front: front,
      back: back,
    );
  }

  static ValueNotifier<List<QrItem>> currentQrs({
    required ValueNotifier<CanvasSide> canvasSide,
    required ValueNotifier<List<QrItem>> front,
    required ValueNotifier<List<QrItem>> back,
  }) {
    return DesignCanvasHelper.currentQrs(
      canvasSide: canvasSide,
      front: front,
      back: back,
    );
  }

  static ValueNotifier<List<TableItem>> currentTables({
    required ValueNotifier<CanvasSide> canvasSide,
    required ValueNotifier<List<TableItem>> front,
    required ValueNotifier<List<TableItem>> back,
  }) {
    return DesignCanvasHelper.currentTables(
      canvasSide: canvasSide,
      front: front,
      back: back,
    );
  }

  static ValueNotifier<Color> currentBg({
    required ValueNotifier<CanvasSide> canvasSide,
    required ValueNotifier<Color> front,
    required ValueNotifier<Color> back,
  }) {
    return DesignCanvasHelper.currentBg(
      canvasSide: canvasSide,
      front: front,
      back: back,
    );
  }

  static ValueNotifier<String?> currentImage({
    required ValueNotifier<CanvasSide> canvasSide,
    required ValueNotifier<String?> front,
    required ValueNotifier<String?> back,
  }) {
    return DesignCanvasHelper.currentImage(
          canvasSide: canvasSide,
          front: front,
          back: back,
        ) ??
        ValueNotifier<String?>(null);
  }

  static ValueNotifier<double> currentImageScale({
    required ValueNotifier<CanvasSide> canvasSide,
    required ValueNotifier<double> front,
    required ValueNotifier<double> back,
  }) {
    return canvasSide.value == CanvasSide.front ? front : back;
  }

  static ValueNotifier<Offset> currentImagePosition({
    required ValueNotifier<CanvasSide> canvasSide,
    required ValueNotifier<Offset> front,
    required ValueNotifier<Offset> back,
  }) {
    return canvasSide.value == CanvasSide.front ? front : back;
  }

  /// ================= SELECTION HELPERS =================

  static TextItem? selectedText({
    required String? selectedTextId,
    required ValueNotifier<List<TextItem>> textItems,
  }) {
    try {
      return textItems.value.firstWhere((e) => e.id == selectedTextId);
    } catch (_) {
      return null;
    }
  }

  static void clearAllSelections({required VoidCallback onClear}) {
    onClear();
  }
}
