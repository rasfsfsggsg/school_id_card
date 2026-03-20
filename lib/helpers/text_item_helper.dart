import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/text_item.dart';
import 'help/text_editable_box.dart';

class TextItemHelper {
  static OverlayEntry? _popupEntry;

  // ================= TEXT ITEM =================
  static Widget build({
    required BuildContext context,
    required TextItem item,
    required bool selected,
    required VoidCallback onSelect,
    required void Function(TextItem item) onExcelPopup,
    required void Function(TextItem item, bool bringToFront) onChangeLayer, // ✅ ADD THIS
    required double canvasWidth,
    required double canvasHeight,

    VoidCallback? onDelete,
    VoidCallback? onUpdate,
    VoidCallback? onDuplicate,
    double? maxWidth,
    List<TextItem>? allSelectedItems,
    required VoidCallback onDragStart, required bool isMultiSelection,
  }) {
    return Positioned(
      left: item.position.dx,
      top: item.position.dy,
      child: Focus(
        autofocus: selected,

        // ================= KEYBOARD MOVE =================
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            final double move =
            HardwareKeyboard.instance.isShiftPressed ? 10.0 : 2.0;

            Offset delta = Offset.zero;

            if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              delta = const Offset(0, -1);
            } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              delta = const Offset(0, 1);
            } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              delta = const Offset(-1, 0);
            } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
              delta = const Offset(1, 0);
            }

            if (delta != Offset.zero) {
              final List<TextItem> list =
              allSelectedItems?.isNotEmpty == true
                  ? allSelectedItems!
                  : [item];

              for (final t in list) {
                if (!t.locked) {
                  final maxX = canvasWidth - t.size.width; // canvasWidth को अपने canvas width से replace करें
                  final maxY = canvasHeight - t.size.height; // canvasHeight को replace करें

                  final newPos = t.position + delta * move;

                  t.position = Offset(
                    newPos.dx.clamp(0.0, maxX),
                    newPos.dy.clamp(0.0, maxY),
                  );
                }
              }

              onUpdate?.call();
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },

        child: GestureDetector(
          behavior: HitTestBehavior.opaque,

          // ================= TAP =================
          onTap: () {
            onSelect();
            TextItemHelper.closePopup();

            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showPopup(
                context: context,
                onChangeLayer: onChangeLayer, // ✅ ADD

                item: item,
                onDelete: onDelete,
                onDuplicate: onDuplicate,
                onExcelPopup: onExcelPopup,
                onUpdate: onUpdate,
              );
            });
          },

          // ================= DRAG =================
          onPanStart: item.locked
              ? null
              : (_) {
            TextItemHelper.closePopup();
            onDragStart();
          },
          onPanUpdate: item.locked
              ? null
              : (d) {
            final List<TextItem> list =
            allSelectedItems?.contains(item) == true
                ? allSelectedItems!
                : [item];

            for (final t in list) {
              if (!t.locked) {
                final maxX = canvasWidth - t.size.width;
                final maxY = canvasHeight - t.size.height;

                t.position = Offset(
                  (t.position.dx + d.delta.dx).clamp(0.0, maxX),
                  (t.position.dy + d.delta.dy).clamp(0.0, maxY),
                );
              }
            }
            onUpdate?.call();
          },
          onPanEnd: item.locked
              ? null
              : (_) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showPopup(
                context: context,
                onChangeLayer: onChangeLayer, // ✅ ADD THIS



                item: item,
                onDelete: onDelete,
                onDuplicate: onDuplicate,
                onExcelPopup: onExcelPopup,
                onUpdate: onUpdate,
              );
            });
          },

          // ================= UPDATED CHILD WITH ROTATION HANDLE =================
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [

              // TEXT + TRANSFORM
              Transform.rotate(
                angle: item.rotation,
                child: Transform.scale(
                  scale: item.scale,
                  child: TextEditableBox(
                    key: item.boxKey,
                    item: item,
                    selected: selected,
                    maxWidth: maxWidth,
                    onUpdate: onUpdate,
                  ),
                ),
              ),

              // ROTATION HANDLE
              if (selected && !item.locked)
                Positioned(
                  bottom: -50,
                  child: _RotationHandle(
                    item: item,
                    onUpdate: onUpdate,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void handleTextLayerChange(
      TextItem item,
      bool bringToFront,
      ValueNotifier<List<TextItem>> textItems,
      ) {
    final list = textItems.value;

    final index = list.indexWhere((e) => e.id == item.id);
    if (index == -1) return;

    list.removeAt(index);

    if (bringToFront) {
      list.add(item);       // ✅ Sabse upar
    } else {
      list.insert(0, item); // ✅ Sabse neeche
    }

    textItems.value = [...list];
  }
  // ================= POPUP =================
  static void _showPopup({
    required BuildContext context,
    required TextItem item,
    VoidCallback? onDelete,
    required void Function(TextItem, bool bringToFront) onChangeLayer, // ✅ ADD

    VoidCallback? onDuplicate,
    required void Function(TextItem) onExcelPopup,
    VoidCallback? onUpdate,
  }) {
    closePopup();

    final boxContext = item.boxKey.currentContext;
    if (boxContext == null) return;

    final renderBox = boxContext.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _popupEntry = OverlayEntry(
      builder: (_) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: closePopup,
            ),
          ),
          Positioned(
            left: offset.dx + size.width / 2 - 90,
            top: offset.dy - 50,
            child: Material(
              color: Colors.transparent,
              child: _PopupContent(
                item: item,
                onDelete: onDelete,
                onDuplicate: onDuplicate,
                onChangeLayer: onChangeLayer, // ✅ ADD

                onExcelPopup: onExcelPopup,
                onUpdate: onUpdate,
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context, rootOverlay: true)!.insert(_popupEntry!);
  }

  static void closePopup() {
    _popupEntry?.remove();
    _popupEntry = null;
  }
}

class _RotationHandle extends StatefulWidget {
  final TextItem item;
  final VoidCallback? onUpdate;

  const _RotationHandle({
    required this.item,
    this.onUpdate,
  });

  @override
  State<_RotationHandle> createState() => _RotationHandleState();
}


class _RotationHandleState extends State<_RotationHandle> {
  Offset? _center;
  double _startAngle = 0; // radians
  double _initialRotation = 0; // degrees

  @override
  Widget build(BuildContext context) {
    double degrees = widget.item.rotation;

    return MouseRegion(
      cursor: SystemMouseCursors.grab,

      // ✅ Mouse aate hi popup hide
      onEnter: (_) {
        TextItemHelper.closePopup();
      },

      child: GestureDetector(
        behavior: HitTestBehavior.opaque,

        onPanStart: (details) {
          // ✅ Rotation start hote hi popup hide
          TextItemHelper.closePopup();

          final textContext = widget.item.boxKey.currentContext;
          if (textContext == null) return;

          final textBox =
          textContext.findRenderObject() as RenderBox;

          final textGlobal =
          textBox.localToGlobal(Offset.zero);

          _center = Offset(
            textGlobal.dx + textBox.size.width / 2,
            textGlobal.dy + textBox.size.height / 2,
          );

          _startAngle =
              (details.globalPosition - _center!).direction;

          _initialRotation = widget.item.rotation;
        },

        onPanUpdate: (details) {
          if (_center == null) return;

          final currentAngle =
              (details.globalPosition - _center!).direction;

          final deltaRadians = currentAngle - _startAngle;
          const double rotationSensitivity = 0.10; // 👈 jitna chhota, utna slow
          final deltaDegrees = (deltaRadians * 180 / math.pi) * rotationSensitivity;

          double newRotation =
              _initialRotation + deltaDegrees;

          if (HardwareKeyboard.instance.isShiftPressed) {
            newRotation =
                (newRotation / 15).round() * 15;
          }

          setState(() {
            widget.item.rotation = newRotation;
          });

          widget.onUpdate?.call();
        },

        child: SizedBox(
          width: 48,
          height: 70,
          child: Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 8,
                      color: Colors.black26,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.rotate_right,
                  size: 20,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "${degrees.toStringAsFixed(0)}°",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// ================= POPUP CONTENT =================
class _PopupContent extends StatelessWidget {
  final TextItem item;
  final VoidCallback? onDelete;
  final VoidCallback? onDuplicate;
  final void Function(TextItem) onExcelPopup;
  final VoidCallback? onUpdate;
  final void Function(TextItem, bool bringToFront)? onChangeLayer; // नया callback

  const _PopupContent({
    required this.item,
    this.onDelete,
    this.onDuplicate,
    required this.onExcelPopup,
    this.onUpdate,
    this.onChangeLayer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(blurRadius: 8, color: Colors.black26),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _icon(Icons.copy, () {
            onDuplicate?.call();
            TextItemHelper.closePopup();
          }),
          _icon(Icons.delete, () {
            onDelete?.call();
            TextItemHelper.closePopup();
          }),

          // ================= WRAP TOGGLE =================
          _icon(
            item.wrapText ? Icons.wrap_text : Icons.wrap_text_outlined,
                () async {
              if (!item.wrapText) {
                // set default width/height
                item.wrapWidth = item.wrapWidth > 0 ? item.wrapWidth : 200;
                item.boxHeight = item.boxHeight > 0 ? item.boxHeight : 50;
              }
              item.wrapText = !item.wrapText;
              onUpdate?.call();
            },
          ),

          _icon(Icons.more_horiz, () {
            onExcelPopup(item);
            TextItemHelper.closePopup();
          }),
          _icon(
            item.locked ? Icons.lock : Icons.lock_open,
                () {
              item.locked = !item.locked;
              onUpdate?.call();
              TextItemHelper.closePopup();
            },
          ),

          // ================= NEW LAYER ICONS =================
          _icon(Icons.vertical_align_top, () { // Bring to Front
            onChangeLayer?.call(item, true);
            TextItemHelper.closePopup();
          }),
          _icon(Icons.vertical_align_bottom, () { // Send to Back
            onChangeLayer?.call(item, false);
            TextItemHelper.closePopup();
          }),
        ],
      ),
    );
  }

  Widget _icon(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 18),
      ),
    );
  }
}