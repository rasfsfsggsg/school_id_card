
import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as ex;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


import '../models/text_item.dart';
import '../models/excel_cell_selection.dart';
import 'utils/excel_cache.dart';
class FullExcelPanel extends StatefulWidget {
  final ValueNotifier<List<TextItem>> textItems;
  final ValueNotifier<ExcelCellSelection?> selectedExcelCell;
  final ValueNotifier<List<List<String>>> excelDataNotifier;
  final ValueNotifier<List<int>> selectedRowIndexes;


  const FullExcelPanel({
    super.key,
    required this.textItems,
    required this.selectedExcelCell,
    required this.excelDataNotifier,
    required this.selectedRowIndexes, // 🔥 ADD

  });

  @override
  State<FullExcelPanel> createState() => _FullExcelPanelState();
}

class _FullExcelPanelState extends State<FullExcelPanel> {
  final List<List<List<String>>> allSheets = [];
  final List<String> sheetNames = [];
  final ScrollController _hCtrlBottom = ScrollController();
  bool _isSyncingHorizontal = false;
  int? _anchorRow;
  int? _startDragRow;
  bool _dragSelecting = false;
  bool _isDragging = false; // track if user is dragging
  Offset? _dragPointer; // track pointer position globally
  late final Ticker _autoScrollTicker; // ticker to auto-scroll while dragging


  int activeSheetIndex = 0;
  int? lastClickedRow; // Shift+Click के लिए track last clicked


  bool isUploading = false;
  bool isSheetChanging = false;
  double progress = 0;

  final ScrollController _hCtrl = ScrollController();
  final ScrollController _vCtrl = ScrollController();
  final ScrollController _sheetCtrl = ScrollController();

  // OLD:
// final ScrollController _vCtrl = ScrollController();

// NEW:
  final ScrollController _vCtrlHeader = ScrollController(); // Row header vertical
  final ScrollController _vCtrlGrid = ScrollController(); // Main grid vertical
  final FocusNode _gridFocusNode = FocusNode();


  static const double cellWidth = 120;
  static const double cellHeight = 40;
  static const double rowHeaderWidth = 50;
  static const double colHeaderHeight = 40;
  static const double titleRowHeight = 42;
  static const double bottomScrollbarHeight = 14;

  List<List<String>> get excelData =>
      widget.excelDataNotifier.value.isEmpty ? [] : widget.excelDataNotifier
          .value;


  @override
  void dispose() {
    _hCtrl.dispose();
    _vCtrl.dispose();
    _sheetCtrl.dispose();
    _gridFocusNode.dispose();
    _autoScrollTicker.dispose();

    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _restoreExcelFromCache();
    _hCtrl.addListener(() {
      if (_isSyncingHorizontal) return;

      if (_hCtrlBottom.hasClients) {
        _isSyncingHorizontal = true;
        _hCtrlBottom.jumpTo(_hCtrl.offset);
        _isSyncingHorizontal = false;
      }
    });

    _hCtrlBottom.addListener(() {
      if (_isSyncingHorizontal) return;

      if (_hCtrl.hasClients) {
        _isSyncingHorizontal = true;
        _hCtrl.jumpTo(_hCtrlBottom.offset);
        _isSyncingHorizontal = false;
      }
    });
    // Auto-scroll ticker
    _autoScrollTicker = Ticker(_autoScroll);
    _autoScrollTicker.start();

    // 🔥 SYNC VERTICAL SCROLL
    _vCtrlHeader.addListener(() {
      if (_vCtrlGrid.hasClients && _vCtrlGrid.offset != _vCtrlHeader.offset) {
        _vCtrlGrid.jumpTo(_vCtrlHeader.offset);
      }
    });

    _vCtrlGrid.addListener(() {
      if (_vCtrlHeader.hasClients && _vCtrlHeader.offset != _vCtrlGrid.offset) {
        _vCtrlHeader.jumpTo(_vCtrlGrid.offset);
      }
    });
  }


