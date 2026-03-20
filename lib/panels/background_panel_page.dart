import 'package:flutter/material.dart';
import '../widgets/background_color_popup.dart';

class BackgroundPanelPage extends StatefulWidget {
  final ValueNotifier<Color> backgroundColor;
  final VoidCallback? onHide; // 🔹 Hide callback

  const BackgroundPanelPage({
    super.key,
    required this.backgroundColor,
    this.onHide,
  });

  @override
  State<BackgroundPanelPage> createState() => _BackgroundPanelPageState();
}

class _BackgroundPanelPageState extends State<BackgroundPanelPage> {
  final TextEditingController hexController = TextEditingController();
  final List<Color> recentColors = [];
  List<Color> colorVariants = [];

  final List<Color> presetColors = const [
    Colors.white,
    Color(0xffB3E5FC),
    Color(0xffC8E6C9),
    Color(0xffFFF9C4),
    Color(0xffFFCCBC),
    Color(0xffF8BBD0),
    Color(0xffBDBDBD),
    Color(0xff4FC3F7),
    Color(0xff66BB6A),
    Color(0xffFFEE58),
    Color(0xffFFB74D),
    Color(0xffEF9A9A),
    Color(0xff616161),
    Color(0xff29B6F6),
    Color(0xff43A047),
    Color(0xffFDD835),
    Color(0xffFB8C00),
    Color(0xffE53935),
    Colors.black,
    Color(0xff006064),
    Color(0xff2E7D32),
    Color(0xffAF8F00),
    Color(0xffBF360C),
    Color(0xff8E0000),

    // 🔹 Additional colors
    Color(0xff9C27B0), // Purple
    Color(0xff673AB7), // Deep Purple
    Color(0xff3F51B5), // Indigo
    Color(0xff03A9F4), // Light Blue
    Color(0xff00BCD4), // Cyan
    Color(0xff009688), // Teal
    Color(0xff8BC34A), // Light Green
    Color(0xffCDDC39), // Lime
    Color(0xffFFC107), // Amber
    Color(0xffFF9800), // Orange
    Color(0xffFF5722), // Deep Orange
    Color(0xff795548), // Brown
    Color(0xff9E9E9E), // Grey
    Color(0xff607D8B), // Blue Grey
    Color(0xffD500F9), // Bright Pink
  ];


  @override
  void initState() {
    super.initState();
    _updateHex(widget.backgroundColor.value);

    widget.backgroundColor.addListener(() {
      _updateHex(widget.backgroundColor.value);
      _updateVariants(widget.backgroundColor.value);
    });

    hexController.addListener(_onHexChanged);
    _updateVariants(widget.backgroundColor.value);
  }

  void _updateHex(Color color) {
    hexController.text =
    "#${color.value.toRadixString(16).substring(2).toUpperCase()}";
  }

  void _onHexChanged() {
    String hex = hexController.text.replaceAll("#", "");
    if (hex.length == 6 || hex.length == 8) {
      try {
        final intColor = int.parse(hex, radix: 16);
        final color = hex.length == 6 ? Color(0xFF000000 | intColor) : Color(intColor);
        widget.backgroundColor.value = color;
      } catch (_) {}
    }
  }

  void _select(Color color) {
    widget.backgroundColor.value = color;
    _updateVariants(color);

    if (!recentColors.contains(color)) {
      setState(() {
        recentColors.insert(0, color);
        if (recentColors.length > 5) {
          recentColors.removeLast();
        }
      });
    }
  }

  void _updateVariants(Color color) {
    final hsl = HSLColor.fromColor(color);
    colorVariants = List.generate(5, (i) {
      double factor = (i - 2) * 0.15; // -0.3, -0.15, 0, 0.15, 0.3
      double lightness = (hsl.lightness + factor).clamp(0.0, 1.0);
      return hsl.withLightness(lightness).toColor();
    });
    setState(() {});
  }

  void _openPopup() {
    showDialog(
      context: context,
      builder: (_) => BackgroundColorPopup(
        backgroundColor: widget.backgroundColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Column(
        children: [
          // ===== HEADER =====
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Background",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

            ],
          ),
          const SizedBox(height: 12),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// 🔹 COLOR PREVIEW (OPEN POPUP)
                  ValueListenableBuilder<Color>(
                    valueListenable: widget.backgroundColor,
                    builder: (_, color, __) {
                      return GestureDetector(
                        onTap: _openPopup,
                        child: Container(
                          height: 80,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.black12),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  /// 🔹 HEX FIELD
                  TextField(
                    controller: hexController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.palette),
                      suffixIcon: const Icon(Icons.colorize),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  /// 🔹 RAINBOW COLOR LINE
                  GestureDetector(
                    onTap: _openPopup,
                    child: Container(
                      height: 14,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: const LinearGradient(
                          colors: [
                            Colors.red,
                            Colors.orange,
                            Colors.yellow,
                            Colors.green,
                            Colors.cyan,
                            Colors.blue,
                            Colors.purple,
                            Colors.red,
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  /// 🔹 RECENT COLORS
                  if (recentColors.isNotEmpty) ...[
                    const Text(
                      "Recent Colors",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: recentColors.map(_colorDot).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  /// 🔹 COLOR VARIANTS
                  if (colorVariants.isNotEmpty) ...[
                    const Text(
                      "Variants",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: colorVariants.map(_colorDot).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  /// 🔹 PRESET COLORS
                  const Text(
                    "Preset Colors",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),

                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: presetColors.length,
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemBuilder: (_, i) => _colorDot(presetColors[i]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _colorDot(Color color) {
    return GestureDetector(
      onTap: () => _select(color),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black12),
        ),
      ),
    );
  }
}
