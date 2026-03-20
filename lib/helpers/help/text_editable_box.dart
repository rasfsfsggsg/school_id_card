import 'package:flutter/material.dart';
import '../../models/text_item.dart';

class TextEditableBox extends StatefulWidget {
  final TextItem item;
  final bool selected;
  final VoidCallback? onUpdate;
  final double? maxWidth;

  const TextEditableBox({
    super.key,
    required this.item,
    required this.selected,
    this.onUpdate,
    this.maxWidth,
  });

  @override
  State<TextEditableBox> createState() => _TextEditableBoxState();
}

class _TextEditableBoxState extends State<TextEditableBox> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,

      // 🔥 DOUBLE TAP → EDIT (only if unlocked)
      onDoubleTap: () {
        if (widget.item.locked) return;

        widget.item.isEditing = true;
        widget.item.controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: widget.item.controller.text.length,
        );
        widget.onUpdate?.call();
      },

      child: Opacity(
        opacity: widget.item.opacity,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // ================= TEXT BOX =================
            Container(
              width: widget.item.wrapText ? widget.item.wrapWidth : null,
              height: widget.item.wrapText
                  ? widget.item.boxHeight
                  : (widget.item.boxHeight > 0 ? widget.item.boxHeight : null),
              padding: widget.item.backgroundPadding,
              decoration: BoxDecoration(
                color: widget.item.backgroundColor,
                gradient: widget.item.backgroundGradient,
                borderRadius: BorderRadius.circular(widget.item.backgroundRadius),
                border: widget.selected && !widget.item.isEditing
                    ? Border.all(
                  color: widget.item.locked ? Colors.red : Colors.blue,
                  width: 1.5,
                )
                    : widget.item.border
                    ? Border.all(
                  color: widget.item.borderColor,
                  width: widget.item.borderWidth,
                )
                    : null,


              ),
              child: widget.item.isEditing
                  ? _editableText(context)
                  : _displayText(),
            ),

            // ================= RESIZE HANDLES =================
            if (widget.selected && widget.item.wrapText)
              ..._buildResizeHandles(),
          ],
        ),
      ),
    );
  }

  // ================= DISPLAY MODE =================
  Widget _displayText() {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: widget.item.wrapText
            ? widget.item.wrapWidth
            : (widget.maxWidth ?? double.infinity),
      ),
      child: Text(
        widget.item.displayText,
        softWrap: true,
        maxLines: null,
        textAlign: widget.item.align,
        style: _textStyle(),
      ),
    );
  }

  // ================= EDIT MODE =================
  Widget _editableText(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: widget.item.wrapText
            ? widget.item.wrapWidth
            : (widget.maxWidth ?? double.infinity),
      ),
      child: TextField(
        controller: widget.item.controller,
        autofocus: true,
        enabled: !widget.item.locked,
        maxLines: null,
        style: _textStyle(),
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
        ),
        onChanged: (_) => widget.onUpdate?.call(),
        onEditingComplete: () => _closeEdit(),
        onTapOutside: (_) => _closeEdit(),
      ),
    );
  }

  void _closeEdit() {
    if (!widget.item.isEditing) return;
    widget.item.isEditing = false;
    widget.onUpdate?.call();
  }

  TextStyle _textStyle() {
    return TextStyle(
      fontFamily: widget.item.fontFamily,
      fontSize: widget.item.fontSize,
      fontWeight: widget.item.fontWeight,
      fontStyle: widget.item.fontStyle,
      color: widget.item.color,
      letterSpacing: widget.item.letterSpacing,
      height: widget.item.lineSpacing,
      decoration: _decoration(),
      shadows: widget.item.shadow
          ? [
        Shadow(
          offset: widget.item.shadowOffset,
          blurRadius: widget.item.shadowBlur,
          color: widget.item.shadowColor,
        )
      ]
          : null,
    );
  }

  TextDecoration _decoration() {
    if (widget.item.underline && widget.item.strike) {
      return TextDecoration.combine([
        TextDecoration.underline,
        TextDecoration.lineThrough,
      ]);
    }
    if (widget.item.underline) return TextDecoration.underline;
    if (widget.item.strike) return TextDecoration.lineThrough;
    return TextDecoration.none;
  }

  // ================= RESIZE HANDLES =================
  List<Widget> _buildResizeHandles() {
    final handleSize = 12.0;

    return [
      // Bottom-right handle
      Positioned(
        right: -handleSize / 2,
        bottom: -handleSize / 2,
        child: GestureDetector(
          onPanUpdate: (details) {
            setState(() {
              widget.item.wrapWidth =
                  (widget.item.wrapWidth + details.delta.dx)
                      .clamp(50.0, widget.maxWidth ?? double.infinity);
              widget.item.boxHeight =
                  (widget.item.boxHeight + details.delta.dy).clamp(20.0, 1000.0);
            });
            widget.onUpdate?.call();
          },
          child: _handleDot(),
        ),
      ),

      // Bottom-left handle
      Positioned(
        left: -handleSize / 2,
        bottom: -handleSize / 2,
        child: GestureDetector(
          onPanUpdate: (details) {
            setState(() {
              final newWidth = (widget.item.wrapWidth - details.delta.dx)
                  .clamp(50.0, widget.maxWidth ?? double.infinity);
              final dxChange = widget.item.wrapWidth - newWidth;
              widget.item.position += Offset(dxChange, 0);
              widget.item.wrapWidth = newWidth;

              widget.item.boxHeight =
                  (widget.item.boxHeight + details.delta.dy).clamp(20.0, 1000.0);
            });
            widget.onUpdate?.call();
          },
          child: _handleDot(),
        ),
      ),

      // Top-right handle
      Positioned(
        right: -handleSize / 2,
        top: -handleSize / 2,
        child: GestureDetector(
          onPanUpdate: (details) {
            setState(() {
              widget.item.wrapWidth =
                  (widget.item.wrapWidth + details.delta.dx)
                      .clamp(50.0, widget.maxWidth ?? double.infinity);
              final newHeight =
              (widget.item.boxHeight - details.delta.dy).clamp(20.0, 1000.0);
              widget.item.position +=
                  Offset(0, widget.item.boxHeight - newHeight);
              widget.item.boxHeight = newHeight;
            });
            widget.onUpdate?.call();
          },
          child: _handleDot(),
        ),
      ),

      // Top-left handle
      Positioned(
        left: -handleSize / 2,
        top: -handleSize / 2,
        child: GestureDetector(
          onPanUpdate: (details) {
            setState(() {
              final newWidth = (widget.item.wrapWidth - details.delta.dx)
                  .clamp(50.0, widget.maxWidth ?? double.infinity);
              final dxChange = widget.item.wrapWidth - newWidth;
              widget.item.position += Offset(dxChange, 0);
              widget.item.wrapWidth = newWidth;

              final newHeight =
              (widget.item.boxHeight - details.delta.dy).clamp(20.0, 1000.0);
              widget.item.position +=
                  Offset(0, widget.item.boxHeight - newHeight);
              widget.item.boxHeight = newHeight;
            });
            widget.onUpdate?.call();
          },
          child: _handleDot(),
        ),
      ),
    ];
  }

  Widget _handleDot() {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}
