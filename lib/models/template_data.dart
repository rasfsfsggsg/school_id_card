import 'dart:ui';


import 'package:vista_print24/models/qr_item.dart';
import 'package:vista_print24/models/table_item.dart';
import 'package:vista_print24/models/text_item.dart';

import 'graphic_item.dart';

class TemplateData {
  final String id;
  final double width;
  final double height;
  final bool showGrid;
  final Color frontBg;
  final Color backBg;
  final String? frontImage;
  final Offset frontImagePosition;
  final double frontImageScale;
  final String? backImage;
  final Offset backImagePosition;
  final double backImageScale;
  final List<TextItem> frontTexts;
  final List<TextItem> backTexts;
  final List<QrItem> frontQrs;
  final List<QrItem> backQrs;
  final List<GraphicItem> frontGraphics;
  final List<GraphicItem> backGraphics;
  final List<TableItem> frontTables;
  final List<TableItem> backTables;

  TemplateData({
    required this.id,
    required this.width,
    required this.height,
    required this.showGrid,
    required this.frontBg,
    required this.backBg,
    this.frontImage,
    required this.frontImagePosition,
    required this.frontImageScale,
    this.backImage,
    required this.backImagePosition,
    required this.backImageScale,
    required this.frontTexts,
    required this.backTexts,
    required this.frontQrs,
    required this.backQrs,
    required this.frontGraphics,
    required this.backGraphics,
    required this.frontTables,
    required this.backTables,
  });

  factory TemplateData.fromExcelRow(List<String> row) {
    // यहाँ row के हिसाब से mapping करें
    return TemplateData(
      id: row[0],
      width: double.tryParse(row[1]) ?? 55,
      height: double.tryParse(row[2]) ?? 65,
      showGrid: row[3] == "1",
      frontBg: Color(int.tryParse(row[4]) ?? 0xffffffff),
      backBg: Color(int.tryParse(row[5]) ?? 0xffffffff),
      frontImage: row[6],
      frontImagePosition: Offset.zero,
      frontImageScale: 1.0,
      backImage: row[7],
      backImagePosition: Offset.zero,
      backImageScale: 1.0,
      frontTexts: [],
      backTexts: [],
      frontQrs: [],
      backQrs: [],
      frontGraphics: [],
      backGraphics: [],
      frontTables: [],
      backTables: [],
    );
  }
}
