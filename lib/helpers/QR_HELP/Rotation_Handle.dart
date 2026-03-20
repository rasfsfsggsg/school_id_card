import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/qr_item.dart';

class QrRotationHandle extends StatefulWidget {
  final QrItem item;
  final VoidCallback? onUpdate;

  // 👇 NEW CALLBACKS
  final VoidCallback? onRotationStart;
  final VoidCallback? onRotationEnd;

  const QrRotationHandle({
    Key? key,
    required this.item,
    this.onUpdate,
    this.onRotationStart,
    this.onRotationEnd,
  }) : super(key: key);

  @override
  State<QrRotationHandle> createState() => _QrRotationHandleState();
}

class _QrRotationHandleState extends State<QrRotationHandle> {
  Offset? _center;
  double _startAngle = 0;
  double _initialRotation = 0;
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    double degrees = widget.item.rotation;

    return MouseRegion(
      cursor:
      _dragging ? SystemMouseCursors.grabbing : SystemMouseCursors.grab,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,

        // ================= ROTATION START =================
        onPanStart: (details) {
          final boxContext = widget.item.boxKey.currentContext;
          if (boxContext == null) return;

          final box = boxContext.findRenderObject() as RenderBox;
          final global = box.localToGlobal(Offset.zero);

          _center = Offset(
            global.dx + box.size.width / 2,
            global.dy + box.size.height / 2,
          );

          _startAngle = (details.globalPosition - _center!).direction;
          _initialRotation = widget.item.rotation;

          _dragging = true;
          widget.onRotationStart?.call(); // 👈 popup hide

          setState(() {});
        },

        // ================= ROTATION UPDATE =================
        onPanUpdate: (details) {
          if (_center == null) return;

          final currentAngle =
              (details.globalPosition - _center!).direction;

          final deltaRadians = currentAngle - _startAngle;
          const double rotationSensitivity = 0.4; // 👈 jitna chhota, utna slow
          final deltaDegrees = (deltaRadians * 180 / math.pi) * rotationSensitivity;
          double newRotation = _initialRotation + deltaDegrees;

          // SHIFT snap 15°
          if (HardwareKeyboard.instance.isShiftPressed) {
            newRotation = (newRotation / 15).round() * 15;
          }

          widget.item.rotation = newRotation;

          widget.onUpdate?.call();
          setState(() {});
        },

        // ================= ROTATION END =================
        onPanEnd: (_) {
          _dragging = false;
          _center = null;

          widget.onRotationEnd?.call(); // 👈 popup show again

          setState(() {});
        },

        child: SizedBox(
          width: 48,
          height: 70,
          child: Column(
            children: [
              /// ROTATE ICON
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

              /// DEGREE LABEL
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
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