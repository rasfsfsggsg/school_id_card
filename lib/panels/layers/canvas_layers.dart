import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../../models/text_item.dart';
import '../../models/graphic_item.dart';
import '../../models/qr_item.dart';
import '../../models/table_item.dart';
import 'dart:math' as math;

import '../../helpers/text_item_helper.dart';
import '../../helpers/graphic_item_helper.dart';
import '../../helpers/qr_item_helper.dart';
import '../../helpers/table_item_helper.dart';
import '../excel_column_popup.dart';

class CanvasLayers extends StatelessWidget {
  final double widthPx;
  final double heightPx;
  final bool showGrid;

  final ValueNotifier<String?> backgroundImage;
  final ValueNotifier<double> imageScale;
  final ValueNotifier<Offset> imagePosition;
  final ValueNotifier<bool> imageEditEnabled;

  // ✅ FIXED: Properly Declared Notifiers
  final ValueNotifier<List<TextItem>> textItems;
  final ValueNotifier<List<GraphicItem>> graphics;
  final ValueNotifier<List<QrItem>> qrs;
  final ValueNotifier<List<TableItem>> tables;

  final ValueNotifier<List<List<String>>> excelDataNotifier;

  final String? selectedTextId;
  final String? selectedGraphicId;
  final String? selectedQrId;
  final String? selectedTableId;

  final Function(String id) onSelectText;
  final Function(String id) onSelectGraphic;
  final Function(String id) onSelectQr;
  final Function(String id) onSelectTable;

  final VoidCallback onClearSelection;