  void _selectRowFromPointer(Offset globalPos) {
    if (excelData.isEmpty) return;

    RenderBox box = context.findRenderObject() as RenderBox;
    final localOffset = box.globalToLocal(globalPos);

    final rowFromDrag =
        ((localOffset.dy - colHeaderHeight - titleRowHeight) ~/ cellHeight) + 1;

    if (rowFromDrag >= 1 && rowFromDrag < excelData.length) {
      final rows = List<int>.from(widget.selectedRowIndexes.value);
      if (!rows.contains(rowFromDrag)) {
        rows.add(rowFromDrag);
        widget.selectedRowIndexes.value = rows;
        widget.selectedRowIndexes.notifyListeners();
        _updateTextItems(rows);
        setState(() {});
      }
    }
  }

  void _updateTextItems(List<int> rows) {
    for (final rowIndex in rows) {
      if (rowIndex < 0 || rowIndex >= excelData.length) continue;

      for (final item in widget.textItems.value) {
        if (!item.excelBound || item.excelColumn == null) continue;

        final ci = _colIndexFromExcel(item.excelColumn!);
        if (ci >= 0 && ci < excelData[rowIndex].length) {
          item
            ..setText(excelData[rowIndex][ci])
            ..excelRow = rowIndex + 1;
        }
      }
    }
    widget.textItems.notifyListeners();
  }


  void _autoScroll(Duration _) {
    if (!_isDragging || _dragPointer == null) return;

    final RenderBox box = context.findRenderObject() as RenderBox;
    final localOffset = box.globalToLocal(_dragPointer!);

    const scrollMargin = 30.0;
    const scrollSpeed = 8.0;

    final viewHeight = _vCtrl.position.viewportDimension;
    final offset = _vCtrl.offset;

    bool scrolled = false;

    if (localOffset.dy > viewHeight - scrollMargin) {
      final maxScroll = _vCtrl.position.maxScrollExtent;
      _vCtrl.jumpTo((offset + scrollSpeed).clamp(0, maxScroll));
      scrolled = true;
    } else if (localOffset.dy < scrollMargin) {
      _vCtrl.jumpTo(
          (offset - scrollSpeed).clamp(0, _vCtrl.position.maxScrollExtent));
      scrolled = true;
    }

    if (scrolled) {
      _selectRowFromPointer(_dragPointer!);
    }
  }


  Future<void> _saveTempExcel({
    required String fileName,
    required List<String> sheetNames,
    required List<List<List<String>>> allSheetsData,
  }) async {
    try {
      final doc = FirebaseFirestore.instance.collection("excel_temp").doc();
      await doc.set({
        "id": doc.id,
        "fileName": fileName,
        "sheets": sheetNames,
        "allSheetsData": allSheetsData, // store full data to restore
        "uploadedAt": FieldValue.serverTimestamp(),
        "expiresAt": Timestamp.fromDate(
            DateTime.now().add(const Duration(hours: 3))),
      });
    } catch (e) {
      print("TEMP EXCEL SAVE ERROR: $e");
    }
  }

