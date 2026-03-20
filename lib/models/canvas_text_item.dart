import 'dart:ui';
import 'package:flutter/material.dart';

enum TextListType { none, bullet, number }

@immutable
class CanvasTextItem {
  final String id;
  final String text;
  final Offset position;
  final double scale;
  final double rotation;
  final bool locked;
  final Color color;
  final double fontSize;
  final FontWeight fontWeight;
  final FontStyle fontStyle;

  const CanvasTextItem({
    required this.id,
    required this.text,
    this.position = const Offset(100, 100),
    this.scale = 1,
    this.rotation = 0,
    this.locked = false,
    this.color = Colors.black,
    this.fontSize = 24,
    this.fontWeight = FontWeight.normal,
    this.fontStyle = FontStyle.normal,
  });

  CanvasTextItem copyWith({
    String? id,
    String? text,
    Offset? position,
    double? scale,
    double? rotation,
    bool? locked,
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
  }) {
    return CanvasTextItem(
      id: id ?? this.id,
      text: text ?? this.text,
      position: position ?? this.position,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      locked: locked ?? this.locked,
      color: color ?? this.color,
      fontSize: fontSize ?? this.fontSize,
      fontWeight: fontWeight ?? this.fontWeight,
      fontStyle: fontStyle ?? this.fontStyle,
    );
  }
}
