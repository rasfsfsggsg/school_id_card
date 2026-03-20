import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vista_print24/common/canvas_orientation.dart';

import '../../common/canvas_side.dart';
import '../../models/graphic_item.dart';
import '../../models/qr_item.dart';
import '../../models/table_item.dart';
import '../../models/text_item.dart';
import '../../services/popup_page_preview.dart';
import '../../widgets/design_canvas_container.dart';
import '../../widgets/red_dashed_border.dart';
import '../../widgets/zoom_control_popup.dart';
import '../layers/canvas_layers.dart';

class DesignCanvasViewHelper {
  static const double borderPadding = 10;

  static final List<TextItem> selectedItems = [];
  static final List<QrItem> selectedQrItems = [];
  static final List<TableItem> selectedTableItems = [];
  static final List<GraphicItem> selectedGraphicItems = [];

  // ===========================
  // CANVAS LAYERS
  // ===========================
  static Widget buildCanvasLayers({
    required CanvasSide canvasSide,
    required ValueNotifier<bool> showGrid,
    required ValueNotifier<String?> backgroundImage,
    required ValueNotifier<double> imageScale,
    required ValueNotifier<Offset> imagePosition,
    required ValueNotifier<List<TextItem>> textItems,
    required ValueNotifier<List<GraphicItem>> graphics,
    required ValueNotifier<List<QrItem>> qrs,
    required ValueNotifier<List<TableItem>> tables,
    required String? selectedTextId,
    required String? selectedGraphicId,
    required String? selectedQrId,
    required String? selectedTableId,
    required VoidCallback onClearSelection,
    required Function(String) onSelectText,
    required Function(String) onSelectGraphic,
    required Function(String) onSelectQr,
    required Function(String) onSelectTable,
    required ValueNotifier<bool> imageEditEnabled,
    required double canvasW,
    required double canvasH,
    required ValueNotifier<List<List<String>>> excelDataNotifier,
  }) {
    return ValueListenableBuilder<bool>(
      valueListenable: showGrid,
      builder: (_, grid, __) {
        return CanvasLayers(
          widthPx: canvasW,
          heightPx: canvasH,
          showGrid: grid,
          backgroundImage: backgroundImage,
          imageScale: imageScale,
          imagePosition: imagePosition,
          textItems: textItems,
          graphics: graphics,
          qrs: qrs,
          tables: tables,
          selectedTextId: selectedTextId,
          selectedGraphicId: selectedGraphicId,
          selectedQrId: selectedQrId,
          selectedTableId: selectedTableId,
          onClearSelection: onClearSelection,
          onSelectText: onSelectText,
          onSelectGraphic: onSelectGraphic,
          onSelectQr: onSelectQr,
          onSelectTable: onSelectTable,
          imageEditEnabled: imageEditEnabled,
          excelDataNotifier: excelDataNotifier,
        );
      },
    );
  }

