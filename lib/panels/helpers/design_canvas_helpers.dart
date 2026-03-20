import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../common/canvas_side.dart';
import '../../models/graphic_item.dart';
import '../../models/qr_item.dart';
import '../../models/table_item.dart';
import '../../models/text_item.dart';

class DesignCanvasHelper {
  /// =========================================================
  /// CURRENT SIDE GETTERS
  /// =========================================================
  static ValueNotifier<List<TextItem>> currentText({
    required ValueNotifier<CanvasSide> canvasSide,
    required ValueNotifier<List<TextItem>> front,
    required ValueNotifier<List<TextItem>> back,
  }) =>
      canvasSide.value == CanvasSide.front ? front : back;

  static ValueNotifier<List<GraphicItem>> currentGraphics({
    required ValueNotifier<CanvasSide> canvasSide,
    required ValueNotifier<List<GraphicItem>> front,
    required ValueNotifier<List<GraphicItem>> back,
  }) =>
      canvasSide.value == CanvasSide.front ? front : back;

  static ValueNotifier<List<QrItem>> currentQrs({
    required ValueNotifier<CanvasSide> canvasSide,
    required ValueNotifier<List<QrItem>> front,
    required ValueNotifier<List<QrItem>> back,
  }) =>
      canvasSide.value == CanvasSide.front ? front : back;

  static ValueNotifier<List<TableItem>> currentTables({
    required ValueNotifier<CanvasSide> canvasSide,
    required ValueNotifier<List<TableItem>> front,
    required ValueNotifier<List<TableItem>> back,
  }) =>
      canvasSide.value == CanvasSide.front ? front : back;

  static ValueNotifier<Color> currentBg({
    required ValueNotifier<CanvasSide> canvasSide,
    required ValueNotifier<Color> front,
    required ValueNotifier<Color> back,
  }) =>
      canvasSide.value == CanvasSide.front ? front : back;

  static ValueNotifier<String?> currentImage({
    required ValueNotifier<CanvasSide> canvasSide,
    required ValueNotifier<String?> front,
    required ValueNotifier<String?> back,
  }) =>
      canvasSide.value == CanvasSide.front ? front : back;

  static ValueNotifier<double> currentImageScale({
    required ValueNotifier<CanvasSide> canvasSide,
    required ValueNotifier<double> frontScale,
    required ValueNotifier<double> backScale,
  }) =>
      canvasSide.value == CanvasSide.front ? frontScale : backScale;

  static ValueNotifier<Offset> currentImagePosition({
    required ValueNotifier<CanvasSide> canvasSide,
    required ValueNotifier<Offset> frontPos,
    required ValueNotifier<Offset> backPos,
  }) =>
      canvasSide.value == CanvasSide.front ? frontPos : backPos;

