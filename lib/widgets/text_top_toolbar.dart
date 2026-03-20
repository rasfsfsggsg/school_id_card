import 'package:flutter/material.dart';
import '../models/text_item.dart';
import '../panels/cate/open_ColorPicker.dart';

class TextTopToolbar extends StatelessWidget {
  final TextItem item;
  final VoidCallback onUpdate;


  const TextTopToolbar({
    super.key,
    required this.item,
    required this.onUpdate,
    final VoidCallback? onBeginEdit, // ✅ ADD

  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _safeDropdown(
              value: item.fontFamily,
              items: const [
                'Arimo',
                'Roboto',
                'Poppins',
                'LiberationSans',
                'LiberationSerif',
                'Carlito'
              ],
              width: 160,
              onChanged: (v) {
                item.fontFamily = v;
                onUpdate();
              },
            ),

            const SizedBox(width: 8),
            _fontSizeControl(),
            const VerticalDivider(width: 16),

            _colorButton(context),
            const SizedBox(width: 6),

            _textStyleDropdown(),

            _icon(Icons.format_list_bulleted, () {
              item.listType = item.listType == TextListType.bullet
                  ? TextListType.none
                  : TextListType.bullet;
              onUpdate();
            }, active: item.listType == TextListType.bullet),

            _icon(Icons.format_list_numbered, () {
              item.listType = item.listType == TextListType.number
                  ? TextListType.none
                  : TextListType.number;
              onUpdate();
            }, active: item.listType == TextListType.number),

            const VerticalDivider(width: 16),

            _spacingPopup(),
            _opacityPopup(),
            _effectsPopup(),
            _rotationPopup(),
          ],
        ),
      ),
    );
  }

  /// SAFE DROPDOWN (NO OVERFLOW)
  Widget _safeDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
    double width = 140,
  }) {
    final safeItems = items.toSet().toList()..sort();
    final safeValue = safeItems.contains(value) ? value : safeItems.first;

    return SizedBox(
      width: width,
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<String>(
          value: safeValue,
          isExpanded: true,
          isDense: true,
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            border: OutlineInputBorder(),
          ),
          selectedItemBuilder: (context) {
            return safeItems.map((e) {
              return Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  e,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList();
          },
          items: safeItems
              .map((e) => DropdownMenuItem(
            value: e,
            child: Text(e, overflow: TextOverflow.ellipsis),
          ))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }

  /// FONT SIZE
  Widget _fontSizeControl() {
    final controller =
    TextEditingController(text: item.fontSize.toInt().toString());

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _icon(Icons.remove, () {
          item.fontSize = (item.fontSize - 1).clamp(1, 999);
          onUpdate();
        }),
        SizedBox(
          width: 50,
          child: TextField(
            controller: controller,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            onSubmitted: (v) {
              final d = double.tryParse(v);
              if (d != null) {
                item.fontSize = d;
                onUpdate();
              }
            },
            decoration: const InputDecoration(
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
        ),
        _icon(Icons.add, () {
          item.fontSize += 1;
          onUpdate();
        }),
      ],
    );
  }

  /// TEXT STYLE MENU
  Widget _textStyleDropdown() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.text_fields, size: 18),
      itemBuilder: (_) => [
        _styleItem("bold", Icons.format_bold),
        _styleItem("italic", Icons.format_italic),
        _styleItem("underline", Icons.format_underline),
        _styleItem("strike", Icons.format_strikethrough),
      ],
      onSelected: (v) {
        switch (v) {
          case "bold":
            item.fontWeight = item.fontWeight == FontWeight.bold
                ? FontWeight.normal
                : FontWeight.bold;
            break;
          case "italic":
            item.fontStyle = item.fontStyle == FontStyle.italic
                ? FontStyle.normal
                : FontStyle.italic;
            break;
          case "underline":
            item.underline = !item.underline;
            break;
          case "strike":
            item.strike = !item.strike;
            break;
        }
        onUpdate();
      },
    );
  }

  PopupMenuItem<String> _styleItem(String v, IconData icon) {
    return PopupMenuItem(
      value: v,
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(v.toUpperCase()),
        ],
      ),
    );
  }

  Widget _colorButton(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await CustomColorPicker.show(
          context: context,
          currentColor: item.color,
          onColorSelected: (color) {
            item.color = color;
            onUpdate();
          },
        );
      },
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: item.color,
          border: Border.all(color: Colors.black),
        ),
      ),
    );
  }

  Widget _icon(IconData icon, VoidCallback onTap, {bool active = false}) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      icon: Icon(icon, size: 18, color: active ? Colors.blue : Colors.black),
      onPressed: onTap,
    );
  }

  Widget _spacingPopup() {
    return PopupMenuButton(
      icon: const Icon(Icons.format_line_spacing, size: 18),
      itemBuilder: (_) => [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Letter Spacing"),
              _spacingField(
                value: item.letterSpacing,
                onChanged: (v) {
                  item.letterSpacing = v;
                  onUpdate();
                },
              ),
              const SizedBox(height: 8),
              const Text("Line Spacing"),
              _spacingField(
                value: item.lineSpacing,
                min: 1,
                onChanged: (v) {
                  item.lineSpacing = v;
                  onUpdate();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _spacingField({
    required double value,
    required ValueChanged<double> onChanged,
    double min = 0,
  }) {
    final controller =
    TextEditingController(text: value.toStringAsFixed(1));
    return SizedBox(
      width: 80,
      child: TextField(
        controller: controller,
        keyboardType:
        const TextInputType.numberWithOptions(decimal: true),
        onSubmitted: (v) {
          final d = double.tryParse(v);
          if (d != null && d >= min) onChanged(d);
        },
        decoration:
        const InputDecoration(isDense: true, border: OutlineInputBorder()),
      ),
    );
  }

  Widget _opacityPopup() {
    return PopupMenuButton(
      icon: const Icon(Icons.opacity, size: 18),
      itemBuilder: (_) => [
        PopupMenuItem(
          enabled: false,
          child: Column(
            children: [
              Slider(
                value: item.opacity,
                min: 0,
                max: 1,
                onChanged: (v) {
                  item.opacity = v;
                  onUpdate();
                },
              ),
              Text("${(item.opacity * 100).round()}%"),
            ],
          ),
        ),
      ],
    );
  }

  Widget _effectsPopup() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.auto_awesome, size: 18),
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: "shadow",
          child: Row(
            children: [
              Icon(Icons.blur_on, size: 18),
              SizedBox(width: 8),
              Text("Shadow"),
            ],
          ),
        ),
      ],
      onSelected: (_) {
        item.shadow = !item.shadow;
        onUpdate();
      },
    );
  }

  Widget _rotationPopup() {
    return PopupMenuButton<double>(
      icon: const Icon(Icons.rotate_right, size: 18),
      itemBuilder: (_) => [0, 45, 90, 135, 180, 225, 270, 315]
          .map((v) => PopupMenuItem(
        value: v.toDouble(),
        child: Text("$v°"),
      ))
          .toList(),
      onSelected: (v) {
        item.rotation = v;
        onUpdate();
      },
    );
  }
}





