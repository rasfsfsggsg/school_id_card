import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/text_item.dart';
import 'cate/open_ColorPicker.dart';

enum TextSourceType { static, bound, date }

class FontManager {
  static final Map<String, String> fontFamilies = {
    'Liberation Sans': 'LiberationSans',
    'Liberation Serif': 'LiberationSerif',
    'Carlito': 'Carlito',
    'Calibri': 'Calibri',
    'Arial': 'Arial',
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
    return availableFonts.contains(fontFamily) ? fontFamily : availableFonts.first;
  }
}

class ExcelColumnPopup extends StatefulWidget {
  final List<String> firstRow;
  final TextItem textItem;
  final VoidCallback onClose; // parent ko notify karne ke liye

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
  bool strike = false;

  bool border = false;
  bool autoSize = false;
  double roundCorner = 0.0;
  bool shrinkToFit = false;

  late Color _textColor;
  late double _rotation;

  late double _posX;
  late double _posY;

  late Color _borderColor;
  late double _borderWidth;

  late final List<String> _fontList;

  @override
  void initState() {
    super.initState();
    final t = widget.textItem;

    _staticController.text = t.text;

    _fontList = FontManager.availableFonts.toSet().toList()..sort();
    _fontFamily = FontManager.safeFont(t.fontFamily);
    _fontSize = t.fontSize.toInt();

    bold = t.fontWeight == FontWeight.bold;
    italic = t.fontStyle == FontStyle.italic;
    underline = t.underline;
    strike = t.strike;

    _textColor = t.color;
    _rotation = t.rotation;

    _posX = t.position.dx;
    _posY = t.position.dy;

    _borderColor = t.borderColor ?? Colors.black;
    _borderWidth = t.borderWidth ?? 1.0;

    border = t.border;
    autoSize = t.autoSize;
    roundCorner = t.roundCorner;
    shrinkToFit = t.shrinkToFit;

    if (t.excelColumn != null && t.excelColumn!.isNotEmpty) {
      _sourceType = TextSourceType.bound;
      _selectedColumnIndex = t.excelColumn!.codeUnitAt(0) - 65;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      title: const Text("Text", style: TextStyle(fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _radioRow("Static", TextSourceType.static),
              _radioRow("Bound", TextSourceType.bound),
              _radioRow("Use Today's Date", TextSourceType.date),
              const SizedBox(height: 8),

              if (_sourceType == TextSourceType.static)
                Padding(
                  padding: const EdgeInsets.only(left: 24, top: 8),
                  child: TextField(
                    controller: _staticController,
                    decoration: const InputDecoration(
                      labelText: "Enter Text",
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),

              if (_sourceType == TextSourceType.bound)
                Padding(
                  padding: const EdgeInsets.only(left: 24, top: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          value: _selectedColumnIndex,
                          items: List.generate(widget.firstRow.length, (i) {
                            return DropdownMenuItem(
                              value: i,
                              child: Text("${String.fromCharCode(65 + i)} : ${widget.firstRow[i]}"),
                            );
                          }),
                          onChanged: (v) => setState(() => _selectedColumnIndex = v),
                        ),
                      ),
                    ],
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
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
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
              Row(
                children: [
                  Expanded(child: _dropdown("Font", _fontList, _fontFamily, (v) => setState(() => _fontFamily = v))),
                  const SizedBox(width: 8),
                  _dropdown(
                    "Size",
                    List.generate(80, (i) => '${i + 1}'),
                    _fontSize.toString(),
                        (v) => setState(() => _fontSize = int.parse(v)),
                    width: 80,
                  ),
                ],
              ),

              const SizedBox(height: 8),
              Wrap(
                spacing: 16,
                children: [
                  _check("Bold", bold, (v) => setState(() => bold = v)),
                  _check("Italic", italic, (v) => setState(() => italic = v)),
                  _check("Underline", underline, (v) => setState(() => underline = v)),
                  _check("Strike", strike, (v) => setState(() => strike = v)),
                ],
              ),

              const SizedBox(height: 8),
              const Text("Options", style: TextStyle(fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 16,
                children: [
                  _check("Border", border, (v) => setState(() => border = v)),
                  _check("AutoSize", autoSize, (v) => setState(() => autoSize = v)),
                  _numberField("RoundCorner", roundCorner.toInt(), (v) => setState(() => roundCorner = v.toDouble())),
                  _check("ShrinkToFit", shrinkToFit, (v) => setState(() => shrinkToFit = v)),
                ],
              ),

              const SizedBox(height: 8),
              Row(
                children: [
                  _colorBox("Text", _textColor, (c) => setState(() => _textColor = c)),
                  const SizedBox(width: 16),
                  _colorBox("Border", _borderColor, (c) => setState(() => _borderColor = c)),
                  const SizedBox(width: 16),
                  _dropdown(
                    "Rotation",
                    ['0', '90', '180', '270'],
                    _rotation.toStringAsFixed(0),
                        (v) => setState(() => _rotation = double.parse(v)),
                    width: 120,
                  ),
                  const SizedBox(width: 16),
                  _numberField("Width", _borderWidth.toInt(), (v) => setState(() => _borderWidth = v.toDouble())),
                ],
              ),

              const SizedBox(height: 8),
              Row(
                children: [
                  _numberField("X", _posX.toInt(), (v) => setState(() => _posX = v.toDouble())),
                  const SizedBox(width: 16),
                  _numberField("Y", _posY.toInt(), (v) => setState(() => _posY = v.toDouble())),
                ],
              ),

              const SizedBox(height: 16),
              const Text("Sample", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                height: 50,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  border: Border.all(color: border ? _borderColor : Colors.transparent, width: _borderWidth),
                  borderRadius: BorderRadius.circular(roundCorner),
                ),
                alignment: Alignment.centerLeft,
                child: Transform.rotate(
                  angle: _rotation * 3.1415926 / 180,
                  child: Text(
                    _getSampleText(),
                    style: FontManager.getFontStyle(
                      _fontFamily,
                      fontSize: _fontSize.toDouble(),
                      weight: bold ? FontWeight.bold : FontWeight.normal,
                      style: italic ? FontStyle.italic : FontStyle.normal,
                      color: _textColor,
                      decoration: _getTextDecoration(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context); // popup close
          },
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            _applyChanges();
            Navigator.pop(context); // popup close
            // parent ko notify karo aur focus restore karo
            widget.onClose();
          },
          child: const Text("OK"),
        ),
      ],
    );
  }

  void _applyChanges() {
    final item = widget.textItem;

    // Apply all text & styles
    if (_sourceType == TextSourceType.static) {
      item.bindToExcel(column: "", startRow: 1);
      item.setText(_staticController.text);
    } else if (_sourceType == TextSourceType.bound && _selectedColumnIndex != null) {
      // ✅ Safety check
      if (_selectedColumnIndex! < widget.firstRow.length) {
        final col = String.fromCharCode(65 + _selectedColumnIndex!);
        item.bindToExcel(column: col, startRow: 1);
        item.setText(widget.firstRow[_selectedColumnIndex!]);
      }

  } else if (_sourceType == TextSourceType.date) {
      item.bindToExcel(column: "", startRow: 1);
      item.setText(DateFormat(_dateFormat).format(_selectedDate));
    }

    // Apply styles
    item.fontFamily = _fontFamily;
    item.fontSize = _fontSize.toDouble();
    item.fontWeight = bold ? FontWeight.bold : FontWeight.normal;
    item.fontStyle = italic ? FontStyle.italic : FontStyle.normal;
    item.underline = underline;
    item.strike = strike;
    item.color = _textColor;
    item.rotation = _rotation;
    item.position = Offset(_posX, _posY);
    item.border = border;
    item.borderColor = _borderColor;
    item.borderWidth = _borderWidth;
    item.autoSize = autoSize;
    item.roundCorner = roundCorner;
    item.shrinkToFit = shrinkToFit;
  }

  TextDecoration? _getTextDecoration() {
    if (underline && strike) return TextDecoration.combine([TextDecoration.underline, TextDecoration.lineThrough]);
    if (underline) return TextDecoration.underline;
    if (strike) return TextDecoration.lineThrough;
    return null;
  }

  String _getSampleText() {
    if (_sourceType == TextSourceType.static) return _staticController.text;
    if (_sourceType == TextSourceType.bound && _selectedColumnIndex != null && widget.firstRow.isNotEmpty) {
      if (_selectedColumnIndex! < widget.firstRow.length) {
        return widget.firstRow[_selectedColumnIndex!];
      }
    }
    if (_sourceType == TextSourceType.date) return DateFormat(_dateFormat).format(_selectedDate);
    return "";
  }

  Widget _radioRow(String label, TextSourceType value) => RadioListTile<TextSourceType>(
    dense: true,
    title: Text(label),
    value: value,
    groupValue: _sourceType,
    onChanged: (v) => setState(() => _sourceType = v!),
  );

  Widget _dropdown(String label, List<String> items, String? value, ValueChanged<String> onChanged,
      {double width = 160}) {
    final safeItems = items.toSet().toList()..sort();
    final safeValue =
    (value != null && safeItems.contains(value)) ? value : (safeItems.isNotEmpty ? safeItems.first : null);

    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          DropdownButtonFormField<String>(
            value: safeValue,
            isDense: true,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: safeItems.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ],
      ),
    );
  }

  Widget _numberField(String label, int value, ValueChanged<int> onChanged) => SizedBox(
    width: 120,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        TextFormField(
          initialValue: value.toString(),
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
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

  Widget _colorBox(String label, Color color, ValueChanged<Color> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 4),
        InkWell(
          onTap: () {
            CustomColorPicker.show(
              context: context,
              currentColor: color,
              onColorSelected: onChanged,
            );
          },
          child: Container(
            width: 60,
            height: 30,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey),
            ),
          ),
        ),
      ],
    );
  }
}
