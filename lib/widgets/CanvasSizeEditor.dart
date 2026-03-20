import 'package:flutter/material.dart';

class CanvasSizeEditor extends StatefulWidget {
  final double initialWidth;
  final double initialHeight;
  final void Function(double width, double height) onUpdate;

  const CanvasSizeEditor({
    super.key,
    required this.initialWidth,
    required this.initialHeight,
    required this.onUpdate, required initialUnit,
  });

  @override
  State<CanvasSizeEditor> createState() => _CanvasSizeEditorState();
}

class _CanvasSizeEditorState extends State<CanvasSizeEditor> {
  late TextEditingController wController;
  late TextEditingController hController;

  @override
  void initState() {
    super.initState();
    wController = TextEditingController(text: widget.initialWidth.toString());
    hController = TextEditingController(text: widget.initialHeight.toString());
  }

  @override
  void dispose() {
    wController.dispose();
    hController.dispose();
    super.dispose();
  }

  void _submit() {
    final w = double.tryParse(wController.text);
    final h = double.tryParse(hController.text);

    if (w != null && h != null && w > 0 && h > 0) {
      widget.onUpdate(w, h);
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter valid size!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Edit Canvas Size (cm)"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: wController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Width"),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: hController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Height"),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text("Update"),
        ),
      ],
    );
  }
}
