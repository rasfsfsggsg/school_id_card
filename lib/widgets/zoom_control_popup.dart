import 'package:flutter/material.dart';

class ZoomControlPopup extends StatelessWidget {
  final double zoom;
  final ValueChanged<double> onZoomChanged;

  const ZoomControlPopup({
    super.key,
    required this.zoom,
    required this.onZoomChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),

    );
  }
}
