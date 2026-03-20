import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../common/canvas_orientation.dart';
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

  // ✅ NEW QR SUPPORT
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
  State<DesignCanvasContainer> createState() =>
      _DesignCanvasContainerState();
}

class _DesignCanvasContainerState
    extends State<DesignCanvasContainer> {
  Rect? selectionRect;
  Offset? dragStart;
  bool isDraggingSelection = false;

  Offset? dragItemStart;

  final FocusNode _focusNode = FocusNode();

  bool get _isGroupActive =>
      widget.selectedTextItems.length +
          widget.selectedQrItems.length +
          widget.selectedTableItems.length +
          widget.selectedGraphicItems.length > 1;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Offset _toCanvas(Offset local) => local / widget.zoom;

  Rect _normalize(Rect r) {
    return Rect.fromLTRB(
      r.left < r.right ? r.left : r.right,
      r.top < r.bottom ? r.top : r.bottom,
      r.left > r.right ? r.left : r.right,
      r.top > r.bottom ? r.top : r.bottom,
    );
  }

  // =========================================================
  // 🔥 ARROW KEY MOVE (TEXT + QR)
  // =========================================================
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

    final move =
    HardwareKeyboard.instance.isShiftPressed ? 10.0 : 2.0;

    // TEXT MOVE
    for (final item in widget.selectedTextItems) {
      if (!item.locked) {
        final maxX = widget.width - item.size.width;
        final maxY = widget.height - item.size.height;

        final newPos = item.position + delta * move;

        item.position = Offset(
          newPos.dx.clamp(0.0, maxX),
          newPos.dy.clamp(0.0, maxY),
        );
      }
    }

    // QR MOVE
    for (final qr in widget.selectedQrItems) {
      if (!qr.locked) {
        final maxX = widget.width - qr.width;
        final maxY = widget.height - qr.height;

        final newPos = qr.position + delta * move;

        qr.position = Offset(
          newPos.dx.clamp(0.0, maxX),
          newPos.dy.clamp(0.0, maxY),
        );
      }
    }

    // TABLE MOVE
    for (final table in widget.selectedTableItems) {
      if (!table.locked) {
        table.position += delta * move;
      }
    }

    // ✅ GRAPHIC MOVE
    for (final g in widget.selectedGraphicItems) {
      if (!g.locked) {
        const baseSize = 100.0;
        final width = baseSize * g.scale;
        final height = baseSize * g.scale;

        final maxX = widget.width - width;
        final maxY = widget.height - height;

        final newPos = g.position + delta * move;

        g.position = Offset(
          newPos.dx.clamp(0.0, maxX),
          newPos.dy.clamp(0.0, maxY),
        );
      }
    }

    widget.onUpdate?.call();
    setState(() {});
  }

  // =========================================================
  // 🔥 DRAG SELECTION (TEXT + QR)
  // =========================================================
  void _selectByRect(Rect rect) {
    final norm = _normalize(rect);

    // TEXT
    final selectedTexts = widget.allTextItems.where((t) {
      if (t.locked) return false;

      final r = Rect.fromLTWH(
        t.position.dx,
        t.position.dy,
        t.size.width,
        t.size.height,
      );

      return norm.contains(r.topLeft) && norm.contains(r.bottomRight);
    }).toList();

    // QR
    final selectedQrs = widget.allQrItems.where((q) {
      if (q.locked) return false;

      final r = Rect.fromLTWH(
        q.position.dx,
        q.position.dy,
        q.width,
        q.height,
      );

      return norm.contains(r.topLeft) && norm.contains(r.bottomRight);
    }).toList();

    // TABLE
    final selectedTables = widget.allTableItems.where((t) {
      if (t.locked) return false;

      final width = t.cols * t.cellWidth;
      final height = t.rows * t.cellHeight;

      final r = Rect.fromLTWH(
        t.position.dx,
        t.position.dy,
        width,
        height,
      );

      return norm.contains(r.topLeft) && norm.contains(r.bottomRight);
    }).toList();

    // GRAPHIC
    final selectedGraphics = widget.allGraphicItems.where((g) {
      if (g.locked) return false;

      const baseSize = 100.0;

      final width = baseSize * g.scale;
      final height = baseSize * g.scale;

      final r = Rect.fromLTWH(
        g.position.dx,
        g.position.dy,
        width,
        height,
      );

      return norm.contains(r.topLeft) && norm.contains(r.bottomRight);
    }).toList();

    final shiftPressed = HardwareKeyboard.instance.isShiftPressed;

    if (!shiftPressed) {
      widget.selectedTextItems.clear();
      widget.selectedQrItems.clear();
      widget.selectedTableItems.clear();
      widget.selectedGraphicItems.clear();
    }

    widget.selectedTextItems.addAll(selectedTexts);
    widget.selectedQrItems.addAll(selectedQrs);
    widget.selectedTableItems.addAll(selectedTables);
    widget.selectedGraphicItems.addAll(selectedGraphics);

    selectionRect = null;

    widget.onUpdate?.call();
    setState(() {});
  }

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

  // =========================================================
  // 🔥 GROUP BOUNDING BOX (TEXT + QR)
  // =========================================================
  Rect? _getSelectionBounds() {
    if (widget.selectedTextItems.isEmpty &&
        widget.selectedQrItems.isEmpty &&
        widget.selectedTableItems.isEmpty &&
        widget.selectedGraphicItems.isEmpty) {
      return null;
    }

    final allRects = <Rect>[];

    for (final t in widget.selectedTextItems) {
      allRects.add(Rect.fromLTWH(
        t.position.dx,
        t.position.dy,
        t.size.width,
        t.size.height,
      ));
    }

    for (final t in widget.selectedTableItems) {
      final width = t.cols * t.cellWidth;
      final height = t.rows * t.cellHeight;

      allRects.add(Rect.fromLTWH(
        t.position.dx,
        t.position.dy,
        width,
        height,
      ));
    }

    for (final q in widget.selectedQrItems) {
      allRects.add(Rect.fromLTWH(
        q.position.dx,
        q.position.dy,
        q.width,
        q.height,
      ));
    }

    for (final g in widget.selectedGraphicItems) {
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

  // =========================================================
  // 🔥 BUILD
  // =========================================================
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
            if (event.buttons == kPrimaryMouseButton) {
              if (_isInsideSelection(pos)) {
                return;
              }

              if (!HardwareKeyboard.instance.isShiftPressed) {
                _clearSelection();
              }
            }

            if (event.buttons == kSecondaryMouseButton) {
              _clearSelection();
            }
          }
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,

          // =========================
          // PAN START
          // =========================
          onPanStart: (details) {
            _focusNode.requestFocus();

            final screenPos = details.localPosition;
            final canvasPos = _toCanvas(screenPos);

            if (_isInsideSelection(canvasPos)) {
              dragItemStart = canvasPos;
            } else {
              isDraggingSelection = true;
              dragStart = screenPos;
              selectionRect = Rect.fromPoints(screenPos, screenPos);
            }

            setState(() {});
          },

          // =========================
          // PAN UPDATE
          // =========================
          onPanUpdate: (details) {
            final screenPos = details.localPosition;
            final canvasPos = _toCanvas(screenPos);

            // MOVE SELECTED ITEMS
            if (dragItemStart != null) {
              final delta = canvasPos - dragItemStart!;

              final bounds = _getSelectionBounds();
              if (bounds == null) return;

              double dx = delta.dx;
              double dy = delta.dy;

              if (bounds.left + dx < 0) dx = -bounds.left;
              if (bounds.top + dy < 0) dy = -bounds.top;
              if (bounds.right + dx > widget.width) {
                dx = widget.width - bounds.right;
              }
              if (bounds.bottom + dy > widget.height) {
                dy = widget.height - bounds.bottom;
              }

              final finalDelta = Offset(dx, dy);

              for (var t in widget.selectedTextItems) {
                if (!t.locked) t.position += finalDelta;
              }

              for (var table in widget.selectedTableItems) {
                if (!table.locked) table.position += finalDelta;
              }

              for (var q in widget.selectedQrItems) {
                if (!q.locked) q.position += finalDelta;
              }

              for (var g in widget.selectedGraphicItems) {
                if (!g.locked) g.position += finalDelta;
              }

              dragItemStart = canvasPos;

              widget.onUpdate?.call();
              setState(() {});
              return;
            }

            // DRAG SELECTION RECT
            if (isDraggingSelection && dragStart != null) {
              selectionRect = Rect.fromPoints(dragStart!, screenPos);
              setState(() {});
            }
          },

          // =========================
          // PAN END
          // =========================
          onPanEnd: (details) {
            dragItemStart = null;

            if (isDraggingSelection && selectionRect != null) {
              final r = _normalize(selectionRect!);

              // SCREEN → CANVAS CONVERT
              final canvasRect = Rect.fromLTRB(
                r.left / widget.zoom,
                r.top / widget.zoom,
                r.right / widget.zoom,
                r.bottom / widget.zoom,
              );

              _selectByRect(canvasRect);

              selectionRect = null;
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

                // =========================
                // CANVAS CONTENT
                // =========================
                Transform.scale(
                  scale: widget.zoom,
                  alignment: Alignment.topLeft,
                  child: IgnorePointer(
                    ignoring: _isGroupActive,
                    child: SizedBox(
                      width: widget.width,
                      height: widget.height,
                      child: widget.child,
                    ),
                  ),
                ),

                // =========================
                // GROUP SELECTION BOX
                // =========================
                if (selectionBounds != null)
                  Positioned.fromRect(
                    rect: _scaleRect(selectionBounds),
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.15),
                          border: Border.all(
                            color: Colors.blue,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),

                // =========================
                // DRAG SELECTION RECT
                // =========================
                if (selectionRect != null)
                  Positioned.fromRect(
                    rect: _normalize(selectionRect!),
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.25),
                          border: Border.all(
                            color: Colors.blue,
                            width: 1,
                          ),
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

  Rect _scaleRect(Rect r) {
    return Rect.fromLTRB(
      r.left * widget.zoom,
      r.top * widget.zoom,
      r.right * widget.zoom,
      r.bottom * widget.zoom,
    );
  }
}