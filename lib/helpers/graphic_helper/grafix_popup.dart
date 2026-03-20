import 'package:flutter/material.dart';
import '../../models/graphic_item.dart';
import '../../panels/cate/open_ColorPicker.dart';
import '../help/image_border_popup.dart';

class GraphicPopup {
  static OverlayEntry? _popupEntry;

  /// Show popup for a graphic item
  static void show({
    required BuildContext context,
    required GraphicItem item,
    required VoidCallback onDelete,
    required VoidCallback onUpdate,
    required Function(GraphicItem) addItem,
    required String Function() generateId,
    required void Function(GraphicItem, bool bringToFront) onChangeLayer,
  }) {
    close();

    final ctx = item.boxKey.currentContext;
    if (ctx == null) return;

    final box = ctx.findRenderObject() as RenderBox;
    final bool isLine = item.type == GraphicType.line;
    final Offset globalCenter = box.localToGlobal(box.size.center(Offset.zero));
    final double itemHeight = box.size.height;

    final Offset popupPosition = Offset(
      globalCenter.dx - 130 / 2,
      isLine
          ? globalCenter.dy - itemHeight / 2 - 35
          : globalCenter.dy - itemHeight / 2 - 55,
    );

    _popupEntry = OverlayEntry(
      builder: (_) => Stack(
        children: [
          /// Close popup when clicking outside
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.deferToChild,
              onTap: () {
                close();
                item.showResizeHandles = false;
                item.showRotationHandle = false;
                onUpdate();
              },
            ),
          ),

          /// Popup content
          Positioned(
            left: popupPosition.dx,
            top: popupPosition.dy,
            child: Material(
              color: Colors.transparent,
              child: _PopupContent(
                item: item,
                onDelete: onDelete,
                onUpdate: onUpdate,
                onToggleResize: () {
                  item.showResizeHandles = !item.showResizeHandles;
                  item.showRotationHandle = false;
                  onUpdate();
                },
                onCopy: () {
                  final newItem = item.duplicate(generateId());
                  addItem(newItem);
                  onUpdate();
                },
                onChangeLayer: onChangeLayer,
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context, rootOverlay: true)!.insert(_popupEntry!);
  }

  /// Close popup
  static void close() {
    _popupEntry?.remove();
    _popupEntry = null;
  }
}

/// ================= POPUP CONTENT =================
class _PopupContent extends StatelessWidget {
  final GraphicItem item;
  final VoidCallback onDelete;
  final VoidCallback onUpdate;
  final VoidCallback onToggleResize;
  final VoidCallback onCopy;
  final void Function(GraphicItem, bool bringToFront)? onChangeLayer;

  const _PopupContent({
    required this.item,
    required this.onDelete,
    required this.onUpdate,
    required this.onToggleResize,
    required this.onCopy,
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
        boxShadow: const [BoxShadow(blurRadius: 8, color: Colors.black26)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // DELETE
          _icon(Icons.delete, () {
            onDelete();
            GraphicPopup.close();
          }),

          // LOCK/UNLOCK
          _icon(item.locked ? Icons.lock : Icons.lock_open, () {
            item.locked = !item.locked;
            onUpdate();
            GraphicPopup.close();
          }),

          // BRING TO FRONT
          _icon(Icons.vertical_align_top, () {
            onChangeLayer?.call(item, true);
            GraphicPopup.close();
          }),

          // SEND TO BACK
          _icon(Icons.vertical_align_bottom, () {
            onChangeLayer?.call(item, false);
            GraphicPopup.close();
          }),

          // COPY (not for line)
          if (item.type != GraphicType.line)
            _icon(Icons.copy, () {
              onCopy();
              GraphicPopup.close();
            }),


          // RESIZE TOGGLE
          _icon(Icons.crop_free, onToggleResize),

          _icon(Icons.rotate_90_degrees_ccw, () {
            item.showProtectIcon = !item.showProtectIcon; // ✅ sirf yahi toggle
            onUpdate();
            // GraphicPopup.close(); // ❌ yeh close hatao, nahi to resize/rotation me bhi close ho raha hai
          }),

          // COLOR PICKER (not for image)
          if (item.type != GraphicType.image)
            _icon(Icons.color_lens, () {
              CustomColorPicker.show(
                context: context,
                currentColor: item.color,
                onColorSelected: (selectedColor) {
                  item.color = selectedColor;
                  onUpdate();
                },
              );
            }),


          // 3-DOT OPTIONS (only for image, icon, shape; NOT for line)
          if (item.type != GraphicType.line && item.type != GraphicType.line)
            _icon(Icons.more_vert, () {
              final ctx = item.boxKey.currentContext;
              if (ctx == null) return;

              final box = ctx.findRenderObject() as RenderBox;
              final offset = box.localToGlobal(Offset.zero);

              const popupWidth = 320.0;
              const popupHeight = 520.0;
              final screen = MediaQuery.of(context).size;

              double leftPos = offset.dx - popupWidth - 10;
              if (leftPos < 10) leftPos = offset.dx + box.size.width + 10;

              double topPos = offset.dy + (box.size.height - popupHeight) / 2;
              topPos = topPos.clamp(10.0, screen.height - popupHeight - 10);

              late final OverlayEntry overlayEntry;

              overlayEntry = OverlayEntry(
                builder: (_) => Stack(
                  children: [
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () => overlayEntry.remove(),
                      ),
                    ),
                    Positioned(
                      left: leftPos,
                      top: topPos,
                      child: ImageBorderPopup(
                        item: item,
                        onUpdate: onUpdate,
                        onClose: () => overlayEntry.remove(),
                      ),
                    ),
                  ],
                ),
              );

              Overlay.of(context, rootOverlay: true)!.insert(overlayEntry);
            }),
        ],
      ),
    );
  }

  Widget _icon(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 18),
      ),
    );
  }
}