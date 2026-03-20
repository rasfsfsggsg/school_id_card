import 'package:flutter/material.dart';

import '../../models/table_item.dart';
import '../table_item_helper.dart';

class TablePopup extends StatelessWidget {
  final TableItem item;
  final VoidCallback onDelete;
  final VoidCallback onUpdate;
  final Function(TableItem) onDuplicate;
  final void Function(TableItem, bool bringToFront)? onChangeLayer;

  const TablePopup({
    super.key,
    required this.item,
    required this.onDelete,
    required this.onUpdate,
    required this.onDuplicate,
    this.onChangeLayer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(blurRadius: 8, color: Colors.black26),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [

          /// COPY
          _icon(Icons.copy, () {
            final newItem = item.copyWith(
              position: item.position + const Offset(20, 20),
            );
            onDuplicate(newItem);
            TableItemHelper.closePopup();
          }),

          /// DELETE
          _icon(Icons.delete, () {
            onDelete();
            TableItemHelper.closePopup();
          }),

          /// LOCK / UNLOCK
          _icon(item.locked ? Icons.lock : Icons.lock_open, () {
            item.locked = !item.locked;
            onUpdate();
            TableItemHelper.closePopup();
          }),

          /// RESIZE TOGGLE
          _icon(Icons.crop_free, () {
            item.showResizeHandles = !item.showResizeHandles;
            onUpdate();
          }),

          /// BRING TO FRONT
          _icon(Icons.vertical_align_top, () {
            onChangeLayer?.call(item, true);
            TableItemHelper.closePopup();
          }),

          /// SEND TO BACK
          _icon(Icons.vertical_align_bottom, () {
            onChangeLayer?.call(item, false);
            TableItemHelper.closePopup();
          }),
        ],
      ),
    );
  }

  Widget _icon(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 18),
      ),
    );
  }
}