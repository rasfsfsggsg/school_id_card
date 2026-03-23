import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FontManager {
  static final Map<String, String> fontFamilies = {
    'Liberation Sans': 'LiberationSans',
    'Liberation Serif': 'LiberationSerif',
    'Carlito': 'Carlito',
  };

  static List<String> get availableFonts =>
      fontFamilies.keys.toSet().toList()..sort();

  static TextStyle getFontStyle(
      String fontFamily, {
        FontWeight weight = FontWeight.normal,
        FontStyle style = FontStyle.normal,
        double fontSize = 14,
        Color color = Colors.black,
        TextDecoration? decoration,
      }) {
    return TextStyle(
      fontFamily: fontFamilies[fontFamily] ?? fontFamily,
      fontSize: fontSize,
      fontWeight: weight,
      fontStyle: style,
      color: color,
      decoration: decoration,
    );
  }

  static String safeFont(String fontFamily) {
    return fontFamilies.containsKey(fontFamily) ? fontFamily : availableFonts.first;
  }
}

/// ================= EXCEL POPUP =================
enum TextSourceType { static, bound, date }

class ExcelColumnPopup extends StatefulWidget {
  final List<String> firstRow;
  final dynamic textItem;
  final VoidCallback onClose;

  const ExcelColumnPopup({
    super.key,
    required this.firstRow,
    required this.textItem,
    required this.onClose,
  });

  @override
  State<ExcelColumnPopup> createState() => _ExcelColumnPopupState();
}

class _ExcelColumnPopupState extends State<ExcelColumnPopup> {
  TextSourceType _sourceType = TextSourceType.static;
  int? _selectedColumnIndex;
  final TextEditingController _staticController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _dateFormat = 'dd/MM/yyyy';

  late String _fontFamily;
  late int _fontSize;
  bool bold = false;
  bool italic = false;
  bool underline = false;
  late Color _textColor;
  late double _rotation;
  late int _posX;
  late int _posY;

  final List<String> styles = ['Regular', 'Italic', 'Bold', 'Bold Italic'];

