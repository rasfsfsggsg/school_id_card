import 'package:flutter/material.dart';
import '../models/text_item.dart';

class TextFormatHelper {
  /// Apply all formatting except font family to a TextItem
  static void applyFormatting({
    required TextItem item,
    required bool bold,
    required bool italic,
    required bool underline,
    required Color color,
    required double rotation,
    required Offset position,
    required double fontSize,
  }) {
    item.fontSize = fontSize;
    item.fontWeight = bold ? FontWeight.bold : FontWeight.normal;
    item.fontStyle = italic ? FontStyle.italic : FontStyle.normal;
    item.underline = underline;
    item.color = color;
    item.rotation = rotation;
    item.position = position;
  }

  /// Generate TextStyle from TextItem (excluding font family)
  static TextStyle textStyleFromItem(TextItem item) {
    return TextStyle(
      fontSize: item.fontSize,
      fontWeight: item.fontWeight,
      fontStyle: item.fontStyle,
      color: item.color,
      decoration: item.underline ? TextDecoration.underline : null,
    );
  }
}
