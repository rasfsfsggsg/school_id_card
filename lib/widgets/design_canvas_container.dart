import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../common/canvas_orientation.dart';
import '../helpers/graphic_helper/graphic_line_helper.dart';
import '../models/graphic_item.dart';
import '../models/table_item.dart';
import '../models/text_item.dart';
import '../models/qr_item.dart';

class DesignCanvasContainer extends StatefulWidget {
  final Widget child;
  final Color backgroundColor;
  final CanvasOrientation orientation;
  final double width;
  final double height;
  final double zoom;

  final List<TextItem> allTextItems;
  final List<TextItem> selectedTextItems;
  final List<TableItem> allTableItems;
  final List<TableItem> selectedTableItems;
  final List<GraphicItem> allGraphicItems;
  final List<GraphicItem> selectedGraphicItems;
  final List<QrItem> allQrItems;
  final List<QrItem> selectedQrItems;

  final VoidCallback? onTapOutside;
  final VoidCallback? onUpdate;

  const DesignCanvasContainer({
    super.key,
    required this.child,
    required this.backgroundColor,
    required this.allGraphicItems,
    required this.selectedGraphicItems,
    required this.allTableItems,
    required this.selectedTableItems,
    required this.orientation,
    required this.width,
    required this.height,
    required this.zoom,
    required this.allTextItems,
    required this.selectedTextItems,
    required this.allQrItems,
    required this.selectedQrItems,
    this.onTapOutside,
    this.onUpdate,
    required bool showBlueBorder,
    required ValueNotifier<double> imageScale,
    required ValueNotifier<Offset> imagePosition,
  });

  @override
  State<DesignCanvasContainer> createState() => _DesignCanvasContainerState();
}

class _DesignCanvasContainerState extends State<DesignCanvasContainer> {
  Rect? dragRect; // Exact rectangle being dragged
  Offset? dragStart;
  bool isDraggingSelection = false;
  Offset? dragItemStart;

  final FocusNode _focusNode = FocusNode();
  static const double _minSelectionThickness = 23.0; // Fixed thickness for thin lines

  bool get _isGroupActive =>
      widget.selectedTextItems.length +
          widget.selectedQrItems.length +
          widget.selectedTableItems.length +
          widget.selectedGraphicItems.length >
          1;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Offset _toCanvas(Offset local) => local / widget.zoom;

  Rect _normalize(Rect r) {
    return Rect.fromLTRB(
      min(r.left, r.right),
      min(r.top, r.bottom),
      max(r.left, r.right),
      max(r.top, r.bottom),
    );
  }

  /// ===================== Arrow Key Movement =====================
  void _handleArrow(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    if (widget.selectedTextItems.isEmpty &&
        widget.selectedQrItems.isEmpty &&
        widget.selectedTableItems.isEmpty &&
        widget.selectedGraphicItems.isEmpty) return;

    Offset delta = Offset.zero;
    if (event.logicalKey == LogicalKeyboardKey.arrowUp)
      delta = const Offset(0, -1);
    if (event.logicalKey == LogicalKeyboardKey.arrowDown)
      delta = const Offset(0, 1);
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft)
      delta = const Offset(-1, 0);
    if (event.logicalKey == LogicalKeyboardKey.arrowRight)
      delta = const Offset(1, 0);

    if (delta == Offset.zero) return;

    final move = HardwareKeyboard.instance.isShiftPressed ? 10.0 : 2.0;

    void moveItem(dynamic item, double maxX, double maxY) {
      final newPos = item.position + delta * move;
      item.position =
          Offset(newPos.dx.clamp(0.0, maxX), newPos.dy.clamp(0.0, maxY));
    }

    for (final t in widget.selectedTextItems)
      if (!t.locked) moveItem(
          t, widget.width - t.size.width, widget.height - t.size.height);
    for (final q in widget.selectedQrItems)
      if (!q.locked) moveItem(
          q, widget.width - q.width, widget.height - q.height);
    for (final table in widget.selectedTableItems)
      if (!table.locked) table.position += delta * move;
    for (final g in widget.selectedGraphicItems)
      if (!g.locked) g.position += delta * move;