  const CanvasLayers({
    super.key,
    required this.widthPx,
    required this.heightPx,
    required this.showGrid,
    required this.backgroundImage,
    required this.imageScale,
    required this.imagePosition,
    required this.imageEditEnabled,
    required this.textItems,
    required this.graphics,
    required this.qrs,
    required this.tables,
    required this.excelDataNotifier,
    required this.selectedTextId,
    required this.selectedGraphicId,
    required this.selectedQrId,
    required this.selectedTableId,
    required this.onSelectText,
    required this.onSelectGraphic,
    required this.onSelectQr,
    required this.onSelectTable,
    required this.onClearSelection,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widthPx,
      height: heightPx,
      child: ClipRect(
        child: Stack(
          children: [

            /// Tap to clear selection
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onClearSelection,
              ),
            ),

            Stack(
              children: [
                _backgroundImageLayer(),
                _unifiedLayer(context),

                if (showGrid) _gridOverlay(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ================= BACKGROUND =================
  Widget _backgroundImageLayer() {
    return ValueListenableBuilder<String?>(
      valueListenable: backgroundImage,
      builder: (_, img, __) {
        if (img == null || img.isEmpty) return const SizedBox.shrink();

        return ValueListenableBuilder3<double, Offset, bool>(
          first: imageScale,
          second: imagePosition,
          third: imageEditEnabled,
          builder: (_, scale, offset, enabled, __) {
            Widget imageWidget = kIsWeb
                ? Image.network(img,
                fit: BoxFit.cover,
                width: widthPx,
                height: heightPx)
                : Image.file(File(img),
                fit: BoxFit.cover,
                width: widthPx,
                height: heightPx);

            if (enabled) {
              return Positioned(
                left: offset.dx,
                top: offset.dy,
                child: GestureDetector(
                  onScaleUpdate: (details) {
                    imageScale.value =
                        (imageScale.value * details.scale).clamp(0.5, 6.0);
                    imagePosition.value += details.focalPointDelta;
                  },
                  child: Transform.scale(
                    scale: scale,
                    child: imageWidget,
                  ),
                ),
              );
            } else {
              return Positioned.fill(
                child: Transform.scale(
                  scale: scale,
                  child: imageWidget,
                ),
              );
            }
          },
        );
      },
    );
  }

  // ================= GRID =================
  Widget _gridOverlay() {
    return IgnorePointer(
      child: CustomPaint(
        painter: _GridPainter(),
        size: Size(widthPx, heightPx),
      ),
    );
  }

  // ================= GRAPHICS =================
  Widget _unifiedLayer(BuildContext context) {
    return ValueListenableBuilder4<
        List<GraphicItem>,
        List<QrItem>,
        List<TableItem>,
        List<TextItem>>(
      first: graphics,
      second: qrs,
      third: tables,
      fourth: textItems,
      builder: (_, graphicList, qrList, tableList, textList, __) {

        /// 🔥 Combine all items
        final List<dynamic> allItems = [
          ...graphicList,
          ...qrList,
          ...tableList,
          ...textList,
        ];

        /// 🔥 Sort by zIndex
        allItems.sort((a, b) => a.zIndex.compareTo(b.zIndex));

        return Stack(
          children: allItems.map((item) {

            /// ================= GRAPHIC =================
            if (item is GraphicItem) {
              return GraphicItemHelper.build(
                canvasWidth: widthPx,
                canvasHeight: heightPx,
                context: context,
                item: item,
                selected: selectedGraphicId == item.id,
                onSelect: () => onSelectGraphic(item.id),
                onDelete: () {
                  graphics.value =
                      graphics.value.where((e) => e.id != item.id).toList();
                  graphics.notifyListeners();
                  onClearSelection();
                },
                onUpdate: graphics.notifyListeners,
                onDragStart: () {},
                addItem: (newItem) {
                  final maxZ = _getMaxZ(allItems);
                  newItem.zIndex = maxZ + 1;
                  graphics.value = [...graphics.value, newItem];
                  graphics.notifyListeners();
                },
                generateId: () =>
                    DateTime.now().millisecondsSinceEpoch.toString(), onChangeLayer: (graphicItem, bringToFront) {
                final maxZ = _getMaxZ(allItems);
                final minZ = _getMinZ(allItems);

                graphicItem.zIndex =
                bringToFront ? maxZ + 1 : minZ - 1;

                graphics.notifyListeners();
              },
              );
            }

            /// ================= QR =================
            if (item is QrItem) {
              return QrItemHelper.build(
                canvasWidth: widthPx,
                canvasHeight: heightPx,
                context: context,
                item: item,
                selected: selectedQrId == item.id,
                onSelect: () => onSelectQr(item.id),
                onDelete: () {
                  qrs.value =
                      qrs.value.where((e) => e.id != item.id).toList();
                  qrs.notifyListeners();
                  onClearSelection();
                },
                onCopy: () {
                  final maxZ = _getMaxZ(allItems);
                  final newQr = item.copyWith(
                    id: UniqueKey().toString(),
                    position: item.position + const Offset(20, 20),
                    zIndex: maxZ + 1,
                  );
                  qrs.value = [...qrs.value, newQr];
                  qrs.notifyListeners();
                },
                onUpdate: qrs.notifyListeners,
                onDragStart: () {}, onChangeLayer: (qrItem, bringToFront) {
                final maxZ = _getMaxZ(allItems);
                final minZ = _getMinZ(allItems);

                qrItem.zIndex =
                bringToFront ? maxZ + 1 : minZ - 1;

                qrs.notifyListeners();
              },
              );
            }

            /// ================= TABLE =================
            if (item is TableItem) {
              return TableItemHelper.build(
                canvasWidth: widthPx,
                canvasHeight: heightPx,
                context: context,
                item: item,
                selected: selectedTableId == item.id,
                onSelect: () => onSelectTable(item.id),
                onDelete: () {
                  tables.value =
                      tables.value.where((e) => e.id != item.id).toList();
                  tables.notifyListeners();
                  onClearSelection();
                },
                onUpdate: tables.notifyListeners,
                onDragStart: () {},
                onDuplicate: (newItem) {
                  final maxZ = _getMaxZ(allItems);
                  newItem.zIndex = maxZ + 1;
                  tables.value = [...tables.value, newItem];
                  tables.notifyListeners();
                  onSelectTable(newItem.id);
                }, onChangeLayer: (tableItem, bringToFront) {
                final maxZ = _getMaxZ(allItems);
                final minZ = _getMinZ(allItems);

                tableItem.zIndex =
                bringToFront ? maxZ + 1 : minZ - 1;

                tables.notifyListeners();
              },
              );
            }

            /// ================= TEXT =================
            if (item is TextItem) {
              return TextItemHelper.build(
                canvasWidth: widthPx,
                canvasHeight: heightPx,

                context: context,
                item: item,
                selected: selectedTextId == item.id,
                isMultiSelection: false,
                onSelect: () => onSelectText(item.id),
                onUpdate: textItems.notifyListeners,
                onDelete: () {
                  textItems.value =
                      textItems.value.where((e) => e.id != item.id).toList();
                  textItems.notifyListeners();
                  onClearSelection();
                },
                onDuplicate: () {
                  final maxZ = _getMaxZ(allItems);
                  final copy = item.copyWith(
                    id: UniqueKey().toString(),
                    position: item.position + const Offset(20, 20),
                    zIndex: maxZ + 1,
                  );
                  textItems.value = [...textItems.value, copy];
                  textItems.notifyListeners();
                  onSelectText(copy.id);
                },
                onChangeLayer: (item, bringToFront) {
                  final maxZ = _getMaxZ(allItems);
                  final minZ = _getMinZ(allItems);

                  item.zIndex =
                  bringToFront ? maxZ + 1 : minZ - 1;

                  textItems.notifyListeners();
                },
                onExcelPopup: (item) {
                  final firstRow =
                  excelDataNotifier.value.isNotEmpty
                      ? List<String>.from(
                      excelDataNotifier.value[0])
                      : <String>[];

                  showDialog(
                    context: context,
                    builder: (_) => ExcelColumnPopup(
                      textItem: item,
                      firstRow: firstRow,
                      onClose: () {
                        textItems.notifyListeners();
                      },
                    ),
                  );
                },
                maxWidth: widthPx - 10,
                onDragStart: () {},
              );
            }

            return const SizedBox();
          }).toList(),
        );
      },
    );
  }
  int _getMaxZ(List<dynamic> list) {
    if (list.isEmpty) return 0;

    int maxZ = list.first.zIndex;
    for (var item in list) {
      if (item.zIndex > maxZ) {
        maxZ = item.zIndex;
      }
    }
    return maxZ;
  }

  int _getMinZ(List<dynamic> list) {
    if (list.isEmpty) return 0;

    int minZ = list.first.zIndex;
    for (var item in list) {
      if (item.zIndex < minZ) {
        minZ = item.zIndex;
      }
    }
    return minZ;
  }
}
class ValueListenableBuilder4<A, B, C, D> extends StatelessWidget {
  final ValueNotifier<A> first;
  final ValueNotifier<B> second;
  final ValueNotifier<C> third;
  final ValueNotifier<D> fourth;

  final Widget Function(
      BuildContext, A, B, C, D, Widget?) builder;

  const ValueListenableBuilder4({
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
// ================= GRID PAINTER =================
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black12
      ..strokeWidth = 0.5;

    const step = 20.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ================= ValueListenableBuilder3 =================
class ValueListenableBuilder3<A, B, C> extends StatelessWidget {
  final ValueNotifier<A> first;
  final ValueNotifier<B> second;
  final ValueNotifier<C> third;
  final Widget Function(BuildContext, A, B, C, Widget?) builder;

  const ValueListenableBuilder3({
    super.key,
    required this.first,
    required this.second,
    required this.third,
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
              builder: (_, c, ____) =>
                  builder(context, a, b, c, null),
            );
          },
        );
      },
    );
  }
}