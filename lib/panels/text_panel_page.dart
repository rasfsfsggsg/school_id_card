import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/text_item.dart';
import '../models/excel_cell_selection.dart';
import '../common/canvas_side.dart';
import 'excel_column_popup.dart';

class TextPanelPage extends StatefulWidget {
  final ValueNotifier<List<TextItem>> frontText;
  final ValueNotifier<List<TextItem>> backText;
  final ValueNotifier<CanvasSide> canvasSide;

  final VoidCallback onToggle;
  final ValueNotifier<ExcelCellSelection?> selectedExcelCell;
  final ValueNotifier<List<List<String>>> excelDataNotifier;

  const TextPanelPage({
    super.key,
    required this.frontText,
    required this.backText,
    required this.canvasSide,
    required this.onToggle,
    required this.selectedExcelCell,
    required this.excelDataNotifier,
  });

  @override
  State<TextPanelPage> createState() => _TextPanelPageState();
}

class _TextPanelPageState extends State<TextPanelPage> {
  final _uuid = const Uuid();
  final Map<String, TextEditingController> _controllers = {};

  /// ===== CURRENT SIDE TEXT =====
  ValueNotifier<List<TextItem>> get _currentText =>
      widget.canvasSide.value == CanvasSide.front
          ? widget.frontText
          : widget.backText;

  @override
  void initState() {
    super.initState();

    widget.selectedExcelCell.addListener(() {
      final cell = widget.selectedExcelCell.value;
      if (cell != null) {
        updateTextFromSelectedCell(cell);
      }
    });
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _controllers.clear();
    super.dispose();
  }

  // ================= ADD TEXT =================
  void _addText() {
    final id = _uuid.v4();
    final item = TextItem(id: id, text: 'New Text'); // Default text

    _currentText.value = [..._currentText.value, item];
    _controllers[id] = TextEditingController(text: item.text);
    _currentText.notifyListeners();

    // Automatically focus the new TextField
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = _controllers[id];
      if (controller != null) {
        FocusScope.of(context).requestFocus(FocusNode());
        controller.selection =
            TextSelection(baseOffset: 0, extentOffset: controller.text.length);
      }
    });
  }

  // ================= DELETE TEXT =================
  void _deleteText(String id) {
    _currentText.value =
        _currentText.value.where((e) => e.id != id).toList();

    _controllers[id]?.dispose();
    _controllers.remove(id);
    _currentText.notifyListeners();
  }

  // ================= CONTROLLER =================
  TextEditingController _getController(TextItem item) {
    final controller = _controllers.putIfAbsent(
      item.id,
          () => TextEditingController(text: item.text),
    );

    if (controller.text != item.text) {
      controller.text = item.text;
    }
    return controller;
  }

  // ================= COLUMN BIND POPUP =================
  void _openColumnPopup(TextItem item) {
    final firstRow = widget.excelDataNotifier.value.isNotEmpty
        ? List<String>.from(widget.excelDataNotifier.value[0])
        : <String>[];

    if (firstRow.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Excel first row is empty")),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return ExcelColumnPopup(
          firstRow: firstRow,
          textItem: item,
          onClose: () {
            // 🔹 controller sync
            _controllers[item.id]?.text = item.text;
            _currentText.notifyListeners();

            // 🔥🔥🔥 MAIN FIX — yahin problem solve hoti hai
            final cell = widget.selectedExcelCell.value;
            if (cell != null) {
              updateTextFromSelectedCell(cell);
            }
          },
        );
      },
    );
  }


  void updateTextFromSelectedCell(ExcelCellSelection cell) {
    final excelData = widget.excelDataNotifier.value;

    // ✅ Excel data empty होने पर वापसी
    if (excelData.isEmpty || cell.row < 0 || cell.row >= excelData.length) return;

    final selectedRow = excelData[cell.row];

    // ✅ अगर row खाली है तो वापसी
    if (selectedRow.isEmpty) return;

    for (final item in _currentText.value) {
      if (!item.excelBound || item.excelColumn == null || item.isEditing) continue;

      // Excel column index safe calculation
      final colIndex = item.excelColumn!.codeUnitAt(0) - 65;

      if (colIndex >= 0 && colIndex < selectedRow.length) {
        final value = selectedRow[colIndex];

        item
          ..setText(value)
          ..excelRow = cell.row + 1;

        // Controller sync
        if (_controllers[item.id]?.text != value) {
          _controllers[item.id]?.text = value;
        }
      }
    }

    _currentText.notifyListeners();
  }


  // ================= HELPER =================
  String getColumnName(String colLetter) {
    if (widget.excelDataNotifier.value.isEmpty) return colLetter;

    final colIndex = colLetter.codeUnitAt(0) - 65;
    final firstRow = widget.excelDataNotifier.value[0];

    if (colIndex >= 0 && colIndex < firstRow.length) {
      return firstRow[colIndex];
    }

    return colLetter;
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<CanvasSide>(
      valueListenable: widget.canvasSide,
      builder: (context, side, _) {
        return Container(
          width: 320,
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 10),
            ],
          ),
          child: Column(
            children: [
              // HEADER
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      side == CanvasSide.front
                          ? "Text Fields (Front)"
                          : "Text Fields (Back)",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),

                  ],
                ),
              ),

              // ===== ATTRACTIVE ADD BUTTON =====
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _addText,
                    icon: const Icon(
                      Icons.add,
                      size: 24,
                      color: Colors.white, // ✅ icon white
                    ),
                    label: const Text(
                      "Add New Text Field",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white, // ✅ text bhi white
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue, // ✅ background blue
                      foregroundColor: Colors.white, // (safety: icon/text white)
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                  ),
                ),

              ),

              const SizedBox(height: 12),

              // TEXT LIST
              Expanded(
                child: ValueListenableBuilder<List<TextItem>>(
                  valueListenable: _currentText,
                  builder: (_, list, __) {
                    return ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (_, index) {
                        final item = list[index];
                        final controller = _getController(item);

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (item.excelBound && item.excelColumn != null)
                                        Text(
                                          getColumnName(item.excelColumn!),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      // 🎯 Wrap TextField in LayoutBuilder for max width
                                      LayoutBuilder(
                                        builder: (context, constraints) {
                                          return ConstrainedBox(
                                            constraints: BoxConstraints(
                                              maxWidth: constraints.maxWidth, // canvas ke andar hi limit
                                            ),
                                            child: TextField(
                                              controller: controller,
                                              maxLines: null, // multi-line allowed
                                              keyboardType: TextInputType.multiline,
                                              onTap: () {
                                                item.isEditing = true;
                                              },
                                              onChanged: (v) {
                                                item
                                                  ..setText(v)
                                                  ..isEditing = true;

                                                _currentText.notifyListeners();
                                              },
                                              onEditingComplete: () {
                                                item.isEditing = false;
                                              },
                                              focusNode: FocusNode()
                                                ..addListener(() {
                                                  if (!FocusScope.of(context).hasFocus) {
                                                    item.isEditing = false;
                                                  }
                                                }),
                                              decoration: const InputDecoration(
                                                border: InputBorder.none,
                                                isDense: true,
                                                contentPadding: EdgeInsets.symmetric(vertical: 8),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              IconButton(
                                icon: const Icon(Icons.table_chart,
                                    color: Colors.blue),
                                onPressed: () => _openColumnPopup(item),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteText(item.id),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
