import 'package:flutter/material.dart';
import 'dart:math';

class TableItem {
  // ================= BASIC =================
  final String id;
  int rows;
  int cols;
  GlobalKey boxKey = GlobalKey();
  int zIndex;

  // ================= TRANSFORM =================
  Offset position;
  double scale;
  double rotation;
  bool locked;
  bool showResizeHandles;

  LayerLink layerLink = LayerLink();

  // ================= UI DATA =================
  List<List<String>> data;
  List<List<Color>> dataColor;
  List<List<Color>> cellBg;

  // ================= STYLE =================
  Color borderColor;
  double borderWidth; // default borderWidth
  Color headerColor;
  Color cellColor;

  // ================= CELL SIZE =================
  double cellWidth;
  double cellHeight;

  // ================= PER-CELL STYLE =================
  late List<List<double>> cellWidths;
  late List<List<double>> cellHeights;
  late List<List<double>> borderWidths;
  late List<List<Color>> borderColors;

  // ================= CONSTRUCTOR =================
  TableItem({
    required this.id,
    this.zIndex = 0,
    required this.rows,
    required this.cols,
    this.position = const Offset(150, 150),
    this.scale = 1.0,
    this.rotation = 0.0,
    this.locked = false,
    this.showResizeHandles = false,
    Color? borderColor,
    double? borderWidth,
    Color? headerColor,
    Color? cellColor,
    List<List<String>>? data,
    List<List<Color>>? dataColor,
    List<List<Color>>? cellBg,
    double? cellWidth,
    double? cellHeight,
  })  : borderColor = borderColor ?? Colors.black12,
        borderWidth = borderWidth ?? 1.0,
        headerColor = headerColor ?? const Color(0xffE3F2FD),
        cellColor = cellColor ?? Colors.white,
        cellWidth = cellWidth ?? 80,
        cellHeight = cellHeight ?? 40,
        data = data ?? List.generate(rows, (_) => List.generate(cols, (_) => "")),
        dataColor = dataColor ?? List.generate(rows, (_) => List.generate(cols, (_) => Colors.black)),
        cellBg = cellBg ??
            List.generate(
              rows,
                  (r) => List.generate(
                cols,
                    (_) => r == 0
                    ? (headerColor ?? const Color(0xffE3F2FD))
                    : (cellColor ?? Colors.white),
              ),
            ) {
    // Initialize per-cell sizes and borders
    cellWidths = List.generate(rows, (_) => List.generate(cols, (_) => this.cellWidth));
    cellHeights = List.generate(rows, (_) => List.generate(cols, (_) => this.cellHeight));
    borderWidths = List.generate(rows, (_) => List.generate(cols, (_) => this.borderWidth));
    borderColors = List.generate(rows, (_) => List.generate(cols, (_) => this.borderColor));
  }

  // ============================================================
  // ======================== COPY WITH ==========================
  // ============================================================

  TableItem copyWith({
    String? id,
    int? rows,
    int? cols,
    Offset? position,
    int? zIndex,
    double? scale,
    double? rotation,
    bool? locked,
    bool? showResizeHandles,
    Color? borderColor,
    double? borderWidth,
    Color? headerColor,
    Color? cellColor,
    List<List<String>>? data,
    List<List<Color>>? dataColor,
    List<List<Color>>? cellBg,
    double? cellWidth,
    double? cellHeight,
    List<List<double>>? cellWidths,
    List<List<double>>? cellHeights,
    List<List<double>>? borderWidths,
    List<List<Color>>? borderColors,
  }) {
    final copy = TableItem(
      id: id ?? this.id,
      rows: rows ?? this.rows,
      cols: cols ?? this.cols,
      zIndex: zIndex ?? this.zIndex,
      position: position ?? this.position,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      locked: locked ?? this.locked,
      showResizeHandles: showResizeHandles ?? this.showResizeHandles,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      headerColor: headerColor ?? this.headerColor,
      cellColor: cellColor ?? this.cellColor,
      cellWidth: cellWidth ?? this.cellWidth,
      cellHeight: cellHeight ?? this.cellHeight,
      data: data ?? this.data.map((r) => List<String>.from(r)).toList(),
      dataColor: dataColor ?? this.dataColor.map((r) => List<Color>.from(r)).toList(),
      cellBg: cellBg ?? this.cellBg.map((r) => List<Color>.from(r)).toList(),
    );

    // Copy per-cell arrays
    copy.cellWidths = cellWidths ?? this.cellWidths.map((r) => List<double>.from(r)).toList();
    copy.cellHeights = cellHeights ?? this.cellHeights.map((r) => List<double>.from(r)).toList();
    copy.borderWidths = borderWidths ?? this.borderWidths.map((r) => List<double>.from(r)).toList();
    copy.borderColors = borderColors ?? this.borderColors.map((r) => List<Color>.from(r)).toList();

    return copy;
  }

  // ============================================================
  // ======================== DUPLICATE ==========================
  // ============================================================

  TableItem duplicate() {
    return copyWith(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      position: position + const Offset(20, 20),
      showResizeHandles: false,
    );
  }

  // ============================================================
  // ======================== HELPERS ============================
  // ============================================================