  // ===========================
  // MAIN CANVAS
  // ===========================
  static Widget buildMainCanvas({
    required BuildContext context,
    required GlobalKey canvasKey,
    required double zoom,
    bool showZoomPopup = false,
    required ValueNotifier<bool> imageEditEnabled,
    required ValueNotifier<bool> isUploading,
    required ValueNotifier<double> widthCm,
    required ValueNotifier<double> heightCm,
    required ValueNotifier<Color> backgroundColor,
    required ValueNotifier<String?> backgroundImage,
    required ValueNotifier<double> imageScale,
    required ValueNotifier<Offset> imagePosition,
    required ValueChanged<double> onZoomChange,
    required Widget Function(double w, double h) buildLayers,
    required CanvasOrientation orientation,
    required ValueNotifier<List<TextItem>> textItems,
    required ValueNotifier<List<GraphicItem>> graphics,
    required ValueNotifier<List<QrItem>> qrs,
    required ValueNotifier<List<TableItem>> tables,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Focus(
          autofocus: true,
          child: Listener(
            onPointerSignal: (signal) {
              if (!imageEditEnabled.value) return;

              if (signal is PointerScrollEvent) {
                final delta = signal.scrollDelta.dy;
                final change = delta > 0 ? -0.05 : 0.05;
                imageScale.value =
                    (imageScale.value + change).clamp(0.2, 5.0);
              }
            },
            child: GestureDetector(
              onScaleUpdate: (details) {
                if (!imageEditEnabled.value) return;
                if (details.scale != 1) {
                  onZoomChange(details.scale);
                }
              },
              child: VLB2<double, double>(
                first: widthCm,
                second: heightCm,
                builder: (_, w, h, __) {
                  final availableWidth = constraints.maxWidth;
                  final availableHeight = constraints.maxHeight;

                  final scaleX = availableWidth / w;
                  final scaleY = availableHeight / h;
                  final scale = scaleX < scaleY ? scaleX : scaleY;

                  final canvasWidthPx = (w * scale);
                  final canvasHeightPx = (h * scale);

                  final innerWidth =
                      canvasWidthPx - 2 * borderPadding;
                  final innerHeight =
                      canvasHeightPx - 2 * borderPadding;

                  return Stack(
                    alignment: Alignment.topLeft,
                    children: [
                      Transform.scale(
                        alignment: Alignment.topLeft,
                        scale: zoom,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            RedDashedBorder(
                              widthPx: canvasWidthPx,
                              heightPx: canvasHeightPx,
                              widthCm: w,
                              heightCm: h,
                              showLabels: true,
                            ),
                            RepaintBoundary(
                              key: canvasKey,
                              child: VLB4<
                                  List<TextItem>,
                                  List<GraphicItem>,
                                  List<QrItem>,
                                  List<TableItem>>(
                                first: textItems,
                                second: graphics,
                                third: qrs,
                                fourth: tables,
                                builder: (_, updatedTextItems,
                                    updatedGraphics,
                                    updatedQrItems,
                                    updatedTables,
                                    __) {
                                  return DesignCanvasContainer(
                                    zoom: zoom,
                                    orientation: orientation,
                                    width: innerWidth,
                                    height: innerHeight,
                                    allTextItems: updatedTextItems,
                                    selectedTextItems: selectedItems,
                                    allGraphicItems: updatedGraphics,
                                    selectedGraphicItems:
                                    selectedGraphicItems,
                                    allQrItems: updatedQrItems,
                                    selectedQrItems:
                                    selectedQrItems,
                                    allTableItems: updatedTables,
                                    selectedTableItems:
                                    selectedTableItems,
                                    backgroundColor:
                                    backgroundColor.value,
                                    showBlueBorder: false,
                                    imageScale: imageScale,
                                    imagePosition: imagePosition,
                                    onUpdate: () {
                                      textItems.notifyListeners();
                                      graphics.notifyListeners();
                                      qrs.notifyListeners();
                                      tables.notifyListeners();
                                    },
                                    child:
                                    buildLayers(innerWidth, innerHeight),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (showZoomPopup)
                        Positioned(
                          top: 20,
                          right: 20,
                          child: ZoomControlPopup(
                            zoom: zoom,
                            onZoomChanged: onZoomChange,
                          ),
                        ),
                      ValueListenableBuilder<bool>(
                        valueListenable: isUploading,
                        builder: (_, uploading, __) {
                          if (!uploading)
                            return const SizedBox();

                          return Positioned.fill(
                            child: Container(
                              alignment: Alignment.center,
                              child: const Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(
                                    valueColor:
                                    AlwaysStoppedAnimation<Color>(
                                      Colors.black,
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    "Loading...",
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 16,
                                      fontWeight:
                                      FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class VLB2<A, B> extends StatelessWidget {
  final ValueNotifier<A> first;
  final ValueNotifier<B> second;
  final Widget Function(BuildContext, A, B, Widget?) builder;

  const VLB2({
    super.key,
    required this.first,
    required this.second,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<A>(
      valueListenable: first,
      builder: (_, a, __) {
        return ValueListenableBuilder<B>(
          valueListenable: second,
          builder: (_, b, ___) =>
              builder(context, a, b, null),
        );
      },
    );
  }
}

class VLB4<A, B, C, D> extends StatelessWidget {
  final ValueNotifier<A> first;
  final ValueNotifier<B> second;
  final ValueNotifier<C> third;
  final ValueNotifier<D> fourth;

  final Widget Function(
      BuildContext, A, B, C, D, Widget?) builder;

  const VLB4({
    super.key,
    required this.first,
    required this.second,
    required this.third,
    required this.fourth,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<A>(
      valueListenable: first,
      builder: (_, a, __) {
        return ValueListenableBuilder<B>(
          valueListenable: second,
          builder: (_, b, ___) {
            return ValueListenableBuilder<C>(
              valueListenable: third,
              builder: (_, c, ____) {
                return ValueListenableBuilder<D>(
                  valueListenable: fourth,
                  builder: (_, d, _____) =>
                      builder(context, a, b, c, d, null),
                );
              },
            );
          },
        );
      },
    );
  }
}