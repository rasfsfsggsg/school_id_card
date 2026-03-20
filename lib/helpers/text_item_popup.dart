import 'package:flutter/material.dart';
import '../../models/text_item.dart';
import '../core/navigator_key.dart';

class TextPopupMenu {
  static OverlayEntry? _entry;

  static void show({
    required Offset position,
    required TextItem item,
    VoidCallback? onDelete,
    VoidCallback? onDuplicate,
    VoidCallback? onUpdate,
  }) {
    hide();

    _entry = OverlayEntry(
      builder: (_) => Positioned(
        left: position.dx,
        top: position.dy - 10,
        child: Material(
          color: Colors.transparent,
          child: _PopupContent(
            item: item,
            onDelete: onDelete,
            onDuplicate: onDuplicate,
            onUpdate: onUpdate,
          ),
        ),
      ),
    );

    Overlay.of(navigatorKey.currentContext!).insert(_entry!);
  }

  static void hide() {
    _entry?.remove();
    _entry = null;
  }
}

class _PopupContent extends StatefulWidget {
  final TextItem item;
  final VoidCallback? onDelete;
  final VoidCallback? onDuplicate;
  final VoidCallback? onUpdate;



  const _PopupContent({
    required this.item,
    this.onDelete,
    this.onDuplicate,
    this.onUpdate,
  });

  @override
  State<_PopupContent> createState() => _PopupContentState();
}

class _PopupContentState extends State<_PopupContent> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          _item(Icons.copy, 'Copy', () {
            widget.onDuplicate?.call();
            TextPopupMenu.hide();
          }),

          _item(Icons.delete, 'Delete', () {
            widget.onDelete?.call();
            TextPopupMenu.hide();
          }),

          const Divider(),

          // 🔒 LOCK / UNLOCK
          _item(
            widget.item.locked ? Icons.lock : Icons.lock_open,
            widget.item.locked ? 'Locked' : 'Lock',
                () {
              setState(() {
                widget.item.locked = !widget.item.locked;
              });
              widget.onUpdate?.call();
            },
          ),

          // ☑ WRAP TEXT
          Row(
            children: [
              Checkbox(
                value: widget.item.wrapText,
                onChanged: widget.item.locked
                    ? null
                    : (v) {
                  setState(() {
                    widget.item.wrapText = v!;
                    if (v) {
                      widget.item.wrapWidth = 220;
                      widget.item.boxHeight = 60;
                    }
                  });
                  widget.onUpdate?.call();
                },
              ),
              const Text('Wrap text'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _item(IconData icon, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
      ),
    );
  }
}
