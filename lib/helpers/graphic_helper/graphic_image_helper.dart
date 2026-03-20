import 'package:flutter/material.dart';
import '../../models/graphic_item.dart';

class GraphicImageHelper {
  static Widget build(
      GraphicItem item, {
        required double width,
        required double height,
      }) {
    if (item.imageProvider == null) {
      return const Icon(Icons.broken_image, size: 50);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(item.borderRadius ?? 0.0),
      child: Image(
        image: item.imageProvider!,
        width: width,
        height: height,
        fit: BoxFit.cover, // ✅ rectangle + square dono fit
      ),
    );
  }
}