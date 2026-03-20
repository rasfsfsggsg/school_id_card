import 'package:flutter/material.dart';
import '../../models/graphic_item.dart';

/// ================= IMAGE BORDER EDITOR POPUP WITH INLINE COLOR PICKER & PRESETS =================
class ImageBorderPopup extends StatefulWidget {
  final GraphicItem item;
  final VoidCallback onUpdate;
  final VoidCallback onClose;

  const ImageBorderPopup({
    required this.item,
    required this.onUpdate,
    required this.onClose,
    super.key,
  });

  @override
  State<ImageBorderPopup> createState() => _ImageBorderPopupState();
}

class _ImageBorderPopupState extends State<ImageBorderPopup> {
  // Border properties
  Color borderColor = Colors.blue;
  double borderWidth = 2.0;
  double borderRadius = 0.0;

  // Controllers for color pickers
  late HSVColor hsvColor;
  late TextEditingController hexController;
  late TextEditingController rController;
  late TextEditingController gController;
  late TextEditingController bController;

  // Box dimensions
  double boxWidth = 250;
  double boxHeight = 150;

  // Preset quick colors
  final List<Color> presetColors = [
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.yellow,
    Colors.purple,
    Colors.orange,
    Colors.grey,
  ];

  // Dragable position
  double left = 100;
  double top = 100;

  @override
  void initState() {
    super.initState();

    // Initialize from item's existing border
    borderColor = widget.item.borderColor ?? Colors.blue;
    borderWidth = widget.item.borderWidth ?? 2.0;
    borderRadius = widget.item.borderRadius ?? 0.0;

    hsvColor = HSVColor.fromColor(borderColor);
    _initControllers();

    // Initialize popup near the graphic item
    final ctx = widget.item.boxKey.currentContext;
    if (ctx != null) {
      final box = ctx.findRenderObject() as RenderBox;
      final globalCenter = box.localToGlobal(box.size.center(Offset.zero));
      left = globalCenter.dx - 170; // approx half popup width
      top = globalCenter.dy - 100;  // approx half popup height
    }
  }

  void _initControllers() {
    final c = hsvColor.toColor();
    hexController =
        TextEditingController(text: "#${c.value.toRadixString(16).substring(2).toUpperCase()}");
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
    setState(() {
      borderColor = hsvColor.toColor();
    });
    _syncControllers();
  }

  void _updateFromHex(String value) {
    if (value.startsWith('#') && value.length == 7) {
      try {
        final color = Color(int.parse(value.substring(1), radix: 16) + 0xFF000000);
        hsvColor = HSVColor.fromColor(color);
        borderColor = hsvColor.toColor();
        _syncControllers();
        setState(() {});
      } catch (_) {}
    }
  }

  void _handleBoxInteraction(Offset localPosition) {
    double sat = (localPosition.dx / boxWidth).clamp(0.0, 1.0);
    double val = 1 - (localPosition.dy / boxHeight).clamp(0.0, 1.0);

    setState(() {
      hsvColor = hsvColor.withSaturation(sat).withValue(val);
      borderColor = hsvColor.toColor();
      _syncControllers();
    });
  }

  @override
  Widget build(BuildContext context) {
    const popupWidth = 340.0;

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            left += details.delta.dx;
            top += details.delta.dy;

            // Clamp within screen bounds
            final size = MediaQuery.of(context).size;
            left = left.clamp(0.0, size.width - popupWidth);
            top = top.clamp(0.0, size.height - 500); // approx height
          });
        },
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: popupWidth,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black26)],
            ),
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Edit Image Border",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),

                    // ===== PREVIEW IMAGE =====
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        border: Border.all(color: borderColor, width: borderWidth),
                        borderRadius: BorderRadius.circular(borderRadius),
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: widget.item.imageProvider != null
                          ? Image(image: widget.item.imageProvider!, fit: BoxFit.cover)
                          : const Icon(Icons.broken_image, size: 50),
                    ),
                    const SizedBox(height: 16),

                    // ===== HSV BOX =====
                    LayoutBuilder(
                      builder: (context, constraints) {
                        boxWidth = constraints.maxWidth;
                        return GestureDetector(
                          onPanDown: (details) => _handleBoxInteraction(details.localPosition),
                          onPanUpdate: (details) => _handleBoxInteraction(details.localPosition),
                          child: Stack(
                            children: [
                              Container(
                                height: boxHeight,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white,
                                      HSVColor.fromAHSV(1, hsvColor.hue, 1, 1).toColor(),
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
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
                                left: (hsvColor.saturation * boxWidth - 8).clamp(0.0, boxWidth - 16),
                                top: ((1 - hsvColor.value) * boxHeight - 8).clamp(0.0, boxHeight - 16),
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                    boxShadow: const [BoxShadow(color: Colors.black, blurRadius: 3)],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // ===== HUE SLIDER =====
                    Slider(
                      value: hsvColor.hue,
                      min: 0,
                      max: 360,
                      onChanged: (v) {
                        hsvColor = hsvColor.withHue(v);
                        borderColor = hsvColor.toColor();
                        _syncControllers();
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 12),

                    // ===== PREVIEW BAR =====
                    Container(
                      height: 40,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: borderColor,
                        border: Border.all(color: Colors.black),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ===== QUICK PRESET COLORS =====
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: presetColors
                          .map(
                            (c) => GestureDetector(
                          onTap: () {
                            hsvColor = HSVColor.fromColor(c);
                            borderColor = c;
                            _syncControllers();
                            setState(() {});
                          },
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: borderColor == c ? Colors.black : Colors.grey,
                                width: borderColor == c ? 3 : 1,
                              ),
                            ),
                          ),
                        ),
                      )
                          .toList(),
                    ),
                    const SizedBox(height: 12),

                    // ===== HEX INPUT =====
                    TextField(
                      controller: hexController,
                      decoration: const InputDecoration(
                        labelText: "Hex (#RRGGBB)",
                        border: OutlineInputBorder(),
                      ),
                      onChanged: _updateFromHex,
                    ),
                    const SizedBox(height: 8),

                    // ===== RGB INPUTS =====
                    Row(
                      children: [
                        _rgbField("R", rController),
                        const SizedBox(width: 8),
                        _rgbField("G", gController),
                        const SizedBox(width: 8),
                        _rgbField("B", bController),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ===== BORDER WIDTH =====
                    Row(
                      children: [
                        const Text("Width:"),
                        Expanded(
                          child: Slider(
                            min: 0,
                            max: 20,
                            value: borderWidth,
                            onChanged: (v) => setState(() => borderWidth = v),
                          ),
                        ),
                        Text(borderWidth.toStringAsFixed(1)),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ===== BORDER RADIUS =====
                    Row(
                      children: [
                        const Text("Radius:"),
                        Expanded(
                          child: Slider(
                            min: 0,
                            max: 50,
                            value: borderRadius,
                            onChanged: (v) => setState(() => borderRadius = v),
                          ),
                        ),
                        Text(borderRadius.toStringAsFixed(1)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ===== ACTION BUTTONS =====
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: widget.onClose,
                          child: const Text("Cancel"),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            widget.item.borderColor = borderColor;
                            widget.item.borderWidth = borderWidth;
                            widget.item.borderRadius = borderRadius;
                            widget.onUpdate();
                            widget.onClose();
                          },
                          child: const Text("Apply"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
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