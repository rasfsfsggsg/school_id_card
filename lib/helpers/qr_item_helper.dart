
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/qr_item.dart';
import 'QR_HELP/Rotation_Handle.dart';
import 'QR_HELP/qr_popup.dart';
import 'QR_HELP/qr_resize_handles.dart';
import '../panels/cate/open_ColorPicker.dart';

class QrItemHelper {

  // ================== BUILD ==================
  static Widget build({
    required BuildContext context,
    required QrItem item,
    required bool selected,
    required VoidCallback onSelect,
    required VoidCallback onDelete,
    required VoidCallback onCopy,
    required VoidCallback onUpdate,
    required VoidCallback onDragStart,
    required double canvasWidth, // Canvas bounds
    required double canvasHeight, // Canvas bounds
    required void Function(QrItem item, bool bringToFront) onChangeLayer,
  }) {
    return Positioned(
      left: item.position.dx,
      top: item.position.dy,
      child: CompositedTransformTarget(
        link: item.layerLink,
        child: GestureDetector(
          onTap: () {
            onSelect();
            QrPopup.close();

            WidgetsBinding.instance.addPostFrameCallback((_) {
              QrPopup.show(
                context: context,
                item: item,
                onDelete: onDelete,
                onCopy: onCopy,
                onUpdate: onUpdate,
                onToggleResize: () {
                  QrPopup.showResizeHandles = !QrPopup.showResizeHandles;
                  onUpdate();
                },
                onChangeLayer: onChangeLayer,
              );
            });
          },

          // ================= DRAG =================
          onPanStart: item.locked
              ? null
              : (_) {
            onDragStart();
            QrPopup.close();
          },

          onPanUpdate: item.locked
              ? null
              : (details) {
            final maxX = canvasWidth - item.width;
            final maxY = canvasHeight - item.height;

            final newPos = item.position + details.delta;

            item.position = Offset(
              newPos.dx.clamp(0.0, maxX),
              newPos.dy.clamp(0.0, maxY),
            );

            onUpdate();
          },

          onPanEnd: item.locked
              ? null
              : (_) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              QrPopup.show(
                context: context,
                item: item,
                onDelete: onDelete,
                onCopy: onCopy,
                onUpdate: onUpdate,
                onToggleResize: () {
                  QrPopup.showResizeHandles = !QrPopup.showResizeHandles;
                  onUpdate();
                },
                onChangeLayer: onChangeLayer,
              );
            });
          },

          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [

              // ================= ROTATE + CONTENT =================
              Transform.rotate(
                angle: item.rotation * math.pi / 180,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [

                    SizedBox(
                      key: item.boxKey,
                      width: item.width,
                      height: item.height,
                      child: Container(
                        decoration: BoxDecoration(
                          border: item.borderWidth != null && item
                              .borderWidth! > 0
                              ? Border.all(
                            color: item.borderColor ?? Colors.black,
                            width: item.borderWidth!,
                          )
                              : null,
                          borderRadius: BorderRadius.circular(item
                              .borderRadius ?? 0),
                        ),
                        clipBehavior: Clip.hardEdge,
                        child: FittedBox(
                          fit: BoxFit.fill,
                          child: QrImageView(
                            data: item.data,
                            size: 1000,
                            foregroundColor: item.color,
                          ),
                        ),
                      ),
                    ),

                    /// Selection Border
                    if (selected)
                      Container(
                        width: item.width,
                        height: item.height,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.blue,
                            width: 2,
                          ),
                        ),
                      ),

                    /// Resize Handles
                    if (selected && QrPopup.showResizeHandles)
                      ResizeHandles(
                        width: item.width,
                        height: item.height,
                        rotation: item.rotation,
                        onUpdateSize: (newWidth, newHeight, shiftX, shiftY, handleType) {

                          double newX = item.position.dx;
                          double newY = item.position.dy;

                          final oldRight = item.position.dx + item.width;
                          final oldBottom = item.position.dy + item.height;

                          switch (handleType) {

                            case HandleType.middleLeft:
                              newX = oldRight - newWidth;
                              break;

                            case HandleType.middleRight:
                              newX = item.position.dx;
                              break;

                            case HandleType.middleTop:
                              newY = oldBottom - newHeight;
                              break;

                            case HandleType.middleBottom:
                              newY = item.position.dy;
                              break;

                            case HandleType.topLeft:
                              newX = oldRight - newWidth;
                              newY = oldBottom - newHeight;
                              break;

                            case HandleType.topRight:
                              newX = item.position.dx;
                              newY = oldBottom - newHeight;
                              break;

                            case HandleType.bottomLeft:
                              newX = oldRight - newWidth;
                              newY = item.position.dy;
                              break;

                            case HandleType.bottomRight:
                              newX = item.position.dx;
                              newY = item.position.dy;
                              break;
                          }

                          item.width = newWidth;
                          item.height = newHeight;
                          item.position = Offset(newX, newY);

                          onUpdate();
                        },
                      ),
                  ],
                ),
              ),

              /// ROTATION HANDLE
              if (selected && !item.locked)
                Positioned(
                  bottom: -55,
                  child: QrRotationHandle(
                    item: item,

                    /// rotation start hides popup
                    onRotationStart: () {
                      QrPopup.close();
                    },

                    /// rotation update
                    onUpdate: onUpdate,

                    /// rotation end shows popup again
                    onRotationEnd: () {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        QrPopup.show(
                          context: context,
                          item: item,
                          onDelete: onDelete,
                          onCopy: onCopy,
                          onUpdate: onUpdate,
                          onToggleResize: () {
                            QrPopup.showResizeHandles =
                            !QrPopup.showResizeHandles;
                            onUpdate();
                          },
                          onChangeLayer: onChangeLayer,
                        );
                      });
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}