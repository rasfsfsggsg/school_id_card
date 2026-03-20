import 'package:flutter/material.dart';

class CustomColorPicker {
  static Future<void> show({
    required BuildContext context,
    required Color currentColor,
    required ValueChanged<Color> onColorSelected,
  }) async {
    await showDialog(
      context: context,
      builder: (_) => _AdvancedColorPickerDialog(
        initialColor: currentColor,
        onColorSelected: onColorSelected,
      ),
    );
  }
}

class _AdvancedColorPickerDialog extends StatefulWidget {
  final Color initialColor;
  final ValueChanged<Color> onColorSelected;

  const _AdvancedColorPickerDialog({
    required this.initialColor,
    required this.onColorSelected,
  });

  @override
  State<_AdvancedColorPickerDialog> createState() =>
      _AdvancedColorPickerDialogState();
}

class _AdvancedColorPickerDialogState
    extends State<_AdvancedColorPickerDialog> {
  late HSVColor hsvColor;
  late TextEditingController hexController;
  late TextEditingController rController;
  late TextEditingController gController;
  late TextEditingController bController;

  double boxWidth = 300;
  double boxHeight = 200;

  // Drag position
  double left = 100;
  double top = 100;

  @override
  void initState() {
    super.initState();
    hsvColor = HSVColor.fromColor(widget.initialColor);
    _initControllers();
  }

  void _initControllers() {
    final c = hsvColor.toColor();
    hexController = TextEditingController(
        text: "#${c.value.toRadixString(16).substring(2).toUpperCase()}");
    rController = TextEditingController(text: c.red.toString());
    gController = TextEditingController(text: c.green.toString());
    bController = TextEditingController(text: c.blue.toString());
  }

  void _syncControllers() {
    final c = hsvColor.toColor();
    hexController.text =
    "#${c.value.toRadixString(16).substring(2).toUpperCase()}";
    rController.text = c.red.toString();
    gController.text = c.green.toString();
    bController.text = c.blue.toString();
  }

  void _updateFromRGB() {
    int r = int.tryParse(rController.text) ?? 0;
    int g = int.tryParse(gController.text) ?? 0;
    int b = int.tryParse(bController.text) ?? 0;

    r = r.clamp(0, 255);
    g = g.clamp(0, 255);
    b = b.clamp(0, 255);

    hsvColor = HSVColor.fromColor(Color.fromARGB(255, r, g, b));
    widget.onColorSelected(hsvColor.toColor());
    _syncControllers();
    setState(() {});
  }

  void _updateFromHex(String value) {
    if (value.startsWith('#') && value.length == 7) {
      try {
        final color =
        Color(int.parse(value.substring(1), radix: 16) + 0xFF000000);
        hsvColor = HSVColor.fromColor(color);
        widget.onColorSelected(hsvColor.toColor());
        _syncControllers();
        setState(() {});
      } catch (_) {}
    }
  }

  void _handleBoxInteraction(Offset localPosition) {
    double sat = (localPosition.dx / boxWidth).clamp(0.0, 1.0);
    double val = 1 - (localPosition.dy / boxHeight).clamp(0.0, 1.0);

    hsvColor = hsvColor.withSaturation(sat).withValue(val);
    _syncControllers();
    widget.onColorSelected(hsvColor.toColor());
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final selectedColor = hsvColor.toColor();

    return Stack(
      children: [
        // Fullscreen transparent background
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(color: Colors.transparent),
        ),
        Positioned(
          left: left,
          top: top,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                left += details.delta.dx;
                top += details.delta.dy;

                // Clamp within screen
                final size = MediaQuery.of(context).size;
                left = left.clamp(0.0, size.width - 420);
                top = top.clamp(0.0, size.height - 600);
              });
            },
            child: Material(
              elevation: 10,
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text(
                          "Professional Color Picker",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),

                        // Saturation + Value box
                        LayoutBuilder(
                          builder: (context, constraints) {
                            boxWidth = constraints.maxWidth;
                            return GestureDetector(
                              onPanDown: (d) => _handleBoxInteraction(d.localPosition),
                              onPanUpdate: (d) => _handleBoxInteraction(d.localPosition),
                              child: Stack(
                                children: [
                                  Container(
                                    height: boxHeight,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.white,
                                          HSVColor.fromAHSV(1, hsvColor.hue, 1, 1)
                                              .toColor(),
                                        ],
                                      ),
                                    ),
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [Colors.transparent, Colors.black],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: (hsvColor.saturation * boxWidth - 8).clamp(0.0, boxWidth-16),
                                    top: ((1 - hsvColor.value) * boxHeight - 8).clamp(0.0, boxHeight-16),
                                    child: Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                        boxShadow: const [
                                          BoxShadow(color: Colors.black, blurRadius: 3)
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),

                        // Hue slider
                        Slider(
                          value: hsvColor.hue,
                          min: 0,
                          max: 360,
                          onChanged: (v) {
                            hsvColor = hsvColor.withHue(v);
                            _syncControllers();
                            widget.onColorSelected(hsvColor.toColor());
                            setState(() {});
                          },
                        ),
                        const SizedBox(height: 16),

                        // Preview
                        Container(
                          height: 40,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: selectedColor,
                            border: Border.all(color: Colors.black),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Color grid
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: Colors.primaries
                              .expand((color) => [
                            color.shade300,
                            color.shade500,
                            color.shade700,
                          ])
                              .map((color) => GestureDetector(
                            onTap: () {
                              hsvColor = HSVColor.fromColor(color);
                              _syncControllers();
                              widget.onColorSelected(hsvColor.toColor());
                              setState(() {});
                            },
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: color,
                                border: Border.all(
                                  color: selectedColor == color
                                      ? Colors.black
                                      : Colors.grey,
                                  width: 2,
                                ),
                              ),
                            ),
                          ))
                              .toList(),
                        ),
                        const SizedBox(height: 20),

                        // Hex
                        TextField(
                          controller: hexController,
                          decoration: const InputDecoration(
                            labelText: "Hex (#RRGGBB)",
                            border: OutlineInputBorder(),
                          ),
                          onChanged: _updateFromHex,
                        ),
                        const SizedBox(height: 12),

                        // RGB
                        Row(
                          children: [
                            _rgbField("R", rController),
                            const SizedBox(width: 8),
                            _rgbField("G", gController),
                            const SizedBox(width: 8),
                            _rgbField("B", bController),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("Cancel")),
                            const SizedBox(width: 8),
                            ElevatedButton(
                                onPressed: () {
                                  widget.onColorSelected(selectedColor);
                                  Navigator.pop(context);
                                },
                                child: const Text("Select")),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _rgbField(String label, TextEditingController controller) {
    return Expanded(
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        onChanged: (_) => _updateFromRGB(),
      ),
    );
  }
}