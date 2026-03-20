import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/table_item.dart';

class TableResizeHandles extends StatefulWidget {
  final TableItem item;
  final VoidCallback onUpdate;

  const TableResizeHandles({
    super.key,
    required this.item,
    required this.onUpdate,
  });

  @override
  State<TableResizeHandles> createState() => _TableResizeHandlesState();
}

class _TableResizeHandlesState extends State<TableResizeHandles> {
  Offset? _start;
  double? _w;
  double? _h;

  double get _dotSize =>
      widget.item.showResizeHandles ? 18 : 12;

  @override
  Widget build(BuildContext context) {
    final w = widget.item.cols * widget.item.cellWidth;
    final h = widget.item.rows * widget.item.cellHeight;

    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [

          /// TOP LEFT
          _dot(
            top: -_dotSize / 2,
            left: -_dotSize / 2,
            cursor: SystemMouseCursors.resizeUpLeftDownRight,
          ),

          /// TOP RIGHT
          _dot(
            top: -_dotSize / 2,
            left: w - _dotSize / 2,
            cursor: SystemMouseCursors.resizeUpRightDownLeft,
          ),

          /// BOTTOM LEFT
          _dot(
            top: h - _dotSize / 2,
            left: -_dotSize / 2,
            cursor: SystemMouseCursors.resizeUpRightDownLeft,
          ),

          /// BOTTOM RIGHT
          _dot(
            top: h - _dotSize / 2,
            left: w - _dotSize / 2,
            cursor: SystemMouseCursors.resizeUpLeftDownRight,
          ),
        ],
      ),
    );
  }

  Widget _dot({
    required double top,
    required double left,
    required MouseCursor cursor,
  }) {
    return Positioned(
      top: top,
      left: left,
      child: MouseRegion(
        cursor: cursor,
        child: GestureDetector(
          onPanStart: (d) {
            _start = d.globalPosition;
            _w = widget.item.cellWidth;
            _h = widget.item.cellHeight;
          },
          onPanUpdate: (d) {

            final delta = d.globalPosition - (_start ?? Offset.zero);

            widget.item.cellWidth =
                max(30, (_w ?? 60) + delta.dx / widget.item.cols);

            widget.item.cellHeight =
                max(20, (_h ?? 40) + delta.dy / widget.item.rows);

            widget.onUpdate();
          },
          child: Container(
            width: _dotSize,
            height: _dotSize,
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}