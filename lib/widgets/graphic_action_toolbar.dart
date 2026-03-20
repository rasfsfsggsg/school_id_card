import 'package:flutter/material.dart';

class GraphicActionToolbar extends StatelessWidget {
  final VoidCallback onDelete;

  const GraphicActionToolbar({super.key, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: -40,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 6),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.delete, size: 18),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
