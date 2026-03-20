import 'package:flutter/material.dart';
import '../common/canvas_orientation.dart';

class CanvasSizeSelectionDialog {
  static Future<void> show({
    required BuildContext context,
    required Function(double width, double height, CanvasOrientation orientation) onStart,
  }) async {
    // Default values
    double selectedWidth = 8.52;
    double selectedHeight = 5.51;
    CanvasOrientation selectedOrientation = CanvasOrientation.horizontal;

    bool isCustom = false;
    String selectedPreset = "Horizontal";

    // Preset sizes
    final presetSizes = [
      {
        'name': 'Vertical',
        'width': 5.51,
        'height': 8.52,
        'orientation': CanvasOrientation.vertical,
      },
      {
        'name': 'Horizontal',
        'width': 8.52,
        'height': 5.51,
        'orientation': CanvasOrientation.horizontal,
      },
      {
        'name': 'Square',
        'width': 5.51,
        'height': 5.51,
        'orientation': CanvasOrientation.vertical,
      },
      {
        'name': 'A4',
        'width': 4.0,
        'height': 7.7,
        'orientation': CanvasOrientation.vertical,
      },
      {
        'name': 'Custom',
        'width': selectedWidth,
        'height': selectedHeight,
        'orientation': selectedOrientation,
      },
    ];

    await showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (context) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Stack(
              children: [
                Container(
                  width: 450,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: StatefulBuilder(
                    builder: (context, setStateDialog) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 30), // Space for cross button
                          const Text(
                            "Select Canvas Size",
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 20),

                          // Dropdown for preset sizes
                          DropdownButtonFormField<String>(
                            value: selectedPreset,
                            items: presetSizes.map((preset) {
                              return DropdownMenuItem<String>(
                                value: preset['name'] as String,
                                child: Text("${preset['name']} (${preset['width']} × ${preset['height']} cm)"),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setStateDialog(() {
                                selectedPreset = val!;
                                isCustom = val == "Custom";

                                if (!isCustom) {
                                  final preset = presetSizes.firstWhere((p) => p['name'] == val);
                                  selectedWidth = preset['width'] as double;
                                  selectedHeight = preset['height'] as double;
                                  selectedOrientation = preset['orientation'] as CanvasOrientation;
                                }
                              });
                            },
                            decoration: InputDecoration(
                              labelText: "Canvas Size",
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: Colors.grey.shade100,
                            ),
                          ),

                          const SizedBox(height: 15),

                          // Custom width/height inputs
                          if (isCustom)
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    decoration: InputDecoration(
                                      labelText: "Width (cm)",
                                      filled: true,
                                      fillColor: Colors.grey.shade100,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    keyboardType: TextInputType.number,
                                    onChanged: (val) {
                                      setStateDialog(() {
                                        selectedWidth = double.tryParse(val) ?? selectedWidth;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    decoration: InputDecoration(
                                      labelText: "Height (cm)",
                                      filled: true,
                                      fillColor: Colors.grey.shade100,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    keyboardType: TextInputType.number,
                                    onChanged: (val) {
                                      setStateDialog(() {
                                        selectedHeight = double.tryParse(val) ?? selectedHeight;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),

                          const SizedBox(height: 25),

                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: () {
                                // Auto-detect orientation for custom size
                                if (isCustom) {
                                  selectedOrientation = selectedWidth > selectedHeight
                                      ? CanvasOrientation.horizontal
                                      : CanvasOrientation.vertical;
                                }

                                onStart(selectedWidth, selectedHeight, selectedOrientation);
                                Navigator.pop(context);
                              },
                              child: const Text("Start", style: TextStyle(fontSize: 16)),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                // Cross button to close dialog
                Positioned(
                  right: 0,
                  top: 0,
                  child: IconButton(
                    icon: const Icon(Icons.close, size: 28, color: Colors.grey),
                    onPressed: () {
                      Navigator.pop(context); // Close the dialog
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}