  void addRow() {
    rows++;
    data.add(List.generate(cols, (_) => ""));
    dataColor.add(List.generate(cols, (_) => Colors.black));
    cellBg.add(List.generate(cols, (_) => cellColor));
    cellWidths.add(List.generate(cols, (_) => cellWidth));
    cellHeights.add(List.generate(cols, (_) => cellHeight));
    borderWidths.add(List.generate(cols, (_) => borderWidth));
    borderColors.add(List.generate(cols, (_) => borderColor));
  }

  void addColumn() {
    cols++;
    for (int r = 0; r < rows; r++) {
      data[r].add("");
      dataColor[r].add(Colors.black);
      cellBg[r].add(r == 0 ? headerColor : cellColor);
      cellWidths[r].add(cellWidth);
      cellHeights[r].add(cellHeight);
      borderWidths[r].add(borderWidth);
      borderColors[r].add(borderColor);
    }
  }

  void removeRow() {
    if (rows <= 1) return;
    rows--;
    data.removeLast();
    dataColor.removeLast();
    cellBg.removeLast();
    cellWidths.removeLast();
    cellHeights.removeLast();
    borderWidths.removeLast();
    borderColors.removeLast();
  }

  void removeColumn() {
    if (cols <= 1) return;
    cols--;
    for (int r = 0; r < rows; r++) {
      data[r].removeLast();
      dataColor[r].removeLast();
      cellBg[r].removeLast();
      cellWidths[r].removeLast();
      cellHeights[r].removeLast();
      borderWidths[r].removeLast();
      borderColors[r].removeLast();
    }
  }

  // ============================================================
  // ================= FIRESTORE SAFE SAVE =======================
  // ============================================================

  Map<String, dynamic> toMap() {
    final List<Map<String, dynamic>> cells = [];

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        cells.add({
          'r': r,
          'c': c,
          't': data[r][c],
          'tc': dataColor[r][c].value,
          'bg': cellBg[r][c].value,
          'w': cellWidths[r][c],
          'h': cellHeights[r][c],
          'bw': borderWidths[r][c],
          'bc': borderColors[r][c].value,
        });
      }
    }

    return {
      'id': id,
      'rows': rows,
      'cols': cols,
      'positionX': position.dx,
      'positionY': position.dy,
      'scale': scale,
      'rotation': rotation,
      'locked': locked,
      'borderColor': borderColor.value,
      'borderWidth': borderWidth,
      'headerColor': headerColor.value,
      'cellColor': cellColor.value,
      'cellWidth': cellWidth,
      'cellHeight': cellHeight,
      'cells': cells,
    };
  }

  factory TableItem.fromMap(Map<String, dynamic> map) {
    final rows = map['rows'] ?? 1;
    final cols = map['cols'] ?? 1;

    final data = List.generate(rows, (_) => List.generate(cols, (_) => ""));
    final dataColor = List.generate(rows, (_) => List.generate(cols, (_) => Colors.black));
    final cellBg = List.generate(rows, (_) => List.generate(cols, (_) => Colors.white));
    final cellWidths = List.generate(rows, (_) => List.generate(cols, (_) => 80.0));
    final cellHeights = List.generate(rows, (_) => List.generate(cols, (_) => 40.0));
    final borderWidths = List.generate(rows, (_) => List.generate(cols, (_) => 1.0));
    final borderColors = List.generate(rows, (_) => List.generate(cols, (_) => Colors.black12));

    final List cells = map['cells'] ?? [];
    for (final cell in cells) {
      final r = cell['r'];
      final c = cell['c'];
      if (r < rows && c < cols) {
        data[r][c] = cell['t'] ?? "";
        dataColor[r][c] = Color(cell['tc'] ?? Colors.black.value);
        cellBg[r][c] = Color(cell['bg'] ?? Colors.white.value);
        cellWidths[r][c] = (cell['w'] ?? 80.0).toDouble();
        cellHeights[r][c] = (cell['h'] ?? 40.0).toDouble();
        borderWidths[r][c] = (cell['bw'] ?? 1.0).toDouble();
        borderColors[r][c] = Color(cell['bc'] ?? Colors.black12.value);
      }
    }

    final table = TableItem(
      id: map['id'],
      rows: rows,
      cols: cols,
      position: Offset((map['positionX'] ?? 0).toDouble(), (map['positionY'] ?? 0).toDouble()),
      scale: (map['scale'] ?? 1).toDouble(),
      rotation: (map['rotation'] ?? 0).toDouble(),
      locked: map['locked'] ?? false,
      borderColor: Color(map['borderColor'] ?? Colors.black12.value),
      borderWidth: (map['borderWidth'] ?? 1.0).toDouble(),
      headerColor: Color(map['headerColor'] ?? 0xffE3F2FD),
      cellColor: Color(map['cellColor'] ?? Colors.white.value),
      cellWidth: (map['cellWidth'] ?? 80).toDouble(),
      cellHeight: (map['cellHeight'] ?? 40).toDouble(),
      data: data,
      dataColor: dataColor,
      cellBg: cellBg,
    );

    table.cellWidths = cellWidths;
    table.cellHeights = cellHeights;
    table.borderWidths = borderWidths;
    table.borderColors = borderColors;

    return table;
  }

  Map<String, dynamic> toJson() => toMap();
  factory TableItem.fromJson(Map<String, dynamic> json) => TableItem.fromMap(json);
}