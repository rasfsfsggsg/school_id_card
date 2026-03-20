import 'package:flutter/material.dart';

class BackgroundColorPopup extends StatefulWidget {
  final ValueNotifier<Color> backgroundColor;

  const BackgroundColorPopup({
    super.key,
    required this.backgroundColor,
  });

  @override
  State<BackgroundColorPopup> createState() => _BackgroundColorPopupState();
}

class _BackgroundColorPopupState extends State<BackgroundColorPopup> {
  bool showCMYK = false;

  double c = 0.0;
  double m = 0.0;
  double y = 0.0;
  double k = 0.0;

  late TextEditingController hexController;

  @override
  void initState() {
    super.initState();
    hexController = TextEditingController();
    _updateHex(widget.backgroundColor.value);

    widget.backgroundColor.addListener(() {
      _updateHex(widget.backgroundColor.value);
      _updateCMYKFromColor(widget.backgroundColor.value);
    });

    hexController.addListener(_onHexChanged);
  }

  @override
  void dispose() {
    hexController.dispose();
    super.dispose();
  }

  void _updateHex(Color color) {
    hexController.text =
    "#${color.value.toRadixString(16).substring(2).toUpperCase()}";
  }

  void _onHexChanged() {
    final hex = hexController.text.replaceAll("#", "");
    if (hex.length == 6 || hex.length == 8) {
      try {
        final intColor = int.parse(hex, radix: 16);
        final color = hex.length == 6 ? Color(0xFF000000 | intColor) : Color(intColor);
        widget.backgroundColor.value = color;
      } catch (_) {}
    }
  }

  void _updateCMYKFromColor(Color color) {
    final r = color.red / 255;
    final g = color.green / 255;
    final b = color.blue / 255;

    k = 1 - [r, g, b].reduce((a, b) => a > b ? a : b);
    c = (1 - r - k) / (1 - k + 1e-10);
    m = (1 - g - k) / (1 - k + 1e-10);
    y = (1 - b - k) / (1 - k + 1e-10);

    if (k == 1.0) c = m = y = 0.0;

    setState(() {});
  }

  Color get cmykColor {
    final r = 255 * (1 - c) * (1 - k);
    final g = 255 * (1 - m) * (1 - k);
    final b = 255 * (1 - y) * (1 - k);
    return Color.fromARGB(255, r.round(), g.round(), b.round());
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// 🔹 HEADER
            Row(
              children: [
                const Text(
                  "Background color",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            const SizedBox(height: 12),

            /// 🔹 COLOR PREVIEW
            ValueListenableBuilder<Color>(
              valueListenable: widget.backgroundColor,
              builder: (_, color, __) {
                return Container(
                  height: 140,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: color,
                    border: Border.all(color: Colors.black12),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            /// 🔹 HEX FIELD
            TextField(
              controller: hexController,
              decoration: InputDecoration(
                prefixText: "#",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(height: 14),

            /// 🔹 TABS
            Row(
              children: [
                _tab("Swatches", !showCMYK),
                _tab("CMYK", showCMYK),
              ],
            ),
            const Divider(),

            /// 🔹 CONTENT
            showCMYK ? _cmykView() : _swatchesView(),
          ],
        ),
      ),
    );
  }

  Widget _tab(String text, bool active) {
    return GestureDetector(
      onTap: () => setState(() => showCMYK = text == "CMYK"),
      child: Padding(
        padding: const EdgeInsets.only(right: 20),
        child: Column(
          children: [
            Text(
              text,
              style: TextStyle(
                fontWeight: active ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            if (active)
              Container(
                height: 2,
                width: 40,
                color: Colors.black,
              ),
          ],
        ),
      ),
    );
  }

  Widget _swatchesView() {
    final colors = [
      Colors.white,
      Colors.blue.shade100,
      Colors.green.shade100,
      Colors.yellow.shade100,
      Colors.orange.shade200,
      Colors.pink.shade200,
      Colors.grey,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.orange,
      Colors.red,
      Colors.black,
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: colors
          .map(
            (c) => GestureDetector(
          onTap: () => widget.backgroundColor.value = c,
          child: CircleAvatar(
            radius: 14,
            backgroundColor: c,
          ),
        ),
      )
          .toList(),
    );
  }

  Widget _cmykView() {
    return Column(
      children: [
        _slider("C", Colors.blue, c, (v) {
          setState(() => c = v);
          widget.backgroundColor.value = cmykColor;
        }),
        _slider("M", Colors.pink, m, (v) {
          setState(() => m = v);
          widget.backgroundColor.value = cmykColor;
        }),
        _slider("Y", Colors.orange, y, (v) {
          setState(() => y = v);
          widget.backgroundColor.value = cmykColor;
        }),
        _slider("K", Colors.black, k, (v) {
          setState(() => k = v);
          widget.backgroundColor.value = cmykColor;
        }),
      ],
    );
  }

  Widget _slider(
      String label,
      Color color,
      double value,
      ValueChanged<double> onChanged,
      ) {
    return Row(
      children: [
        SizedBox(width: 20, child: Text(label)),
        Expanded(
          child: Slider(
            value: value,
            onChanged: onChanged,
            activeColor: color,
          ),
        ),
        SizedBox(
          width: 40,
          child: Text("${(value * 100).round()}%"),
        ),
      ],
    );
  }
}
