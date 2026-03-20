import 'package:flutter/material.dart';
import '../../models/table_item.dart';
import '../../panels/cate/open_ColorPicker.dart';

enum ApplyMode { cell, row, column, table }

class TableCellEditor {
  static void open(
      BuildContext context,
      TableItem item,
      int r,
      int c,
      VoidCallback update,
      ) {
    final ctrl = TextEditingController(text: item.data[r][c]);

    // Initial colors & sizes
    Color bg = item.cellBg[r][c];
    Color txt = item.dataColor[r][c];
    Color borderColor = item.borderColor;
    double borderWidth = item.borderWidths[r][c];

    double cellWidth = item.cellWidths[r][c];
    double cellHeight = item.cellHeights[r][c];

    ApplyMode bgMode = ApplyMode.cell;
    ApplyMode txtMode = ApplyMode.cell;
    ApplyMode sizeMode = ApplyMode.cell;
    ApplyMode borderMode = ApplyMode.cell;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: StatefulBuilder(
            builder: (context, setState) {
              void applyBg(Color color) {
                switch (bgMode) {
                  case ApplyMode.cell:
                    item.cellBg[r][c] = color;
                    break;
                  case ApplyMode.row:
                    for (int i = 0; i < item.cols; i++) item.cellBg[r][i] = color;
                    break;
                  case ApplyMode.column:
                    for (int i = 0; i < item.rows; i++) item.cellBg[i][c] = color;
                    break;
                  case ApplyMode.table:
                    for (int i = 0; i < item.rows; i++)
                      for (int j = 0; j < item.cols; j++) item.cellBg[i][j] = color;
                    break;
                }
              }

              void applyText(Color color) {
                switch (txtMode) {
                  case ApplyMode.cell:
                    item.dataColor[r][c] = color;
                    break;
                  case ApplyMode.row:
                    for (int i = 0; i < item.cols; i++) item.dataColor[r][i] = color;
                    break;
                  case ApplyMode.column:
                    for (int i = 0; i < item.rows; i++) item.dataColor[i][c] = color;
                    break;
                  case ApplyMode.table:
                    for (int i = 0; i < item.rows; i++)
                      for (int j = 0; j < item.cols; j++)
                        item.dataColor[i][j] = color;
                    break;
                }
              }

              void applyWidth(double width) {
                switch (sizeMode) {
                  case ApplyMode.cell:
                    item.cellWidths[r][c] = width;
                    break;
                  case ApplyMode.row:
                    for (int i = 0; i < item.cols; i++) item.cellWidths[r][i] = width;
                    break;
                  case ApplyMode.column:
                    for (int i = 0; i < item.rows; i++) item.cellWidths[i][c] = width;
                    break;
                  case ApplyMode.table:
                    for (int i = 0; i < item.rows; i++)
                      for (int j = 0; j < item.cols; j++) item.cellWidths[i][j] = width;
                    break;
                }
              }

              void applyHeight(double height) {
                switch (sizeMode) {
                  case ApplyMode.cell:
                    item.cellHeights[r][c] = height;
                    break;
                  case ApplyMode.row:
                    for (int i = 0; i < item.cols; i++) item.cellHeights[r][i] = height;
                    break;
                  case ApplyMode.column:
                    for (int i = 0; i < item.rows; i++) item.cellHeights[i][c] = height;
                    break;
                  case ApplyMode.table:
                    for (int i = 0; i < item.rows; i++)
                      for (int j = 0; j < item.cols; j++) item.cellHeights[i][j] = height;
                    break;
                }
              }

              void applyBorderWidth(double width) {
                switch (borderMode) {
                  case ApplyMode.cell:
                    item.borderWidths[r][c] = width;
                    break;
                  case ApplyMode.row:
                    for (int i = 0; i < item.cols; i++) item.borderWidths[r][i] = width;
                    break;
                  case ApplyMode.column:
                    for (int i = 0; i < item.rows; i++) item.borderWidths[i][c] = width;
                    break;
                  case ApplyMode.table:
                    for (int i = 0; i < item.rows; i++)
                      for (int j = 0; j < item.cols; j++) item.borderWidths[i][j] = width;
                    break;
                }
              }

              void applyBorderColor(Color color) {
                switch (borderMode) {
                  case ApplyMode.cell:
                    item.borderColors[r][c] = color;
                    break;
                  case ApplyMode.row:
                    for (int i = 0; i < item.cols; i++) item.borderColors[r][i] = color;
                    break;
                  case ApplyMode.column:
                    for (int i = 0; i < item.rows; i++) item.borderColors[i][c] = color;
                    break;
                  case ApplyMode.table:
                    for (int i = 0; i < item.rows; i++)
                      for (int j = 0; j < item.cols; j++) item.borderColors[i][j] = color;
                    break;
                }
              }

              return Container(
                width: 480,
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Cell Editor",
                        style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),

                      /// TEXT FIELD
                      TextField(
                        controller: ctrl,
                        decoration: InputDecoration(
                          labelText: "Cell Text",
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 15),

                      /// PREVIEW
                      Container(
                        height: cellHeight,
                        width: cellWidth,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: borderColor, width: borderWidth),
                        ),
                        child: Text(
                          ctrl.text.isEmpty ? "Preview" : ctrl.text,
                          style: TextStyle(color: txt, fontSize: 16),
                        ),
                      ),
                      const Divider(height: 30),

                      /// BACKGROUND MODE
                      _buildModeSelector("Background Apply To", bgMode,
                              (mode) => setState(() => bgMode = mode)),

                      _colorButton(context, "Background", bg, (color) {
                        setState(() => bg = color);
                        applyBg(color);
                        update();
                      }),
                      const SizedBox(height: 15),

                      /// TEXT COLOR MODE
                      _buildModeSelector("Text Color Apply To", txtMode,
                              (mode) => setState(() => txtMode = mode)),

                      _colorButton(context, "Text Color", txt, (color) {
                        setState(() => txt = color);
                        applyText(color);
                        update();
                      }),
                      const Divider(height: 30),

                      /// SIZE MODE
                      _buildModeSelector("Size Apply To", sizeMode,
                              (mode) => setState(() => sizeMode = mode)),

                      _slider(context, "Cell Width", cellWidth, 30, 300,
                              (v) {
                            setState(() {
                              cellWidth = v;
                              applyWidth(v);
                            });
                            update();
                          }),
                      const SizedBox(height: 10),
                      _slider(context, "Cell Height", cellHeight, 20, 200,
                              (v) {
                            setState(() {
                              cellHeight = v;
                              applyHeight(v);
                            });
                            update();
                          }),
                      const Divider(height: 30),

                      /// BORDER SETTINGS
                      _buildModeSelector("Border Apply To", borderMode,
                              (mode) => setState(() => borderMode = mode)),

                      _slider(context, "Border Thickness", borderWidth, 1, 10,
                              (v) {
                            setState(() {
                              borderWidth = v;
                              applyBorderWidth(v);
                            });
                            update();
                          }),
                      const SizedBox(height: 10),
                      _colorButton(context, "Border Color", borderColor,
                              (color) {
                            setState(() {
                              borderColor = color;
                              applyBorderColor(color);
                            });
                            update();
                          }),
                      const Divider(height: 30),

                      /// ACTION BUTTONS
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text("Cancel")),
                          const SizedBox(width: 10),
                          ElevatedButton(
                              onPressed: () {
                                item.data[r][c] = ctrl.text;
                                update();
                                Navigator.pop(ctx);
                              },
                              child: const Text("Save")),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// MODE SELECTOR WRAPPER
  static Widget _buildModeSelector(
      String label, ApplyMode current, Function(ApplyMode) onChange) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
            alignment: Alignment.centerLeft,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          children: ApplyMode.values.map((mode) {
            return ChoiceChip(
              label: Text(mode.name.capitalize()),
              selected: current == mode,
              onSelected: (_) => onChange(mode),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  static Widget _slider(BuildContext context, String label, double value, double min,
      double max, Function(double) onChange) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        Row(
          children: [
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 6,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                ),
                child: Slider(
                    value: value,
                    min: min,
                    max: max,
                    divisions: (max - min).toInt(),
                    label: value.toStringAsFixed(0),
                    onChanged: onChange),
              ),
            ),
            SizedBox(
                width: 40,
                child: Text(value.toStringAsFixed(0),
                    textAlign: TextAlign.right)),
          ],
        ),
      ],
    );
  }

  static Widget _colorButton(
      BuildContext context, String label, Color color, Function(Color) onPick) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        GestureDetector(
          onTap: () async {
            await CustomColorPicker.show(
                context: context, currentColor: color, onColorSelected: onPick);
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.black26)),
          ),
        )
      ],
    );
  }
}

/// Helper extension
extension StringCap on String {
  String capitalize() => '${this[0].toUpperCase()}${substring(1)}';
}
