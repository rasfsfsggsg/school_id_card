import 'dart:html' as html;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class DesignExportHelper {
  /// ================================
  /// 🔥 EXPORT SINGLE CANVAS
  /// (Used by EditorPage – REQUIRED)
  /// ================================
  static Future<void> exportCanvas(
      GlobalKey key, {
        required bool withBackground,
      }) async {
    final image = await _capture(key);

    final byteData =
    await image.toByteData(format: ui.ImageByteFormat.png);

    final blob = html.Blob(
      [byteData!.buffer.asUint8List()],
      'image/png',
    );

    final url = html.Url.createObjectUrlFromBlob(blob);

    html.AnchorElement(href: url)
      ..download =
      withBackground ? 'design_full.png' : 'design_text_only.png'
      ..click();

    html.Url.revokeObjectUrl(url);
  }

  /// ================================
  /// 🔥 EXPORT FRONT + BACK (ONE IMAGE)
  /// ================================
  static Future<void> exportFrontAndBack({
    required GlobalKey frontKey,
    required GlobalKey backKey,
    required bool withBackground,
  }) async {
    final frontImage = await _capture(frontKey);
    final backImage = await _capture(backKey);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint();

    final width = frontImage.width.toDouble();
    final height =
        frontImage.height.toDouble() + backImage.height.toDouble();

    /// 🔼 FRONT
    canvas.drawImage(frontImage, Offset.zero, paint);

    /// 🔽 BACK (below front)
    canvas.drawImage(
      backImage,
      Offset(0, frontImage.height.toDouble()),
      paint,
    );

    final picture = recorder.endRecording();
    final finalImage =
    await picture.toImage(width.toInt(), height.toInt());

    final byteData =
    await finalImage.toByteData(format: ui.ImageByteFormat.png);

    final blob = html.Blob(
      [byteData!.buffer.asUint8List()],
      'image/png',
    );

    final url = html.Url.createObjectUrlFromBlob(blob);

    html.AnchorElement(href: url)
      ..download = withBackground
          ? 'design_front_back_full.png'
          : 'design_front_back_text_only.png'
      ..click();

    html.Url.revokeObjectUrl(url);
  }

  /// ================================
  /// 🔹 INTERNAL CANVAS CAPTURE
  /// ================================
  static Future<ui.Image> _capture(GlobalKey key) async {
    final boundary =
    key.currentContext!.findRenderObject() as RenderRepaintBoundary;

    return await boundary.toImage(pixelRatio: 3);
  }
}
