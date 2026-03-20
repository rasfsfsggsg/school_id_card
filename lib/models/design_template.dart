import 'package:flutter/material.dart';
import 'text_item.dart';
import 'graphic_item.dart';
import 'qr_item.dart';
import 'table_item.dart';

class DesignTemplate {
  final String id;
  final String name;
  final Widget thumbnail;

  final Color background;
  final List<TextItem> texts;
  final List<GraphicItem> graphics;
  final List<QrItem> qrs;
  final List<TableItem> tables;

  DesignTemplate({
    required this.id,
    required this.name,
    required this.thumbnail,
    required this.background,
    required this.texts,
    required this.graphics,
    required this.qrs,
    required this.tables,
  });
}