  /// =========================================================
  /// SAVE / UPDATE TEMPLATE
  /// =========================================================
  static Future<void> saveTemplate({
    required String templateName,
    required String excelName,
    required String? templateId,

    required List<List<String>> excelData,
    required bool isUpdate,
    required ValueNotifier<double> widthCm,
    required ValueNotifier<double> heightCm,
    required ValueNotifier<String> orientation,
    required bool showGrid,
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
    try {
      final collection = FirebaseFirestore.instance.collection("canvas_templates");

      // Decide doc reference
      late final DocumentReference doc;
      if (isUpdate && templateId != null && templateId.isNotEmpty) {
        doc = collection.doc(templateId);
      } else if (!isUpdate) {
        doc = collection.doc(); // create new doc
      } else {
        throw Exception("templateId required for update");
      }

      final frontJson = {
        "bg": frontBg.value.value,
        "image": frontImage.value,
        "templateId": templateId,   // ⭐ YE LINE ADD HOGI

        "imageScale": frontImageScale.value,
        "imagePosition": {
          "dx": frontImagePosition.value.dx,
          "dy": frontImagePosition.value.dy,
        },
        "texts": frontText.value.map((e) => e.toJson()).toList(),
        "graphics": frontGraphics.value.map((e) => e.toJson()).toList(),
        "qrs": frontQrs.value.map((e) => e.toJson()).toList(),
        "tables": frontTables.value.map((e) => e.toJson()).toList(),
      };

      final backJson = {
        "bg": backBg.value.value,
        "image": backImage.value,
        "imageScale": backImageScale.value,
        "imagePosition": {
          "dx": backImagePosition.value.dx,
          "dy": backImagePosition.value.dy,
        },
        "texts": backText.value.map((e) => e.toJson()).toList(),
        "graphics": backGraphics.value.map((e) => e.toJson()).toList(),
        "qrs": backQrs.value.map((e) => e.toJson()).toList(),
        "tables": backTables.value.map((e) => e.toJson()).toList(),
      };

      // Save final template
      await doc.set({
        "id": doc.id,
        "templateName": templateName,
        "excelName": excelName,
        "excelData": excelData,
        "widthCm": widthCm.value,
        "heightCm": heightCm.value,
        "orientation": orientation.value,
        "showGrid": showGrid,
        "createdAt": FieldValue.serverTimestamp(),
        "isTemporary": false,
        "front": frontJson,
        "back": backJson,
      }, SetOptions(merge: true)); // important: merge to prevent duplicates

      // Save/Update temp canvas with same id
      await saveTempCanvas(
        canvasId: doc.id,
        widthCm: widthCm,
        heightCm: heightCm,
        orientation: orientation,
        showGrid: showGrid,
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
    } catch (e, stack) {
      print("SAVE TEMPLATE ERROR: $e\n$stack");
    }
  }

  /// =========================================================
  /// AUTOSAVE TEMP CANVAS (UPDATED TO USE SAME DOC ID)
  /// =========================================================
  static Future<void> saveTempCanvas({
    required String canvasId,
    required ValueNotifier<double> widthCm,
    required ValueNotifier<double> heightCm,
    required ValueNotifier<String> orientation,
    required bool showGrid,
    String? templateId,   // ⭐ YE ADD KARO

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
    try {
      final doc = FirebaseFirestore.instance.collection("canvas_temp").doc(canvasId);

      final frontJson = {
        "bg": frontBg.value.value,
        "image": frontImage.value,
        "imageScale": frontImageScale.value,
        "imagePosition": {
          "dx": frontImagePosition.value.dx,
          "dy": frontImagePosition.value.dy,
        },
        "texts": frontText.value.map((e) => e.toJson()).toList(),
        "graphics": frontGraphics.value.map((e) => e.toJson()).toList(),
        "qrs": frontQrs.value.map((e) => e.toJson()).toList(),
        "tables": frontTables.value.map((e) => e.toJson()).toList(),
      };

      final backJson = {
        "bg": backBg.value.value,
        "image": backImage.value,
        "imageScale": backImageScale.value,
        "imagePosition": {
          "dx": backImagePosition.value.dx,
          "dy": backImagePosition.value.dy,
        },
        "texts": backText.value.map((e) => e.toJson()).toList(),
        "graphics": backGraphics.value.map((e) => e.toJson()).toList(),
        "qrs": backQrs.value.map((e) => e.toJson()).toList(),
        "tables": backTables.value.map((e) => e.toJson()).toList(),
      };

      await doc.set({
        "id": canvasId,
        "widthCm": widthCm.value,
        "templateId": templateId,   // ⭐ YE ADD KARO

        "heightCm": heightCm.value,
        "orientation": orientation.value,
        "showGrid": showGrid,
        "lastUpdated": FieldValue.serverTimestamp(),
        "expiresAt": Timestamp.fromDate(DateTime.now().add(Duration(hours: 3))),
        "isTemporary": true,
        "front": frontJson,
        "back": backJson,
      }, SetOptions(merge: true)); // merge prevents new duplicates
    } catch (e, stack) {
      print("TEMP SAVE ERROR: $e\n$stack");
    }
  }

  /// =========================================================
  /// DELETE TEMP CANVAS
  /// =========================================================
  static Future<void> deleteTempCanvas(String canvasId) async {
    await FirebaseFirestore.instance.collection("canvas_temp").doc(canvasId).delete();
  }

  /// =========================================================
  /// LOAD TEMP CANVAS
  /// =========================================================
  static Future<Map<String, dynamic>?> loadTempCanvas(String canvasId) async {
    final doc = await FirebaseFirestore.instance.collection("canvas_temp").doc(canvasId).get();
    if (!doc.exists) return null;
    return doc.data();
  }

  /// =========================================================
  /// FETCH FINAL TEMPLATES
  /// =========================================================
  static Future<List<Map<String, dynamic>>> fetchTemplates() async {
    final snap = await FirebaseFirestore.instance
        .collection("canvas_templates")
        .orderBy("createdAt", descending: true)
        .get();
    return snap.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  /// =========================================================
  /// APPLY TEMPLATE DATA TO VALUE NOTIFIERS
  /// =========================================================
  static void applyTemplateData({
    required Map<String, dynamic> data,
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
  }) {
    widthCm.value = (data['widthCm'] ?? 10).toDouble();
    heightCm.value = (data['heightCm'] ?? 10).toDouble();
    orientation.value = data['orientation'] ?? 'portrait';

    // Front
    frontBg.value = Color(data['front']['bg'] ?? 0xFFFFFFFF);
    frontImage.value = data['front']['image'];
    frontImageScale.value = (data['front']['imageScale'] ?? 1.0).toDouble();
    final fPos = data['front']['imagePosition'];
    frontImagePosition.value = Offset(
      (fPos?['dx'] ?? 0).toDouble(),
      (fPos?['dy'] ?? 0).toDouble(),
    );
    frontText.value = ((data['front']['texts'] ?? []) as List)
        .map((e) => TextItem.fromJson(e))
        .toList();
    frontGraphics.value = ((data['front']['graphics'] ?? []) as List)
        .map((e) => GraphicItem.fromJson(e))
        .toList();
    frontQrs.value = ((data['front']['qrs'] ?? []) as List)
        .map((e) => QrItem.fromJson(e))
        .toList();
    frontTables.value = ((data['front']['tables'] ?? []) as List)
        .map((e) => TableItem.fromJson(e))
        .toList();

    // Back
    backBg.value = Color(data['back']['bg'] ?? 0xFFFFFFFF);
    backImage.value = data['back']['image'];
    backImageScale.value = (data['back']['imageScale'] ?? 1.0).toDouble();
    final bPos = data['back']['imagePosition'];
    backImagePosition.value = Offset(
      (bPos?['dx'] ?? 0).toDouble(),
      (bPos?['dy'] ?? 0).toDouble(),
    );
    backText.value = ((data['back']['texts'] ?? []) as List)
        .map((e) => TextItem.fromJson(e))
        .toList();
    backGraphics.value = ((data['back']['graphics'] ?? []) as List)
        .map((e) => GraphicItem.fromJson(e))
        .toList();
    backQrs.value = ((data['back']['qrs'] ?? []) as List)
        .map((e) => QrItem.fromJson(e))
        .toList();
    backTables.value = ((data['back']['tables'] ?? []) as List)
        .map((e) => TableItem.fromJson(e))
        .toList();
  }
}