import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/text_item.dart';
import '../models/table_item.dart';
import '../models/graphic_item.dart';
import '../models/qr_item.dart';

class DesignCanvasHelper {

  static Rect normalize(Rect r) {
    return Rect.fromLTRB(
      min(r.left, r.right),
      min(r.top, r.bottom),
      max(r.left, r.right),
      max(r.top, r.bottom),
    );
  }


  static void handleArrow({
    required KeyEvent event,
    required List<TextItem> selectedTextItems,
    required List<QrItem> selectedQrItems,
    required List<TableItem> selectedTableItems,
    required List<GraphicItem> selectedGraphicItems,
    required double canvasWidth,
    required double canvasHeight,
  }) {

    if (event is! KeyDownEvent) return;

    Offset delta = Offset.zero;

    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      delta = const Offset(0, -1);
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      delta = const Offset(0, 1);
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      delta = const Offset(-1, 0);
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      delta = const Offset(1, 0);
    }

    if (delta == Offset.zero) return;

    final move =
    HardwareKeyboard.instance.isShiftPressed ? 10.0 : 2.0;

    // TEXT
    for (final item in selectedTextItems) {
      if (item.locked) continue;

      final maxX = canvasWidth - item.size.width;
      final maxY = canvasHeight - item.size.height;

      final newPos = item.position + delta * move;

      item.position = Offset(
        newPos.dx.clamp(0.0, maxX),
        newPos.dy.clamp(0.0, maxY),
      );
    }

    // QR
    for (final qr in selectedQrItems) {
      if (qr.locked) continue;

      final maxX = canvasWidth - qr.width;
      final maxY = canvasHeight - qr.height;

      final newPos = qr.position + delta * move;

      qr.position = Offset(
        newPos.dx.clamp(0.0, maxX),
        newPos.dy.clamp(0.0, maxY),
      );
    }

    // TABLE
    for (final table in selectedTableItems) {
      if (!table.locked) {
        table.position += delta * move;
      }
    }

    // GRAPHIC
    for (final g in selectedGraphicItems) {
      if (g.locked) continue;

      const baseSize = 100.0;

      final width = baseSize * g.scale;
      final height = baseSize * g.scale;

      final maxX = canvasWidth - width;
      final maxY = canvasHeight - height;

      final newPos = g.position + delta * move;

      g.position = Offset(
        newPos.dx.clamp(0.0, maxX),
        newPos.dy.clamp(0.0, maxY),
      );
    }
  }

  // =========================================================
  // GROUP BOUNDS
  // =========================================================

  static Rect? getSelectionBounds({
    required List<TextItem> texts,
    required List<QrItem> qrs,
    required List<TableItem> tables,
    required List<GraphicItem> graphics,
  }) {

    final allRects = <Rect>[];

    for (final t in texts) {
      allRects.add(Rect.fromLTWH(
        t.position.dx,
        t.position.dy,
        t.size.width,
        t.size.height,
      ));
    }

    for (final q in qrs) {
      allRects.add(Rect.fromLTWH(
        q.position.dx,
        q.position.dy,
        q.width,
        q.height,
      ));
    }

    for (final t in tables) {

      final width = t.cols * t.cellWidth;
      final height = t.rows * t.cellHeight;

      allRects.add(Rect.fromLTWH(
        t.position.dx,
        t.position.dy,
        width,
        height,
      ));
    }

    for (final g in graphics) {

      const baseSize = 100.0;

      final width = baseSize * g.scale;
      final height = baseSize * g.scale;

      allRects.add(Rect.fromLTWH(
        g.position.dx,
        g.position.dy,
        width,
        height,
      ));
    }

    if (allRects.isEmpty) return null;

    double left = allRects.first.left;
    double top = allRects.first.top;
    double right = allRects.first.right;
    double bottom = allRects.first.bottom;

    for (final r in allRects) {
      left = min(left, r.left);
      top = min(top, r.top);
      right = max(right, r.right);
      bottom = max(bottom, r.bottom);
    }

    return Rect.fromLTRB(left, top, right, bottom);
  }
}