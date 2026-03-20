import 'package:flutter/material.dart';
import '../common/canvas_orientation.dart';
import 'BackgroundImageUploader.dart';

class DesignCanvasTopBar extends StatelessWidget {
  final ValueNotifier<CanvasOrientation> orientation;
  final bool showGrid;
  final VoidCallback onToggleGrid;
  final VoidCallback onEditSize;

  /// 🔥 Saved templates button callback
  final VoidCallback onShowSavedTemplates;

  final ValueNotifier<String?> backgroundImage;

  /// 🔥 For background image crop/scale/position
  final ValueNotifier<double> scaleNotifier;
  final ValueNotifier<Offset> positionNotifier;

  /// Extra buttons: Zoom, Save, Switch side etc.
  final List<Widget> extraActions;
  final ValueNotifier<bool> isUploading; // 🔹 required



  const DesignCanvasTopBar({
    super.key,
    required this.orientation,
    required this.showGrid,
    required this.onToggleGrid,
    required this.onEditSize,
    required this.onShowSavedTemplates,
    required this.backgroundImage,
    required this.scaleNotifier,
    required this.positionNotifier,
    this.extraActions = const [], required this.isUploading,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ================= ORIENTATION LABEL =================
          ValueListenableBuilder<CanvasOrientation>(
            valueListenable: orientation,
            builder: (_, o, __) {
              return Text(
                o == CanvasOrientation.horizontal
                    ? "Landscape Canvas"
                    : "Portrait Canvas",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              );
            },
          ),

          // ================= ACTION BUTTONS =================
          Row(
            children: [
              // Edit canvas size
              IconButton(
                tooltip: "Edit Canvas Size",
                icon: const Icon(Icons.straighten),
                onPressed: onEditSize,
              ),



              // Toggle Grid
              IconButton(
                tooltip: "Toggle Grid",
                icon: Icon(
                  Icons.grid_on,
                  color: showGrid ? Colors.blue : Colors.grey,
                ),
                onPressed: onToggleGrid,
              ),

              // Background Image Upload + Remove
              Stack(
                alignment: Alignment.topRight,
                children: [
                  // Upload image button
                  BackgroundImageUploader(
                    
                    imageUrlNotifier: backgroundImage, scaleNotifier: scaleNotifier,      // use widget parameter
                      positionNotifier: positionNotifier, isUploading: isUploading,
                    // use widget parameter

                  ),

                  // Remove background button
                  ValueListenableBuilder<String?>(
                    valueListenable: backgroundImage,
                    builder: (_, imgUrl, __) {
                      if (imgUrl == null) return const SizedBox();
                      return Positioned(
                        right: 0,
                        top: 0,
                        child: GestureDetector(
                          onTap: () {
                            // Reset image, scale, and position
                            backgroundImage.value = null;
                            scaleNotifier.value = 1.0;
                            positionNotifier.value = Offset.zero;

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Background image removed"),
                              ),
                            );
                          },
                        )
                      );
                    },
                  ),
                ],
              ),

              // Extra action buttons (Zoom / Save / Switch Side)
              ...extraActions,
            ],
          ),
        ],
      ),
    );
  }
}
