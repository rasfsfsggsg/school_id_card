import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/table_item.dart';

class TableRotationHandle extends StatefulWidget {
  final TableItem item;
  final VoidCallback onUpdate;

  const TableRotationHandle({
    super.key,
    required this.item,
    required this.onUpdate,
  });

  @override
  State<TableRotationHandle> createState() =>
      _TableRotationHandleState();
}

class _TableRotationHandleState
    extends State<TableRotationHandle> {

  Offset? _center;
  double _startAngle = 0;
  double _initialRotation = 0;
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final degrees = widget.item.rotation;

    return SizedBox(
      width: 60,
      height: 80,
      child: MouseRegion(
        cursor: _dragging
            ? SystemMouseCursors.grabbing
            : SystemMouseCursors.grab,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,

          onPanStart: (details) {
            _dragging = true;

            final boxContext =
                widget.item.boxKey.currentContext;
            if (boxContext == null) return;

            final box =
            boxContext.findRenderObject() as RenderBox;

            final global =
            box.localToGlobal(Offset.zero);

            _center = Offset(
              global.dx + box.size.width / 2,
              global.dy + box.size.height / 2,
            );

            _startAngle =
                (details.globalPosition - _center!).direction;

            _initialRotation =
                widget.item.rotation;

            setState(() {});
          },

          onPanUpdate: (details) {
            if (_center == null) return;

            final currentAngle =
                (details.globalPosition - _center!).direction;

            final deltaRadians =
                currentAngle - _startAngle;

            final deltaDegrees =
                deltaRadians * 180 / pi;

            double newRotation =
                _initialRotation + deltaDegrees;

            // SHIFT SNAP (15°)
            if (HardwareKeyboard.instance.isShiftPressed) {
              newRotation =
                  (newRotation / 15).round() * 15;
            }

            widget.item.rotation = newRotation;

            widget.onUpdate();
          },

          onPanEnd: (_) {
            _dragging = false;
            setState(() {});
          },

          child: Column(
            children: [
              Container(
                width: 38,
                height: 38,
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
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius:
                  BorderRadius.circular(6),
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