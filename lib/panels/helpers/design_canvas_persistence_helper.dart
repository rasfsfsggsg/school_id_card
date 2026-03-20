import 'dart:html' as html;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/graphic_item.dart';
import '../../models/qr_item.dart';
import '../../models/table_item.dart';
import '../../models/text_item.dart';

import 'design_canvas_helpers.dart';

class DesignCanvasPersistenceHelper {
  /// ================= TEMP CANVAS ID =================
  static String getOrCreateTempCanvasId() {
    final existing = html.window.localStorage['tempCanvasId'];
    if (existing != null) return existing;

    final id = "temp_canvas_${DateTime.now().millisecondsSinceEpoch}";
    html.window.localStorage['tempCanvasId'] = id;
    return id;
  }

  static Future<Map<String, dynamic>?> getTempCanvas(String canvasId) async {
    return await DesignCanvasHelper.loadTempCanvas(canvasId);
  }
  /// ================= LOAD TEMP CANVAS =================
  static Future<void> loadTempCanvas({
    required String canvasId,

    required ValueNotifier<double> widthCm,
    required ValueNotifier<double> heightCm,
    required ValueNotifier<String> orientation,

    required ValueNotifier<Color> frontBg,
    required ValueNotifier<Color> backBg,

    required ValueNotifier<String?> frontImage,
    required ValueNotifier<String?> backImage,

    required ValueNotifier<double> frontImageScale,
    required ValueNotifier<Offset> frontImagePosition,
    required ValueNotifier<double> backImageScale,
    required ValueNotifier<Offset> backImagePosition,

    required ValueNotifier<List<TextItem>> frontText,
    required ValueNotifier<List<TextItem>> backText,

    required ValueNotifier<List<GraphicItem>> frontGraphics,
    required ValueNotifier<List<GraphicItem>> backGraphics,

    required ValueNotifier<List<QrItem>> frontQrs,
    required ValueNotifier<List<QrItem>> backQrs,

    required ValueNotifier<List<TableItem>> frontTables,
    required ValueNotifier<List<TableItem>> backTables,
  }) async {
    final data = await DesignCanvasHelper.loadTempCanvas(canvasId);
    if (data == null) return;

    DesignCanvasHelper.applyTemplateData(
      data: data,
      widthCm: widthCm,
      heightCm: heightCm,
      orientation: orientation,
      frontBg: frontBg,
      backBg: backBg,
      frontImage: frontImage,
      backImage: backImage,
      frontImageScale: frontImageScale,
      frontImagePosition: frontImagePosition,
      backImageScale: backImageScale,
      backImagePosition: backImagePosition,
      frontText: frontText,
      backText: backText,
      frontGraphics: frontGraphics,
      backGraphics: backGraphics,
      frontQrs: frontQrs,
      backQrs: backQrs,
      frontTables: frontTables,
      backTables: backTables,
    );
  }

  /// ================= AUTOSAVE =================
  static Future<void> autosave({
    required String canvasId,
    String? templateId,
    String? templateName, // ⭐ ADD

    required ValueNotifier<double> widthCm,
    required ValueNotifier<double> heightCm,
    required ValueNotifier<String> orientation,
    required ValueNotifier<bool> showGrid,

    required ValueNotifier<Color> frontBg,
    required ValueNotifier<Color> backBg,

    required ValueNotifier<String?> frontImage,
    required ValueNotifier<String?> backImage,

    required ValueNotifier<double> frontImageScale,
    required ValueNotifier<Offset> frontImagePosition,
    required ValueNotifier<double> backImageScale,
    required ValueNotifier<Offset> backImagePosition,

    required ValueNotifier<List<TextItem>> frontText,
    required ValueNotifier<List<TextItem>> backText,

    required ValueNotifier<List<GraphicItem>> frontGraphics,
    required ValueNotifier<List<GraphicItem>> backGraphics,

    required ValueNotifier<List<QrItem>> frontQrs,
    required ValueNotifier<List<QrItem>> backQrs,

    required ValueNotifier<List<TableItem>> frontTables,
    required ValueNotifier<List<TableItem>> backTables,
  }) async {
    await DesignCanvasHelper.saveTempCanvas(
      canvasId: canvasId,

      widthCm: widthCm,
      heightCm: heightCm,



      orientation: orientation,
      showGrid: showGrid.value,
      frontBg: frontBg,
      backBg: backBg,
      frontImage: frontImage,
      backImage: backImage,
      frontImageScale: frontImageScale,
      frontImagePosition: frontImagePosition,
      backImageScale: backImageScale,
      backImagePosition: backImagePosition,
      frontText: frontText,
      backText: backText,
      frontGraphics: frontGraphics,
      backGraphics: backGraphics,
      frontQrs: frontQrs,
      backQrs: backQrs,
      frontTables: frontTables,
      backTables: backTables,
    );
  }

  /// ================= TEMPLATE NAME =================
  static Future<String> getNextTemplateName() async {
    final snap = await FirebaseFirestore.instance
        .collection("canvas_templates")
        .orderBy("createdAt", descending: true)

        .get();

    int next = 1;

    for (final d in snap.docs) {
      final name = d.data()['templateName']?.toString() ?? '';
      final match = RegExp(r'Template (\d+)').firstMatch(name);
      if (match != null) {
        final n = int.tryParse(match.group(1)!) ?? 0;
        if (n >= next) next = n + 1;
      }
    }
    return "Template $next";
  }
}
