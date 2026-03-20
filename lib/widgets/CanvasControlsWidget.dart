import 'package:flutter/material.dart';
import '../common/canvas_orientation.dart';
import '../models/text_item.dart';
import '../widgets/text_top_toolbar.dart';
import '../widgets/BackgroundImageUploader.dart';

class CanvasControlsWidget extends StatelessWidget {
  final TextItem? selectedText;
  final VoidCallback clearSelection;

  final ValueNotifier<CanvasOrientation> orientation;
  final ValueNotifier<String?> backgroundImage;

  // 🔥 NEW REQUIRED
  final ValueNotifier<double> scaleNotifier;
  final ValueNotifier<Offset> positionNotifier;
  final ValueNotifier<bool> isUploading; // 🔹 required


  final VoidCallback showEditSizeDialog;
  final bool showGrid;
  final ValueChanged<bool> toggleGrid;
  final double zoom;
  final ValueChanged<double> updateZoom;



  const CanvasControlsWidget({
    super.key,
    this.selectedText,
    required this.clearSelection,
    required this.orientation,
    required this.backgroundImage,
    required this.scaleNotifier,      // required
    required this.positionNotifier,   // required
    required this.showEditSizeDialog,
    required this.showGrid,
    required this.toggleGrid,
    required this.zoom,
    required this.updateZoom, required this.isUploading,

  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Selected Text Toolbar
        if (selectedText != null)
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextTopToolbar(
              item: selectedText!,
              onUpdate: () {
                // Text update handled externally
              },
            ),
          ),

        // Top Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Orientation Label
              ValueListenableBuilder<CanvasOrientation>(
                valueListenable: orientation,
                builder: (_, o, __) {
                  return Text(
                    o == CanvasOrientation.horizontal
                        ? "Landscape Canvas"
                        : "Portrait Canvas",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  );
                },
              ),

              // Action Buttons
              Row(
                children: [
                  IconButton(
                    tooltip: "Edit Canvas Size",
                    icon: const Icon(Icons.straighten),
                    onPressed: showEditSizeDialog,
                  ),
                  IconButton(
                    tooltip: "Toggle Grid",
                    icon: Icon(Icons.grid_on,
                        color: showGrid ? Colors.blue : Colors.grey),
                    onPressed: () => toggleGrid(!showGrid),
                  ),

                  // Background Image Upload + Remove + Crop/Scale
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      BackgroundImageUploader(
                        imageUrlNotifier: backgroundImage, scaleNotifier: scaleNotifier,      // use widget parameter
                        positionNotifier: positionNotifier, isUploading: isUploading, // use widget parameter

                      ),
                      ValueListenableBuilder<String?>(
                        valueListenable: backgroundImage,
                        builder: (_, imgUrl, __) {
                          if (imgUrl == null) return const SizedBox();
                          return Positioned(
                            right: 0,
                            top: 0,
                            child: GestureDetector(
                              onTap: () => backgroundImage.value = null,
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),

        // Zoom & Image Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.remove),
              onPressed: () => updateZoom((zoom - 0.1).clamp(0.1, 10.0)),
            ),
            Text("${(zoom * 100).round()}%"),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => updateZoom(1.0),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => updateZoom((zoom + 0.1).clamp(0.1, 10.0)),
            ),
          ],
        ),

        // 🔥 NEW: Image Scale & Position Sliders for cropping
        ValueListenableBuilder2<double, Offset>(
          first: scaleNotifier,
          second: positionNotifier,
          builder: (_, scale, position, __) {
            if (backgroundImage.value == null) return const SizedBox();
            return Column(
              children: [
                // Scale Slider
                Row(
                  children: [
                    const Text("Scale:"),
                    Expanded(
                      child: Slider(
                        value: scale,
                        min: 0.1,
                        max: 5.0,
                        divisions: 50,
                        label: scale.toStringAsFixed(2),
                        onChanged: (v) => scaleNotifier.value = v,
                      ),
                    ),
                  ],
                ),

                // Position X Slider
                Row(
                  children: [
                    const Text("X:"),
                    Expanded(
                      child: Slider(
                        value: position.dx,
                        min: -500,
                        max: 500,
                        divisions: 100,
                        label: position.dx.toStringAsFixed(0),
                        onChanged: (v) => positionNotifier.value =
                            Offset(v, position.dy),
                      ),
                    ),
                  ],
                ),

                // Position Y Slider
                Row(
                  children: [
                    const Text("Y:"),
                    Expanded(
                      child: Slider(
                        value: position.dy,
                        min: -500,
                        max: 500,
                        divisions: 100,
                        label: position.dy.toStringAsFixed(0),
                        onChanged: (v) => positionNotifier.value =
                            Offset(position.dx, v),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// ================= ValueListenableBuilder2 =================
class ValueListenableBuilder2<A, B> extends StatelessWidget {
  final ValueNotifier<A> first;
  final ValueNotifier<B> second;
  final Widget Function(BuildContext, A, B, Widget?) builder;

  const ValueListenableBuilder2({
    super.key,
    required this.first,
    required this.second,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<A>(
      valueListenable: first,
      builder: (_, a, __) {
        return ValueListenableBuilder<B>(
          valueListenable: second,
          builder: (_, b, ___) => builder(context, a, b, null),
        );
      },
    );
  }
}
