import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../models/table_item.dart';
import 'TABLE HELP/table_popup.dart';
import 'TABLE HELP/table_resize_handles.dart';
import 'TABLE HELP/table_rotation_handle.dart';
import 'TABLE HELP/table_item_helper.dart';
import 'TABLE HELP/table_popup.dart';

class TableItemHelper {
  static OverlayEntry? _popupEntry;

  /// ================= BUILD =================
  static Widget build({
    required BuildContext context,
    required TableItem item,
    required bool selected,
    required VoidCallback onSelect,
    required VoidCallback onDelete,
    required VoidCallback onUpdate,
    required VoidCallback onDragStart,
    required Function(TableItem) onDuplicate,
    required void Function(TableItem item, bool bringToFront) onChangeLayer,
    required double canvasWidth,
    required double canvasHeight,
  }) {
    return Positioned(
      left: item.position.dx,
      top: item.position.dy,
      child: GestureDetector(
        onTap: () {
          onSelect();
          closePopup();
        },
        onDoubleTap: () {
          onSelect();
          closePopup();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showPopup(
              context: context,
              item: item,
              onDelete: onDelete,
              onUpdate: onUpdate,
              onDuplicate: onDuplicate,
              onChangeLayer: onChangeLayer,
            );
          });
        },
        onPanUpdate: item.locked
            ? null
            : (d) {
          final tableWidth = item.cols * item.cellWidth;
          final tableHeight = item.rows * item.cellHeight;

          final maxX = canvasWidth - tableWidth;
          final maxY = canvasHeight - tableHeight;

          final newPos = item.position + d.delta;

          item.position = Offset(
            newPos.dx.clamp(0.0, maxX),
            newPos.dy.clamp(0.0, maxY),
          );

          onUpdate();
        },
        child: Transform.rotate(
          angle: item.rotation * pi / 180,
          child: Stack(
            clipBehavior: Clip.none,
            children: [

              /// TABLE
              Container(
                key: item.boxKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(item.rows, (r) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(item.cols, (c) {
                        return GestureDetector(
                          onDoubleTap: () {
                            TableCellEditor.open(
                              context,
                              item,
                              r,
                              c,
                              onUpdate,
                            );
                          },
                          child: _cell(
                            width: item.cellWidths[r][c],
                            height: item.cellHeights[r][c],
                            color: item.cellBg[r][c],
                            border: item.borderColors[r][c],
                            borderWidth: item.borderWidths[r][c],
                            child: Text(
                              item.data[r][c],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: item.dataColor[r][c],
                              ),
                            ),
                          ),
                        );
                      }),
                    );
                  }),
                ),
              ),

              /// BLUE BORDER WHEN SELECTED
              if (selected)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue, width: 2),
                    ),
                  ),
                ),

              /// RESIZE HANDLES
              if (selected && item.showResizeHandles)
                TableResizeHandles(
                  item: item,
                  onUpdate: onUpdate,
                ),

              /// ROTATION HANDLE
              if (selected && !item.locked)
                Positioned(
                  bottom: -60,
                  left: (item.cols * item.cellWidth) / 2 - 24,
                  child: TableRotationHandle(
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

  /// ================= POPUP =================
  static void _showPopup({
    required BuildContext context,
    required TableItem item,
    required VoidCallback onDelete,
    required VoidCallback onUpdate,
    required Function(TableItem) onDuplicate,
    required void Function(TableItem item, bool bringToFront) onChangeLayer,
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

          /// CLICK OUTSIDE CLOSE
          Positioned.fill(
            child: GestureDetector(
              onTap: closePopup,
              behavior: HitTestBehavior.translucent,
            ),
          ),

          /// POPUP
          Positioned(
            left: offset.dx + (size.width - 100) / 2,
            top: offset.dy - 48,
            child: Material(
              color: Colors.transparent,
              child: TablePopup(
                item: item,
                onDelete: onDelete,
                onUpdate: onUpdate,
                onDuplicate: onDuplicate,
                onChangeLayer: onChangeLayer,
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

  /// ================= CELL WIDGET =================
  static Widget _cell({
    required double width,
    required double height,
    required Color color,
    required Color border,
    double borderWidth = 1.0,
    required Widget child,
  }) {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: border, width: borderWidth),
      ),
      child: child,
    );
  }
}

/// ================= COLOR PICKER =================
class _ColorPickerDialog extends StatefulWidget {
  final Color initialColor;
  const _ColorPickerDialog({required this.initialColor});

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late Color selectedColor;

  @override
  void initState() {
    selectedColor = widget.initialColor;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Pick a Color"),
      content: BlockPicker(
        pickerColor: selectedColor,
        onColorChanged: (c) => setState(() => selectedColor = c),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, selectedColor),
          child: const Text("Select"),
        ),
      ],
    );
  }
}