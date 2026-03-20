import 'package:flutter/material.dart';
import 'package:vista_print24/helpers/QR_HELP/qr_border_popup.dart';
import '../../models/qr_item.dart';
import '../../panels/cate/open_ColorPicker.dart';

class QrPopup {
  static OverlayEntry? _popupEntry;
  static bool showResizeHandles = false;

  static void show({
    required BuildContext context,
    required QrItem item,
    required VoidCallback onDelete,
    required VoidCallback onCopy,
    required VoidCallback onUpdate,
    required VoidCallback onToggleResize,
    required void Function(QrItem item, bool bringToFront) onChangeLayer,
  }) {
    close();

    _popupEntry = OverlayEntry(
      builder: (_) => Stack(
        children: [
          /// Tap outside closes popup
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                close();
                showResizeHandles = false;
                onUpdate();
              },
            ),
          ),

          /// Popup follows QR using CompositedTransformFollower
          CompositedTransformFollower(
            link: item.layerLink,
            showWhenUnlinked: false,
            offset: Offset(
              (item.width - _PopupContent.popupWidth) / 2,
              -_PopupContent.popupHeight - 12,
            ),
            child: Material(
              color: Colors.transparent,
              child: _PopupContent(
                item: item,
                onDelete: onDelete,
                onCopy: onCopy,
                onUpdate: onUpdate,
                onToggleResize: onToggleResize,
                onChangeLayer: onChangeLayer,
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context, rootOverlay: true)!.insert(_popupEntry!);
  }

  static void close() {
    _popupEntry?.remove();
    _popupEntry = null;
  }
}

class _PopupContent extends StatefulWidget {
  static const double popupWidth = 140;
  static const double popupHeight = 36;

  final QrItem item;
  final VoidCallback onDelete;
  final VoidCallback onCopy;
  final VoidCallback onUpdate;
  final VoidCallback onToggleResize;
  final void Function(QrItem item, bool bringToFront)? onChangeLayer;

  const _PopupContent({
    required this.item,
    required this.onDelete,
    required this.onCopy,
    required this.onUpdate,
    required this.onToggleResize,
    this.onChangeLayer,
  });

  @override
  State<_PopupContent> createState() => _PopupContentState();
}

class _PopupContentState extends State<_PopupContent> {
  OverlayEntry? _moreOverlayEntry;
  final GlobalKey _moreKey = GlobalKey();

  void _showMoreMenu() {
    final RenderBox renderBox =
    _moreKey.currentContext!.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _moreOverlayEntry = OverlayEntry(
      builder: (_) => Stack(
        children: [
          /// Close dropdown when clicking outside
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _hideMoreMenu,
            ),
          ),

          /// Dropdown menu
          Positioned(
            left: offset.dx,
            top: offset.dy + size.height + 4,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _popupItem(Icons.crop_free, "Resize", () {
                      widget.onToggleResize();
                      _hideMoreMenu();
                    }),
                    _popupItem(Icons.color_lens, "Color", () async {
                      await CustomColorPicker.show(
                        context: context,
                        currentColor: widget.item.color,
                        onColorSelected: (color) {
                          widget.item.color = color;
                          widget.onUpdate();
                        },
                      );
                      _hideMoreMenu();
                    }),
                    _popupItem(Icons.border_outer, "Border", () {
                      _hideMoreMenu();

                      late OverlayEntry borderEntry;

                      borderEntry = OverlayEntry(
                        builder: (_) => Stack(
                          children: [
                            Positioned.fill(
                              child: GestureDetector(
                                onTap: () => borderEntry.remove(),
                              ),
                            ),

                            Positioned(
                              left: 200,
                              top: 200,
                              child: QrBorderPopup(
                                item: widget.item,

                                onUpdate: widget.onUpdate,
                                onClose: () => borderEntry.remove(),
                              ),
                            ),
                          ],
                        ),
                      );

                      Overlay.of(context, rootOverlay: true)!.insert(borderEntry);
                    }),
                    _popupItem(Icons.vertical_align_top, "Bring to Front", () {
                      widget.onChangeLayer?.call(widget.item, true);
                      _hideMoreMenu();
                    }),
                    _popupItem(Icons.vertical_align_bottom, "Send to Back", () {
                      widget.onChangeLayer?.call(widget.item, false);
                      _hideMoreMenu();
                    }),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context, rootOverlay: true)!.insert(_moreOverlayEntry!);
  }

  void _hideMoreMenu() {
    _moreOverlayEntry?.remove();
    _moreOverlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: _PopupContent.popupWidth,
        height: _PopupContent.popupHeight,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              blurRadius: 8,
              color: Colors.black26,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _icon(Icons.copy, widget.onCopy),
            _icon(Icons.delete, () {
              widget.onDelete();
              QrPopup.close();
            }),
            _icon(widget.item.locked ? Icons.lock : Icons.lock_open, () {
              widget.item.locked = !widget.item.locked;
              widget.onUpdate();
              QrPopup.close();
            }),
            _icon(Icons.more_vert, _showMoreMenu, key: _moreKey),
          ],
        ),
      ),
    );
  }

  Widget _icon(IconData icon, VoidCallback onTap, {Key? key}) {
    return InkWell(
      key: key,
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 18),
      ),
    );
  }

  Widget _popupItem(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      hoverColor: Colors.grey.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Row(
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _hideMoreMenu();
    super.dispose();
  }
}