  @override
  void initState() {
    super.initState();
    final t = widget.textItem;

    _staticController.text = t.text;

    _fontFamily = FontManager.safeFont(t.fontFamily);
    _fontSize = t.fontSize.toInt();
    bold = t.fontWeight == FontWeight.bold;
    italic = t.fontStyle == FontStyle.italic;
    underline = t.underline;
    _textColor = t.color;
    _rotation = t.rotation;
    _posX = t.position.dx.toInt();
    _posY = t.position.dy.toInt();

    if (t.excelColumn != null) {
      _sourceType = TextSourceType.bound;
      _selectedColumnIndex = t.excelColumn!.codeUnitAt(0) - 65;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fonts = FontManager.availableFonts;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      title: const Text("Text", style: TextStyle(fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // SOURCE
              _radioRow("Static", TextSourceType.static),
              _radioRow("Bound", TextSourceType.bound),
              _radioRow("Use Today's Date", TextSourceType.date),

              if (_sourceType == TextSourceType.static)
                Padding(
                  padding: const EdgeInsets.only(left: 24, top: 8),
                  child: TextField(
                    controller: _staticController,
                    decoration: const InputDecoration(
                        labelText: "Enter Text",
                        border: OutlineInputBorder(),
                        isDense: true),
                    style: FontManager.getFontStyle(
                      _fontFamily,
                      fontSize: _fontSize.toDouble(),
                      weight: bold ? FontWeight.bold : FontWeight.normal,
                      style: italic ? FontStyle.italic : FontStyle.normal,
                      color: _textColor,
                      decoration: underline ? TextDecoration.underline : null,
                    ),
                  ),
                ),

              if (_sourceType == TextSourceType.bound)
                Padding(
                  padding: const EdgeInsets.only(left: 24, top: 8),
                  child: DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(), isDense: true),
                    value: _selectedColumnIndex,
                    items: List.generate(widget.firstRow.length, (i) {
                      return DropdownMenuItem(
                        value: i,
                        child: Text(
                            "${String.fromCharCode(65 + i)} : ${widget.firstRow[i]}"),
                      );
                    }),
                    onChanged: (v) => setState(() => _selectedColumnIndex = v),
                  ),
                ),

              if (_sourceType == TextSourceType.date)
                Padding(
                  padding: const EdgeInsets.only(left: 24, top: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(DateFormat(_dateFormat).format(_selectedDate)),
                      DropdownButtonFormField<String>(
                        value: _dateFormat,
                        decoration: const InputDecoration(
                            border: OutlineInputBorder(), isDense: true),
                        items: const [
                          'dd/MM/yyyy',
                          'MM-dd-yyyy',
                          'yyyy-MM-dd',
                          'dd MMM yyyy',
                        ]
                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (v) => setState(() => _dateFormat = v!),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),
              const Text("Format", style: TextStyle(fontWeight: FontWeight.bold)),

              // FONT / SIZE
              Row(
                children: [
                  _dropdown("Font", fonts, _fontFamily,
                          (v) => setState(() => _fontFamily = v)),
                  const SizedBox(width: 8),
                  _dropdown(
                      "Size",
                      List.generate(80, (i) => '${i + 1}'),
                      _fontSize.toString(),
                          (v) => setState(() => _fontSize = int.parse(v)),
                      width: 80),
                ],
              ),

              const SizedBox(height: 8),

              // STYLE
              Wrap(
                spacing: 16,
                children: [
                  _check("Bold", bold, (v) => setState(() => bold = v)),
                  _check("Italic", italic, (v) => setState(() => italic = v)),
                  _check("Underline", underline, (v) => setState(() => underline = v)),
                ],
              ),

              const SizedBox(height: 8),

              // COLOR / ROTATION
              Row(
                children: [
                  _colorBox(),
                  const SizedBox(width: 16),
                  _dropdown(
                    "Rotation",
                    ['0', '90', '180', '270'],
                    _rotation.toStringAsFixed(0),
                        (v) => setState(() => _rotation = double.parse(v)),
                    width: 120,
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // POSITION
              Row(
                children: [
                  _numberField("X", _posX, (v) => setState(() => _posX = v)),
                  const SizedBox(width: 16),
                  _numberField("Y", _posY, (v) => setState(() => _posY = v)),
                ],
              ),
            ],
          ),
        ),
      ),

      actions: [
        TextButton(
            onPressed: () {
              widget.onClose();
              Navigator.pop(context);
            },
            child: const Text("Cancel")),
        ElevatedButton(
            onPressed: () {
              final item = widget.textItem;

              // TEXT
              if (_sourceType == TextSourceType.static) {
                item.bindToExcel(column: "", startRow: 1);
                item.setText(_staticController.text);
              }

              if (_sourceType == TextSourceType.bound && _selectedColumnIndex != null) {
                final col = String.fromCharCode(65 + _selectedColumnIndex!);
                item.bindToExcel(column: col, startRow: 1);
                item.setText(widget.firstRow[_selectedColumnIndex!]);
              }

              if (_sourceType == TextSourceType.date) {
                item.bindToExcel(column: "", startRow: 1);
                item.setText(DateFormat(_dateFormat).format(_selectedDate));
              }

              // STYLE
              item.fontFamily = FontManager.safeFont(_fontFamily);
              item.fontSize = _fontSize.toDouble();
              item.fontWeight = bold ? FontWeight.bold : FontWeight.normal;
              item.fontStyle = italic ? FontStyle.italic : FontStyle.normal;
              item.underline = underline;
              item.color = _textColor;
              item.rotation = _rotation;
              item.position = Offset(_posX.toDouble(), _posY.toDouble());

              widget.onClose();
              Navigator.pop(context);
            },
            child: const Text("OK")),
      ],
    );
  }

  Widget _radioRow(String label, TextSourceType value) => RadioListTile<TextSourceType>(
    dense: true,
    title: Text(label),
    value: value,
    groupValue: _sourceType,
    onChanged: (v) => setState(() => _sourceType = v!),
  );

  Widget _dropdown(String label, List<String> items, String value,
      ValueChanged<String> onChanged,
      {double width = 160}) =>
      SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label),
            DropdownButtonFormField<String>(
              value: items.contains(value) ? value : items.first,
              isDense: true,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: items
                  .toSet()
                  .toList()
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => onChanged(v!),
            ),
          ],
        ),
      );

  Widget _numberField(String label, int value, ValueChanged<int> onChanged) =>
      SizedBox(
        width: 120,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label),
            TextFormField(
              initialValue: value.toString(),
              keyboardType: TextInputType.number,
              decoration:
              const InputDecoration(border: OutlineInputBorder(), isDense: true),
              onChanged: (v) => onChanged(int.tryParse(v) ?? value),
            ),
          ],
        ),
      );

  Widget _check(String label, bool value, ValueChanged<bool> onChanged) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Checkbox(value: value, onChanged: (v) => onChanged(v!)),
      Text(label),
    ],
  );

  Widget _colorBox() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text("Color"),
      const SizedBox(height: 4),
      InkWell(
        onTap: () => setState(() {
          _textColor = _textColor == Colors.black ? Colors.red : Colors.black;
        }),
        child: Container(
          width: 40,
          height: 24,
          decoration: BoxDecoration(
            color: _textColor,
            border: Border.all(color: Colors.grey),
          ),
        ),
      ),
    ],
  );
}