    widget.onUpdate?.call();
    setState(() {});
  }

  /// ===================== Select Items Inside Rect =====================
  void _selectByRect(Rect rect) {
    final norm = _normalize(rect);

    final selectedTexts = widget.allTextItems.where((t) {
      if (t.locked) return false;
      final r = Rect.fromLTWH(
          t.position.dx, t.position.dy, t.size.width, t.size.height);
      return norm.overlaps(r);
    }).toList();

    final selectedQrs = widget.allQrItems.where((q) {
      if (q.locked) return false;
      final r = Rect.fromLTWH(q.position.dx, q.position.dy, q.width, q.height);
      return norm.overlaps(r);
    }).toList();

    final selectedTables = widget.allTableItems.where((t) {
      if (t.locked) return false;
      final width = t.cols * t.cellWidth;
      final height = t.rows * t.cellHeight;
      final r = Rect.fromLTWH(t.position.dx, t.position.dy, width, height);
      return norm.overlaps(r);
    }).toList();

    final selectedGraphics = widget.allGraphicItems.where((g) {
      if (g.locked) return false;
      double width;
      double height;

      if (_isLineType(g)) {

        width = GraphicLineHelper.baseSize * g.scale;
        height = _minSelectionThickness;

      } else {

        width = g.width;
        height = g.height;
      }
      final r = Rect.fromLTWH(g.position.dx, g.position.dy, width, height);
      return norm.overlaps(r);
    }).toList();

    if (!HardwareKeyboard.instance.isShiftPressed) {
      widget.selectedTextItems.clear();
      widget.selectedQrItems.clear();
      widget.selectedTableItems.clear();
      widget.selectedGraphicItems.clear();
    }

    widget.selectedTextItems.addAll(selectedTexts);
    widget.selectedQrItems.addAll(selectedQrs);
    widget.selectedTableItems.addAll(selectedTables);
    widget.selectedGraphicItems.addAll(selectedGraphics);

    widget.onUpdate?.call();
    setState(() {});
  }

  /// ===================== Clear Selection =====================
  void _clearSelection() {
    if (widget.selectedTextItems.isNotEmpty ||
        widget.selectedQrItems.isNotEmpty ||
        widget.selectedTableItems.isNotEmpty ||
        widget.selectedGraphicItems.isNotEmpty) {
      widget.selectedTextItems.clear();
      widget.selectedQrItems.clear();
      widget.selectedTableItems.clear();
      widget.selectedGraphicItems.clear();

      widget.onTapOutside?.call();
      setState(() {});
    }
  }

  /// ===================== Selection Bounding Box =====================
  Rect? _getSelectionBounds() {
    final allRects = <Rect>[];

    for (final t in widget.selectedTextItems)
      allRects.add(Rect.fromLTWH(
          t.position.dx, t.position.dy, t.size.width, t.size.height));
    for (final t in widget.selectedTableItems)
      allRects.add(Rect.fromLTWH(
          t.position.dx, t.position.dy, t.cols * t.cellWidth,
          t.rows * t.cellHeight));
    for (final q in widget.selectedQrItems)
      allRects.add(
          Rect.fromLTWH(q.position.dx, q.position.dy, q.width, q.height));
    for (final g in widget.selectedGraphicItems) {

      double width;
      double height;

      if (_isLineType(g)) {

        width = GraphicLineHelper.baseSize * g.scale;
        height = _minSelectionThickness;

      } else {

        width = g.width;
        height = g.height;
      }

      allRects.add(
        Rect.fromLTWH(
          g.position.dx,
          g.position.dy,
          width,
          height,
        ),
      );
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

  bool _isInsideSelection(Offset pos) {
    final bounds = _getSelectionBounds();
    if (bounds == null) return false;
    return bounds.contains(pos);
  }

  Rect _scaleRect(Rect r) =>
      Rect.fromLTRB(
          r.left * widget.zoom, r.top * widget.zoom, r.right * widget.zoom,
          r.bottom * widget.zoom);

  bool _isLineType(GraphicItem g) {
    return g.type == GraphicType.line ||
        g.type == GraphicType.thickLine ||
        g.type == GraphicType.dashedLine ||
        g.type == GraphicType.arrowLine ||
        g.type == GraphicType.doubleLine;
  }

  @override
  Widget build(BuildContext context) {
    final selectionBounds = _getSelectionBounds();

    return Focus(
      autofocus: true,
      focusNode: _focusNode,
      onKeyEvent: (node, event) {
        _handleArrow(event);
        return KeyEventResult.ignored;
      },
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (event) {
          final pos = _toCanvas(event.localPosition);
          if (event.kind == PointerDeviceKind.mouse) {
            if (event.buttons == kPrimaryMouseButton &&
                !_isInsideSelection(pos)) {
              if (!HardwareKeyboard.instance.isShiftPressed) _clearSelection();
            }
            if (event.buttons == kSecondaryMouseButton) _clearSelection();
          }
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (details) {
            _focusNode.requestFocus();
            final canvasPos = _toCanvas(details.localPosition);
            if (_isInsideSelection(canvasPos)) {
              dragItemStart = canvasPos;
            } else {
              isDraggingSelection = true;
              dragStart = canvasPos;
              dragRect = Rect.fromPoints(canvasPos, canvasPos);
            }
            setState(() {});
          },
          onPanUpdate: (details) {
            final canvasPos = _toCanvas(details.localPosition);

            // Move items if dragging selection
            if (dragItemStart != null) {
              final delta = canvasPos - dragItemStart!;
              final bounds = _getSelectionBounds();
              if (bounds == null) return;

              double dx = delta.dx;
              double dy = delta.dy;
              if (bounds.left + dx < 0) dx = -bounds.left;
              if (bounds.top + dy < 0) dy = -bounds.top;
              if (bounds.right + dx > widget.width)
                dx = widget.width - bounds.right;
              if (bounds.bottom + dy > widget.height)
                dy = widget.height - bounds.bottom;

              final finalDelta = Offset(dx, dy);

              for (var t in widget.selectedTextItems)
                if (!t.locked) t.position += finalDelta;
              for (var table in widget.selectedTableItems)
                if (!table.locked) table.position += finalDelta;
              for (var q in widget.selectedQrItems)
                if (!q.locked) q.position += finalDelta;
              for (var g in widget.selectedGraphicItems)
                if (!g.locked) g.position += finalDelta;

              dragItemStart = canvasPos;
              widget.onUpdate?.call();
              setState(() {});
              return;
            }

            // Update drag rectangle while drawing
            if (isDraggingSelection && dragStart != null) {
              dragRect = Rect.fromPoints(dragStart!, canvasPos);
              setState(() {});
            }
          },
          onPanEnd: (details) {
            dragItemStart = null;

            if (isDraggingSelection && dragRect != null) {
              _selectByRect(dragRect!);
              dragRect = null;
              dragStart = null;
              isDraggingSelection = false;
            }
          },
          child: Container(
            width: widget.width,
            height: widget.height,
            color: widget.backgroundColor,
            child: Stack(
              children: [
                Transform.scale(
                  scale: widget.zoom,
                  alignment: Alignment.topLeft,
                  child: IgnorePointer(
                    ignoring: _isGroupActive,
                    child: SizedBox(width: widget.width,
                        height: widget.height,
                        child: widget.child),
                  ),
                ),

                // Temporary drag rectangle
                if (isDraggingSelection && dragRect != null)
                  Positioned.fromRect(
                    rect: _scaleRect(dragRect!),
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.25),
                          border: Border.all(color: Colors.blue, width: 1),
                        ),
                      ),
                    ),
                  ),

                // Bounding box for selected items
                if (!isDraggingSelection && selectionBounds != null)
                  Positioned.fromRect(
                    rect: _scaleRect(selectionBounds),
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.15),
                          border: Border.all(color: Colors.blue, width: 1.5),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}