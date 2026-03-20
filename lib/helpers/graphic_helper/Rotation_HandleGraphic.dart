import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/graphic_item.dart';

class RotationHandleGraphic extends StatefulWidget {
  final GraphicItem item;
  final VoidCallback? onUpdate;
  final VoidCallback? onRotationStart;
  final VoidCallback? onRotationEnd;

  const RotationHandleGraphic({
    required this.item,
    this.onUpdate,
    this.onRotationStart,
    this.onRotationEnd,
    super.key,
  });

  @override
  State<RotationHandleGraphic> createState() =>
      _RotationHandleGraphicState();
}

class _RotationHandleGraphicState extends State<RotationHandleGraphic> {
  Offset? _center;
  double _startAngle = 0;
  double _initialRotation = 0;
  bool _isShiftPressed = false;
  bool _isDragging = false;

  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  double _normalizeAngle(double angle) {
    while (angle > 180) angle -= 360;
    while (angle < -180) angle += 360;
    return angle;
  }

  @override
  Widget build(BuildContext context) {
    double degrees = widget.item.rotation;

    return RawKeyboardListener(
      focusNode: _focusNode,
      onKey: (event) {
        setState(() {
          _isShiftPressed = event.isShiftPressed;
        });
      },
      child: MouseRegion(
        cursor: _isDragging
            ? SystemMouseCursors.grabbing
            : SystemMouseCursors.grab,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,

          onPanStart: (details) {
            _focusNode.requestFocus();
            _isDragging = true;

            final boxContext = widget.item.boxKey.currentContext;
            if (boxContext == null) return;

            final box = boxContext.findRenderObject() as RenderBox;
            final globalOffset = box.localToGlobal(Offset.zero);

            _center = Offset(
              globalOffset.dx + box.size.width / 2,
              globalOffset.dy + box.size.height / 2,
            );

            _startAngle =
                (details.globalPosition - _center!).direction;

            _initialRotation = widget.item.rotation;

            widget.onRotationStart?.call();
            setState(() {});
          },

          onPanUpdate: (details) {
            if (_center == null) return;

            final currentAngle =
                (details.globalPosition - _center!).direction;

            double deltaRadians = currentAngle - _startAngle;

            // Prevent jump at 180°
            if (deltaRadians > math.pi) {
              deltaRadians -= 2 * math.pi;
            } else if (deltaRadians < -math.pi) {
              deltaRadians += 2 * math.pi;
            }

            const double rotationSensitivity = 0.5;
            final deltaDegrees =
                (deltaRadians * 180 / math.pi) *
                    rotationSensitivity;

            double newRotation =
                _initialRotation + deltaDegrees;

            // Snap to 15° if Shift pressed
            if (_isShiftPressed) {
              newRotation =
                  (newRotation / 15).round() * 15;
            }

            newRotation = _normalizeAngle(newRotation);

            widget.item.rotation = newRotation;

            // 🔥 DEBUG PRINT
            print(
                "Rotation Updated: ${newRotation.toStringAsFixed(2)}°");

            widget.onUpdate?.call();
          },

          onPanEnd: (_) {
            _isDragging = false;
            widget.onRotationEnd?.call();
            setState(() {});
          },

          child: Container(
            width: 70,   // 👈 Gesture area bigger
            height: 110, // 👈 More space
            alignment: Alignment.topCenter,
            child: Column(
              children: [

                const SizedBox(height: 15), // 👈 Shifted down

                /// Rotation Circle
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 10,
                        color: Colors.black26,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.rotate_right,
                    size: 18,
                  ),
                ),

                const SizedBox(height: 10),

                /// Degree Label
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    "${degrees.toStringAsFixed(0)}°",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}