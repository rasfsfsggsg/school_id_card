import 'dart:math';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/qr_item.dart';

class QrItemHelper {
  static const double _qrSize = 140;
  static const double _handleSize = 16;

  static OverlayEntry? _popupEntry;

  // ================== BUILD ==================
  static Widget build({
    required BuildContext context,
    required QrItem item,
    required bool selected,
    required VoidCallback onSelect,
    required VoidCallback onDelete,
    required VoidCallback onCopy,
    required VoidCallback onUpdate,
  }) {
    final qrSize = _qrSize * item.scale;

    return Positioned(
      left: item.position.dx,
      top: item.position.dy,
      child: GestureDetector(
        onTap: () {
          onSelect();
          _showPopup(
            context: context,
            item: item,
            onDelete: onDelete,
            onCopy: onCopy,
            onUpdate: onUpdate,
          );
        },
        onPanUpdate: item.locked
            ? null
            : (d) {
          item.position += d.delta;
          onUpdate();
        },
        child: Transform.rotate(
          angle: item.rotation,
          child: SizedBox(
            width: qrSize,
            height: qrSize,
            child: QrImageView(
              data: item.data,
              size: qrSize,
              foregroundColor: item.color,
            ),
          ),
        ),
      ),
    );
  }

  static void _showPopup({
    required BuildContext context,
    required QrItem item,
    required VoidCallback onDelete,
    required VoidCallback onCopy,
    required VoidCallback onUpdate,
  }) {
    closePopup();

    final boxContext = item.boxKey.currentContext;
    if (boxContext == null) return;

    final renderBox = boxContext.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final offset = renderBox.localToGlobal(Offset.zero);

    _popupEntry = OverlayEntry(
      builder: (overlayContext) {
        return Stack(
          children: [
            // Tap outside to close popup
            Positioned.fill(
              child: GestureDetector(
                onTap: closePopup,
                behavior: HitTestBehavior.translucent,
              ),
            ),
            // Popup with blue selection box
            Positioned(
              left: offset.dx,
              top: offset.dy,
              child: Material(
                color: Colors.transparent,
                child: _PopupContent(
                  item: item,
                  onDelete: onDelete,
                  onCopy: onCopy,
                  onUpdate: onUpdate,
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context, rootOverlay: true)!.insert(_popupEntry!);
  }

  static void closePopup() {
    _popupEntry?.remove();
    _popupEntry = null;
  }
}

// ================= POPUP CONTENT =================
class _PopupContent extends StatefulWidget {
  final QrItem item;
  final VoidCallback onDelete;
  final VoidCallback onCopy;
  final VoidCallback onUpdate;

  const _PopupContent({
    required this.item,
    required this.onDelete,
    required this.onCopy,
    required this.onUpdate,
  });

  @override
  State<_PopupContent> createState() => _PopupContentState();
}

class _PopupContentState extends State<_PopupContent> {
  bool _deleteHover = false;
  bool _copyHover = false;
  bool _lockHover = false;
  bool _resizeHover = false;
  bool _resizing = false;

  void _updateSize(DragUpdateDetails d) {
    setState(() {
      widget.item.scale = max(0.3, widget.item.scale + d.delta.dy * 0.005);
    });
    widget.onUpdate();
  }

  @override
  Widget build(BuildContext context) {
    final qrSize = QrItemHelper._qrSize * widget.item.scale;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ================= ICON ROW =================
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _icon(Icons.copy, () {
              widget.onCopy();
              QrItemHelper.closePopup();
            }, hoverSetter: (v) => setState(() => _copyHover = v), hover: _copyHover),
            _icon(Icons.delete, () {
              widget.onDelete();
              QrItemHelper.closePopup();
            }, hoverSetter: (v) => setState(() => _deleteHover = v), hover: _deleteHover),
            _icon(widget.item.locked ? Icons.lock : Icons.lock_open, () {
              widget.item.locked = !widget.item.locked;
              widget.onUpdate();
              QrItemHelper.closePopup();
            }, hoverSetter: (v) => setState(() => _lockHover = v), hover: _lockHover),
            _icon(Icons.open_with, () {
              setState(() => _resizing = !_resizing);
            }, hoverSetter: (v) => setState(() => _resizeHover = v), hover: _resizeHover),
          ],
        ),
        const SizedBox(height: 6),

        // ================= QR + BLUE BOX =================
        Stack(
          clipBehavior: Clip.none,
          children: [
            // QR first
            SizedBox(
              width: qrSize,
              height: qrSize,
              child: QrImageView(
                data: widget.item.data,
                size: qrSize,
                foregroundColor: widget.item.color,
              ),
            ),

            // Blue selection box on top
            if (_resizing)
              Container(
                width: qrSize,
                height: qrSize,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue, width: 2),
                  color: Colors.blue.withOpacity(0.1),
                ),
              ),

            // Resize handles
            if (_resizing) ...[
              _cornerHandle(top: -QrItemHelper._handleSize / 2, left: -QrItemHelper._handleSize / 2),
              _cornerHandle(top: -QrItemHelper._handleSize / 2, right: -QrItemHelper._handleSize / 2),
              _cornerHandle(bottom: -QrItemHelper._handleSize / 2, left: -QrItemHelper._handleSize / 2),
              _cornerHandle(bottom: -QrItemHelper._handleSize / 2, right: -QrItemHelper._handleSize / 2),
            ],
          ],
        ),
      ],
    );
  }

  Widget _cornerHandle({double? top, double? bottom, double? left, double? right}) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: GestureDetector(
        onPanUpdate: _updateSize,
        child: Container(
          width: QrItemHelper._handleSize,
          height: QrItemHelper._handleSize,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.blue, width: 2),
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(blurRadius: 2, color: Colors.black26, offset: Offset(1, 1))
            ],
          ),
        ),
      ),
    );
  }

  Widget _icon(IconData icon, VoidCallback onTap,
      {required Function(bool) hoverSetter, required bool hover}) {
    return MouseRegion(
      onEnter: (_) => hoverSetter(true),
      onExit: (_) => hoverSetter(false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: hover ? Colors.blueAccent.withOpacity(0.2) : Colors.white,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: hover ? Colors.white : Colors.black87),
        ),
      ),
    );
  }
}
