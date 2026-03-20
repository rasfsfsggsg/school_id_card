import 'dart:math';
import 'package:flutter/material.dart';
import '../models/text_item.dart';

class TextTransformBox extends StatelessWidget {
  final TextItem item;
  final Widget child;
  final bool selected;
  final Function(Offset delta) onMove;
  final VoidCallback onUpdate;

  const TextTransformBox({
    super.key,
    required this.item,
    required this.child,
    required this.selected,
    required this.onMove,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,

      onPanUpdate: item.locked
          ? null
          : (details) {
        onMove(details.delta);
      },


      child: Stack(
        clipBehavior: Clip.none,
        children: [

          /// VISUAL TRANSFORM ONLY
          Transform(
            alignment: Alignment.center,
            transform: _matrix(),
            child: child,
          ),

          /// 🔄 ROTATE
          if (selected && !item.locked)
            Positioned(
              top: -35,
              left: 30,
              child: _handle(
                icon: Icons.refresh,
                onDrag: (d) {
                  item.rotation += d.delta.dx * 0.01;
                  onUpdate();
                },
              ),
            ),

          /// ↔ SCALE
          if (selected && !item.locked)
            Positioned(
              bottom: -25,
              right: -25,
              child: _handle(
                icon: Icons.open_with,
                onDrag: (d) {
                  item.scale =
                      max(0.4, item.scale + d.delta.dy * 0.01);
                  onUpdate();
                },
              ),
            ),
        ],
      ),
    );
  }

  // ================= MATRIX =================

  Matrix4 _matrix() {
    final m = Matrix4.identity();
    m.rotateZ(item.rotation);
    m.scale(item.scale);
    return m;
  }

  // ================= HANDLE =================

  Widget _handle({
    required IconData icon,
    required GestureDragUpdateCallback onDrag,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanUpdate: onDrag,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.black26, blurRadius: 4),
          ],
        ),
        child: Icon(icon, size: 18, color: Colors.blue),
      ),
    );
  }
}
