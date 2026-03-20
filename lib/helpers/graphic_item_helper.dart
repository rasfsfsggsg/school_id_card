import 'package:flutter/material.dart';
import '../models/graphic_item.dart';
import 'graphic_helper/ResizeHelper.dart';
import 'graphic_helper/Rotation_HandleGraphic.dart';
import 'graphic_helper/grafix_popup.dart';
import 'graphic_helper/graphic_icon_helper.dart';
import 'graphic_helper/graphic_line_helper.dart';
import 'graphic_helper/graphic_shape_helper.dart';

class GraphicItemHelper {
  static const double _baseSize = 100;

  /// ================= BUILD =================
  static Widget build({
    required BuildContext context,
    required GraphicItem item,
    required bool selected,
    required VoidCallback onSelect,
    required VoidCallback onDelete,
    required VoidCallback onUpdate,
    required double canvasWidth,
    required double canvasHeight,
    required VoidCallback onDragStart,
    required Function(GraphicItem) addItem,
    required String Function() generateId,
    required void Function(GraphicItem, bool bringToFront) onChangeLayer,
  }) {
    if (!item.isValid) return const SizedBox.shrink();

    final bool isLine = GraphicLineHelper.isLineType(item);
    if (!selected) GraphicPopup.close();

    return Positioned(
      left: item.position.dx,
      top: item.position.dy,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,

        /// SELECT
        onTap: () {
          onSelect();
          GraphicPopup.close();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showPopup(
              context: context,
              item: item,
              onDelete: onDelete,
              onUpdate: onUpdate,
              addItem: addItem,
              generateId: generateId,
              onChangeLayer: onChangeLayer,
            );
          });
        },

        /// DRAG START
        onPanStart: item.locked ? null : (_) => onDragStart(),

        /// DRAG UPDATE
        onPanUpdate: item.locked
            ? null
            : (details) {
          final double itemWidth =
          isLine ? GraphicLineHelper.baseSize * item.scale : item.width;
          final double itemHeight = isLine ? 24 : item.height;
          final double maxX = canvasWidth - itemWidth;
          final double maxY = canvasHeight - itemHeight;

          final newPos = item.position + details.delta;
          item.position = Offset(
            newPos.dx.clamp(0.0, maxX),
            newPos.dy.clamp(0.0, maxY),
          );

          onUpdate();
        },

        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            /// ================= ROTATE + CONTENT =================
            Transform.rotate(
              angle: item.rotation * 3.1415926535 / 180,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  /// MAIN GRAPHIC
                  SizedBox(
                    key: item.boxKey,
                    width: isLine
                        ? GraphicLineHelper.baseSize * item.scale
                        : item.width,
                    height: isLine ? 24 : item.height,
                    child: isLine
                        ? Center(
                      child: SizedBox(
                        height: 4,
                        width: GraphicLineHelper.baseSize * item.scale,
                        child: GraphicLineHelper.buildLine(item: item),
                      ),
                    )
                        : item.type == GraphicType.icon
                        ? GraphicIconHelper.build(item: item)
                        : _buildGraphic(item),
                  ),

                  /// SELECTION BORDER
                  if (selected && !isLine && !item.locked)
                    IgnorePointer(
                      child: Container(
                        width: item.width,
                        height: item.height,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.blue, width: 2),
                        ),
                      ),
                    ),

                  /// RESIZE HANDLES
                  if (selected &&
                      !item.locked &&
                      item.showResizeHandles &&
                      !item.showProtectIcon)
                    _buildResizeHandles(
                      item,
                      isLine,
                      onUpdate,
                      canvasWidth: canvasWidth,
                      canvasHeight: canvasHeight,
                    ),

                  /// PROTECT ICON

                ],
              ),
            ),

            /// ================= ROTATION HANDLE =================
            if (selected && !item.locked && !item.showResizeHandles && !item.showProtectIcon)
              Positioned(
                bottom: -70,
                child: RotationHandleGraphic(
                  item: item,
                  onUpdate: onUpdate,
                  onRotationStart: () {
                    GraphicPopup.close();
                    item.showResizeHandles = false;
                    item.showRotationHandle = true;
                    onUpdate();
                  },
                  onRotationEnd: () {
                    item.showRotationHandle = false;
                    item.showResizeHandles = false;
                    _showPopup(
                      context: context,
                      item: item,
                      onDelete: onDelete,
                      onUpdate: onUpdate,
                      addItem: addItem,
                      generateId: generateId,
                      onChangeLayer: onChangeLayer,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  static Widget _buildResizeHandles(
      GraphicItem item,
      bool isLine,
      VoidCallback onUpdate, {
        required double canvasWidth,
        required double canvasHeight,
      }) {
    return ResizeHelper.build(
      item: item,
      isLine: isLine,
      canvasWidth: canvasWidth,
      canvasHeight: canvasHeight,
      onUpdate: onUpdate,
    );
  }

  static Widget _buildGraphic(GraphicItem item) {
    Widget child;

    if (item.type == GraphicType.image) {
      child = item.imageBytes != null
          ? Image.memory(
        item.imageBytes!,
        width: item.width,
        height: item.height,
        fit: BoxFit.cover,
      )
          : item.imageUrl != null
          ? Image.network(
        item.imageUrl!,
        width: item.width,
        height: item.height,
        fit: BoxFit.cover,
      )
          : const Icon(Icons.image, size: 40);
    } else if (item.type == GraphicType.icon) {
      child = Container(
        width: item.width,
        height: item.height,
        alignment: Alignment.center,
        child: GraphicIconHelper.build(item: item),
      );
    } else {
      child = Container(
        width: item.width,
        height: item.height,
        alignment: Alignment.center,
        child: GraphicShapeHelper.build(item),
      );
    }

    return Container(
      width: item.width,
      height: item.height,
      decoration: BoxDecoration(
        border: item.borderWidth != null && item.borderWidth! > 0
            ? Border.all(
          color: item.borderColor ?? Colors.transparent,
          width: item.borderWidth!,
        )
            : null,
        borderRadius: BorderRadius.circular(item.borderRadius ?? 0),
      ),
      clipBehavior: Clip.hardEdge,
      child: child,
    );
  }

  /// ================= POPUP =================
  static void _showPopup({
    required BuildContext context,
    required GraphicItem item,
    required VoidCallback onDelete,
    required VoidCallback onUpdate,
    required Function(GraphicItem) addItem,
    required String Function() generateId,
    required void Function(GraphicItem, bool bringToFront) onChangeLayer,
  }) {
    GraphicPopup.show(
      context: context,
      item: item,
      onDelete: onDelete,
      onUpdate: onUpdate,
      addItem: addItem,
      generateId: generateId,
      onChangeLayer: onChangeLayer,
    );
  }
}