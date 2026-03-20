import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // kIsWeb

class ImageCropPopup extends StatefulWidget {
  final String imagePath; // file path or network url
  final double initialScale;
  final Offset initialPosition;
  final Function(double scale, Offset position) onConfirmed;

  const ImageCropPopup({
    super.key,
    required this.imagePath,
    this.initialScale = 1.0,
    this.initialPosition = const Offset(0, 0),
    required this.onConfirmed,
  });

  @override
  State<ImageCropPopup> createState() => _ImageCropPopupState();
}

class _ImageCropPopupState extends State<ImageCropPopup> {
  late double scale;
  late Offset position;

  @override
  void initState() {
    super.initState();
    scale = widget.initialScale;
    position = widget.initialPosition;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: SizedBox(
        width: double.infinity,
        height: 400,
        child: Stack(
          children: [
            /// IMAGE WITH MOVE & ZOOM
            GestureDetector(
              onScaleUpdate: (details) {
                setState(() {
                  scale = (scale * details.scale).clamp(0.5, 6.0);
                  position += details.focalPointDelta;
                });
              },
              child: ClipRect(
                child: Transform(
                  transform: Matrix4.identity()
                    ..translate(position.dx, position.dy)
                    ..scale(scale),
                  child: kIsWeb
                      ? Image.network(widget.imagePath, fit: BoxFit.cover)
                      : Image.file(File(widget.imagePath), fit: BoxFit.cover),
                ),
              ),
            ),

            /// CONTROLS: CANCEL / CONFIRM
            Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text("Cancel")),
                  ElevatedButton(
                      onPressed: () {
                        widget.onConfirmed(scale, position);
                        Navigator.of(context).pop();
                      },
                      child: const Text("Set Image")),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
