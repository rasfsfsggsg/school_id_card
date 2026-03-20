import 'dart:typed_data';
import 'dart:ui';
import 'package:excel/excel.dart';
import '../models/text_item.dart';

class ExcelImportHelper {
  /// 🔹 Static preview rows accessible by TextPanelPage
  static List<List<String>> previewRows = [];

  /// Sheet names
  static List<String> getSheetNames(Uint8List bytes) {
    final excel = Excel.decodeBytes(bytes);
    return excel.tables.keys.toList();
  }

  /// Preview Excel (rows of string)
  static List<List<String>> parseExcelForPreview(Uint8List bytes, {String? sheet}) {
    final excel = Excel.decodeBytes(bytes);
    final table = sheet != null ? excel.tables[sheet] : excel.tables.values.first;

    if (table == null) return [];

    final rows = table.rows
        .map((row) => List.generate(
      row.length,
          (i) => row[i]?.value.toString() ?? '',
    ))
        .toList();

    previewRows = rows; // store static preview for TextPanel
    return rows;
  }

  /// Parse Excel into TextItems
  static List<TextItem> parseExcelToTextItems(
      Uint8List bytes, {
        String? sheet,
        required int startRow,
        required int endRow,
        required String textCol,
        required String xCol,
        required String yCol,
        required String fontCol,
      }) {
    final excel = Excel.decodeBytes(bytes);
    final table = sheet != null ? excel.tables[sheet] : excel.tables.values.first;

    if (table == null || table.rows.isEmpty) return [];

    final headers = table.rows.first
        .map((c) => c?.value.toString() ?? '')
        .toList();

    final textIndex = headers.indexOf(textCol);
    final xIndex = headers.indexOf(xCol);
    final yIndex = headers.indexOf(yCol);
    final fontIndex = headers.indexOf(fontCol);

    final items = <TextItem>[];

    for (int i = startRow - 1; i < table.rows.length && i < endRow; i++) {
      final row = table.rows[i];

      String safeCell(int index) => (index >= 0 && index < row.length) ? row[index]?.value.toString() ?? '' : '';

      items.add(TextItem(
        text: safeCell(textIndex),
        position: Offset(
          double.tryParse(safeCell(xIndex)) ?? 100,
          double.tryParse(safeCell(yIndex)) ?? 100,
        ),
        fontSize: double.tryParse(safeCell(fontIndex)) ?? 28,
      ));
    }

    return items;
  }

  /// 🔹 Returns a map of column name -> list of values
  static Map<String, List<String>> parseExcelColumns(Uint8List bytes, {String? sheet}) {
    final excel = Excel.decodeBytes(bytes);
    final table = sheet != null ? excel.tables[sheet] : excel.tables.values.first;

    if (table == null || table.rows.isEmpty) return {};

    final headers = table.rows.first
        .map((c) => c?.value.toString() ?? '')
        .toList();

    final map = <String, List<String>>{};
    for (int col = 0; col < headers.length; col++) {
      map[headers[col]] = table.rows.map((row) => (col < row.length ? row[col]?.value.toString() ?? '' : '')).toList();
    }

    return map;
  }

  /// 🔹 Helper to get column headers for dropdowns
  static List<String> getHeaders() {
    if (previewRows.isEmpty) return [];
    return previewRows.first;
  }
}
