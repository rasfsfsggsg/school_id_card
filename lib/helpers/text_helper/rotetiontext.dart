import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/text_item.dart';
import '../text_item_helper.dart';

class RotationHandle extends StatefulWidget {
  final TextItem item;
  final VoidCallback? onUpdate;

  const RotationHandle({
    required this.item,
    this.onUpdate,
    super.key,
  });

  @override
  State<RotationHandle> createState() => _RotationHandleState();
}

class _RotationHandleState extends State<RotationHandle> {
  Offset? _center;
  double _startAngle = 0; // radians
  double _initialRotation = 0; // degrees

  @override
  Widget build(BuildContext context) {
    double degrees = widget.item.rotation;

    return MouseRegion(
      cursor: SystemMouseCursors.grab,
      onEnter: (_) {
        // Hide any open popups when hovering
        TextItemHelper.closePopup();
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        child: SizedBox(
          width: 48,
          height: 70,
          child: Column(
            children: [
              _buildRotationButton(),
              const SizedBox(height: 6),
              _buildRotationLabel(degrees),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRotationButton() {
    return Container(
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
    );
  }

  Widget _buildRotationLabel(double degrees) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
    );
  }

  void _onPanStart(DragStartDetails details) {
    // Hide popup immediately
    TextItemHelper.closePopup();

    final textContext = widget.item.boxKey.currentContext;
    if (textContext == null) return;

    final renderBox = textContext.findRenderObject() as RenderBox;
    final globalPosition = renderBox.localToGlobal(Offset.zero);

    _center = Offset(
      globalPosition.dx + renderBox.size.width / 2,
      globalPosition.dy + renderBox.size.height / 2,
    );

    _startAngle = (details.globalPosition - _center!).direction;
    _initialRotation = widget.item.rotation;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_center == null) return;

    final currentAngle = (details.globalPosition - _center!).direction;
    final deltaRadians = currentAngle - _startAngle;
    double newRotation = _initialRotation + deltaRadians * 180 / math.pi;

    // Snap to 15° increments if shift is pressed
    if (HardwareKeyboard.instance.isShiftPressed) {
      newRotation = (newRotation / 15).round() * 15;
    }

    setState(() {
      widget.item.rotation = newRotation;
    });

    widget.onUpdate?.call();
  }
}