  Future<void> _loadLastTempExcel() async {
    final snap = await FirebaseFirestore.instance
        .collection("excel_temp")
        .orderBy("uploadedAt", descending: true)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return;

    final data = snap.docs.first.data();
    final List<String> sheets = List<String>.from(data['sheets'] ?? []);
    final List<dynamic> sheetsData = data['allSheetsData'] ?? [];

    if (sheets.isEmpty || sheetsData.isEmpty) return;

    sheetNames.clear();
    sheetNames.addAll(sheets);

    allSheets.clear(); // ✅ fill all sheets
    for (var sheet in sheetsData) {
      final List<List<String>> sheetData = [];
      for (var row in sheet) {
        sheetData.add(List<String>.from(row));
      }
      allSheets.add(sheetData);
    }

    // Set first sheet
    activeSheetIndex = 0;
    widget.excelDataNotifier.value = allSheets.first;
    widget.selectedExcelCell.value = null;
    widget.selectedRowIndexes.value = [];

    setState(() {});

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_gridFocusNode.canRequestFocus) {
        _gridFocusNode.requestFocus();
      }
    });
  }


  // ================= PICK EXCEL =================
  Future<void> _pickExcelFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xls', 'xlsx'],
      withData: true,
    );
    if (result == null || result.files.first.bytes == null) return;

    setState(() {
      isUploading = true;
      progress = 0;
    });

    final excel = ex.Excel.decodeBytes(result.files.first.bytes!);

    final bytes = result.files.first.bytes!;
    await ExcelCache.saveExcel(bytes); // 🔥 browser cache


    allSheets.clear();
    sheetNames.clear();

    final entries = excel.tables.entries.toList();
    final total = entries.length;

    for (int i = 0; i < total; i++) {
      final sheet = entries[i].value;
      if (sheet == null) continue;

      sheetNames.add(entries[i].key);

      final maxCols =
      sheet.rows.fold<int>(0, (m, r) => r.length > m ? r.length : m);

      final List<List<String>> data = [];
      for (final row in sheet.rows) {
        data.add(List.generate(
          maxCols,
              (c) => row.length > c ? row[c]?.value?.toString() ?? '' : '',
        ));
      }

      allSheets.add(data);

      setState(() => progress = (i + 1) / total);
      await Future.delayed(const Duration(milliseconds: 50));
    }

    activeSheetIndex = 0;
    widget.excelDataNotifier.value = allSheets.first;
    widget.selectedExcelCell.value = null;

    // 🔹 Save temp Excel to Firestore (persist 3 hours)
    await _saveTempExcel(
      fileName: result.files.first.name,
      sheetNames: sheetNames,
      allSheetsData: allSheets,
    );

    setState(() {
      isUploading = false;
      progress = 0;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_gridFocusNode.canRequestFocus) {
        _gridFocusNode.requestFocus();
      }
    });
  }

  void _onCellTap(int row, int col) {
    if (excelData.isEmpty) return;

    final rows = List<int>.from(widget.selectedRowIndexes.value);

    if (rows.contains(row)) {
      rows.remove(row); // deselect
    } else {
      rows.add(row); // select
    }

    widget.selectedRowIndexes.value = rows;

    widget.selectedExcelCell.value = ExcelCellSelection(
      row: row,
      col: col,
      value: excelData[row][col],
      address: "${_excelCol(col)}${row + 1}",
    );

    widget.selectedRowIndexes.notifyListeners();
    setState(() {});
  }


  void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent && excelData.isNotEmpty) {
      int selectedRow = widget.selectedExcelCell.value?.row ?? 1;
      int selectedCol = widget.selectedExcelCell.value?.col ?? 0;

      int newRow = selectedRow;

      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        newRow = (selectedRow + 1).clamp(1, excelData.length - 1);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        newRow = (selectedRow - 1).clamp(1, excelData.length - 1);
      } else {
        return;
      }

      if (newRow != selectedRow) {
        // ✅ Only select the new row, deselect all others
        widget.selectedRowIndexes.value = [newRow];
        widget.selectedExcelCell.value = ExcelCellSelection(
          row: newRow,
          col: selectedCol,
          value: excelData[newRow][selectedCol],
          address: "${_excelCol(selectedCol)}${newRow + 1}",
        );

        widget.selectedRowIndexes.notifyListeners();
        setState(() {});
        _scrollToCell(newRow, selectedCol);
      }
    }
  }


  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            _sheetBar(),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: Focus(
                      focusNode: _gridFocusNode,
                      autofocus: true,
                      onKeyEvent: (node, event) {
                        if (event is! KeyDownEvent)
                          return KeyEventResult.ignored;
                        if (excelData.isEmpty) return KeyEventResult.handled;

                        int selectedRow = widget.selectedExcelCell.value?.row ??
                            1;
                        int selectedCol = widget.selectedExcelCell.value?.col ??
                            0;

                        int newRow = selectedRow;
                        int newCol = selectedCol;

                        final shiftPressed = RawKeyboard.instance.keysPressed
                            .contains(LogicalKeyboardKey.shiftLeft) ||
                            RawKeyboard.instance.keysPressed
                                .contains(LogicalKeyboardKey.shiftRight);

                        // Arrow key navigation
                        if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                          newRow = (selectedRow + 1).clamp(1, excelData.length -
                              1);
                        } else
                        if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                          newRow = (selectedRow - 1).clamp(1, excelData.length -
                              1);
                        } else
                        if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                          newCol = (selectedCol + 1).clamp(0,
                              excelData[0].length - 1);
                        } else
                        if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                          newCol = (selectedCol - 1).clamp(
                              0, excelData[0].length - 1);
                        } else {
                          return KeyEventResult.ignored;
                        }

                        final rows = List<int>.from(
                            widget.selectedRowIndexes.value);

                        if (shiftPressed &&
                            (event.logicalKey == LogicalKeyboardKey.arrowDown ||
                                event.logicalKey ==
                                    LogicalKeyboardKey.arrowUp)) {
                          // Extend selection
                          final start = rows.isEmpty ? selectedRow : rows.first;
                          final end = newRow;

                          rows.clear();
                          for (int i = start < end ? start : end;
                          i <= (start > end ? start : end);
                          i++) {
                            rows.add(i);
                          }
                        } else {
                          // Normal single row selection
                          rows
                            ..clear()
                            ..add(newRow);
                        }

                        widget.selectedRowIndexes.value = rows;
                        widget.selectedExcelCell.value = ExcelCellSelection(
                          row: newRow,
                          col: newCol,
                          value: excelData[newRow][newCol],
                          address: "${_excelCol(newCol)}${newRow + 1}",
                        );
                        widget.selectedRowIndexes.notifyListeners();

                        _scrollToCell(newRow, newCol);
                        setState(() {});

                        return KeyEventResult.handled;
                      },
                      child: _buildGrid(),
                    ),
                  ),
                  _bottomHorizontalScrollbar(),
                ],
              ),
            ),
          ],
        ),
        if (isUploading || isSheetChanging)
          Positioned.fill(
            child: Container(
              color: Colors.black38,
              child: Center(
                child: Container(
                  width: 280,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("Loading Excel...",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(value: progress),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ================= SHEET BAR =================
  Widget _sheetBar() =>
      Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.black12))),
        child: Row(
          children: [
            ElevatedButton.icon(
              onPressed: _pickExcelFile,
              icon: const Icon(Icons.upload_file),
              label: const Text("Upload Excel"),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ListView.builder(
                controller: _sheetCtrl,
                scrollDirection: Axis.horizontal,
                itemCount: sheetNames.length,
                itemBuilder: (_, i) =>
                    GestureDetector(
                      onTap: () async {
                        if (i == activeSheetIndex) return;

                        setState(() {
                          isSheetChanging = true;
                          progress = 0;
                        });

                        await Future.delayed(const Duration(milliseconds: 150));

                        activeSheetIndex = i;
                        widget.excelDataNotifier.value = allSheets[i];
                        widget.selectedExcelCell.value = null;

                        setState(() => isSheetChanging = false);

                        // Refocus grid
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (_gridFocusNode.canRequestFocus) {
                            _gridFocusNode.requestFocus();
                          }
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: activeSheetIndex == i
                              ? Colors.blue
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          sheetNames[i],
                          style: TextStyle(
                            color: activeSheetIndex == i ? Colors.white : Colors
                                .black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
              ),
            ),
          ],
        ),
      );

  Future<void> _restoreExcelFromCache() async {
    final bytes = await ExcelCache.loadExcel();
    if (bytes == null) return;

    final excel = ex.Excel.decodeBytes(bytes);

    allSheets.clear();
    sheetNames.clear();

    for (final entry in excel.tables.entries) {
      final sheet = entry.value;
      if (sheet == null) continue;

      sheetNames.add(entry.key);

      final maxCols =
      sheet.rows.fold<int>(0, (m, r) => r.length > m ? r.length : m);

      final List<List<String>> data = [];
      for (final row in sheet.rows) {
        data.add(List.generate(
          maxCols,
              (c) => row.length > c ? row[c]?.value?.toString() ?? '' : '',
        ));
      }

      allSheets.add(data);
    }

    activeSheetIndex = 0;
    widget.excelDataNotifier.value = allSheets.first;
    widget.selectedExcelCell.value = null;
    widget.selectedRowIndexes.value = [];

    setState(() {});
  }


  Widget _cell(String t, int r, int c) {
    final bool isSelected = widget.selectedRowIndexes.value.contains(r);

    void _updateTextItems(List<int> rows) {
      for (final rowIndex in rows) {
        if (rowIndex < 0 || rowIndex >= excelData.length) continue;

        for (final item in widget.textItems.value) {
          if (!item.excelBound || item.excelColumn == null) continue;

          final ci = _colIndexFromExcel(item.excelColumn!);
          if (ci >= 0 && ci < excelData[rowIndex].length) {
            item
              ..setText(excelData[rowIndex][ci])
              ..excelRow = rowIndex + 1;
          }
        }
      }
      widget.textItems.notifyListeners();
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,

        // ================= CLICK =================
        onTap: () {
          final rows = <int>[];

          final isShift =
              RawKeyboard.instance.keysPressed.contains(LogicalKeyboardKey.shiftLeft) ||
                  RawKeyboard.instance.keysPressed.contains(LogicalKeyboardKey.shiftRight);

          final isCtrl =
              RawKeyboard.instance.keysPressed.contains(LogicalKeyboardKey.controlLeft) ||
                  RawKeyboard.instance.keysPressed.contains(LogicalKeyboardKey.controlRight) ||
                  RawKeyboard.instance.keysPressed.contains(LogicalKeyboardKey.metaLeft) ||
                  RawKeyboard.instance.keysPressed.contains(LogicalKeyboardKey.metaRight);

          if (isShift && _anchorRow != null) {
            // 🔥 SHIFT RANGE SELECT
            final start = _anchorRow!;
            final end = r;

            for (int i = start < end ? start : end;
            i <= (start > end ? start : end);
            i++) {
              rows.add(i);
            }
          } else if (isCtrl) {
            // 🔥 CTRL MULTI SELECT
            rows.addAll(widget.selectedRowIndexes.value);

            if (rows.contains(r)) {
              rows.remove(r);
            } else {
              rows.add(r);
            }

            _anchorRow ??= r;
          } else {
            // 🔥 NORMAL CLICK
            rows
              ..clear()
              ..add(r);

            _anchorRow = r;
          }

          widget.selectedRowIndexes.value = rows;
          widget.selectedRowIndexes.notifyListeners();

          widget.selectedExcelCell.value = ExcelCellSelection(
            row: r,
            col: c,
            value: t,
            address: "${_excelCol(c)}${r + 1}",
          );

          _scrollToCell(r, 0);
          _updateTextItems(rows);

          setState(() {});
        },

        // ================= DRAG SELECTION =================
        onPanStart: (details) {
          _isDragging = true;
          _dragPointer = details.globalPosition;
          _anchorRow = r;
        },

        onPanUpdate: (details) {
          _dragPointer = details.globalPosition;
          _selectRowFromPointer(details.globalPosition);
        },

        onPanEnd: (details) {
          _isDragging = false;
          _dragPointer = null;
          _startDragRow = null;
        },

        // ================= UI =================
        child: Container(
          width: cellWidth,
          height: cellHeight,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black26),
            color: isSelected
                ? Colors.blue.withOpacity(0.18)
                : Colors.white,
          ),
          child: Text(
            t,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildGrid() {
    if (excelData.isEmpty) {
      return const Center(child: Text("No Excel data loaded"));
    }

    final double gridWidth = excelData[0].length * cellWidth;

    return Stack(
      children: [

        // ================= MAIN CELLS =================
        Padding(
          padding: const EdgeInsets.only(
            top: colHeaderHeight + titleRowHeight,
            left: rowHeaderWidth,
            bottom: bottomScrollbarHeight + 6,
          ),
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerSignal: (event) {
              if (event is PointerScrollEvent) {
                final shiftPressed =
                    RawKeyboard.instance.keysPressed.contains(LogicalKeyboardKey.shiftLeft) ||
                        RawKeyboard.instance.keysPressed.contains(LogicalKeyboardKey.shiftRight);

                if (shiftPressed && _hCtrl.hasClients) {
                  final newOffset = (_hCtrl.offset + event.scrollDelta.dy)
                      .clamp(0.0, _hCtrl.position.maxScrollExtent);

                  _hCtrl.jumpTo(newOffset);
                }
              }
            },
            child: Scrollbar(
              controller: _vCtrlGrid,
              thumbVisibility: true,
              trackVisibility: true,
              child: SingleChildScrollView(
                controller: _vCtrlGrid,
                child: SingleChildScrollView(
                  controller: _hCtrl,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: gridWidth,
                    child: Column(
                      children: List.generate(
                        excelData.length - 1,
                            (r) {
                          return Row(
                            children: List.generate(
                              excelData[0].length,
                                  (c) {
                                return _cell(
                                  excelData[r + 1][c],
                                  r + 1,
                                  c,
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // ================= ROW HEADER =================
        Positioned(
          left: 0,
          top: colHeaderHeight + titleRowHeight,
          width: rowHeaderWidth,
          bottom: bottomScrollbarHeight + 6,
          child: Container(
            color: Colors.grey[300],
            child: SingleChildScrollView(
              controller: _vCtrlHeader,
              child: Column(
                children: List.generate(
                  excelData.length - 1,
                      (r) => _rowHeader(r + 1),
                ),
              ),
            ),
          ),
        ),

        // ================= COLUMN HEADER =================
        Positioned(
          left: rowHeaderWidth,
          top: 0,
          right: 0,
          height: colHeaderHeight,
          child: Container(
            color: Colors.grey[300],
            child: SingleChildScrollView(
              controller: _hCtrl,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: gridWidth,
                child: Row(
                  children: List.generate(
                    excelData[0].length,
                        (i) => _columnHeader(_excelCol(i)),
                  ),
                ),
              ),
            ),
          ),
        ),

        // ================= TITLE ROW =================
        Positioned(
          left: rowHeaderWidth,
          top: colHeaderHeight,
          right: 0,
          height: titleRowHeight,
          child: Container(
            color: Colors.grey[400],
            child: SingleChildScrollView(
              controller: _hCtrl,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: gridWidth,
                child: Row(
                  children: excelData[0].map((e) => _titleCell(e)).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
  void _scrollToCell(int row, int col) {
    final double targetY = (row - 1) * cellHeight;

    // Only vertical scroll for row navigation
    if (_vCtrlGrid.hasClients) {
      _vCtrlGrid.animateTo(
        targetY,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
      );
    }
  }

  Widget _bottomHorizontalScrollbar() {
    if (excelData.isEmpty) {
      return const SizedBox(height: bottomScrollbarHeight);
    }

    final double contentWidth = excelData[0].length * cellWidth;

    return Container(
      height: bottomScrollbarHeight + 10,
      color: Colors.grey[200],
      child: Scrollbar(
        controller: _hCtrlBottom,
        thumbVisibility: true,
        trackVisibility: true,
        thickness: 10,
        radius: const Radius.circular(4),
        scrollbarOrientation: ScrollbarOrientation.bottom,
        child: SingleChildScrollView(
          controller: _hCtrlBottom,
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: contentWidth,
            height: 20,
          ),
        ),
      ),
    );
  }
  // ================= HELPERS =================
  String _excelCol(int index) {
    String col = '';
    while (index >= 0) {
      col = String.fromCharCode(index % 26 + 65) + col;
      index = (index ~/ 26) - 1;
    }
    return col;
  }

  int _colIndexFromExcel(String col) {
    int index = 0;
    for (int i = 0; i < col.length; i++) {
      index = index * 26 + (col.codeUnitAt(i) - 64);
    }
    return index - 1;
  }

  Widget _columnHeader(String t) =>
      Container(
        width: cellWidth,
        height: colHeaderHeight,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          border: Border.all(color: Colors.black26),
        ),
        child: Text(t, style: const TextStyle(fontWeight: FontWeight.bold)),
      );

  Widget _titleCell(String t) =>
      Container(
        width: cellWidth,
        height: titleRowHeight,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        alignment: Alignment.centerLeft,
        color: Colors.black,
        child: Text(
          t,
          style:
          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      );

  Widget _rowHeader(int i) =>
      Container(
        width: rowHeaderWidth,
        height: cellHeight,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          border: Border.all(color: Colors.black26),
        ),
        child: Text(i.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold)),
      );

}