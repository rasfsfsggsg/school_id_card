import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SaveTemplatePopup {
  /// Shows the save template dialog
  /// [context] -> BuildContext
  /// [onSave] -> Callback with the template name when user confirms
  static Future<void> show(
      {required BuildContext context,
        required Future<void> Function(String name) onSave}) async {
    final TextEditingController nameController = TextEditingController();

    // Get last template to auto-increment number
    final lastTemplate = await _getLastTemplate();
    int defaultNumber = 1;

    if (lastTemplate != null && lastTemplate['name'] != null) {
      final name = lastTemplate['name'] as String;
      if (name.startsWith('Template ')) {
        final numPart = int.tryParse(name.split(' ').last);
        if (numPart != null) defaultNumber = numPart + 1;
      }
    }

    nameController.text = "Template $defaultNumber";

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Save Template"),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: "Template Name",
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Cancel")),
            ElevatedButton(
                onPressed: () async {
                  final templateName = nameController.text.trim();
                  if (templateName.isEmpty) return;
                  await onSave(templateName);
                  Navigator.of(context).pop();
                },
                child: const Text("Save")),
          ],
        );
      },
    );
  }

  /// Helper to get the last saved template
  static Future<Map<String, dynamic>?> _getLastTemplate() async {
    final snap = await FirebaseFirestore.instance
        .collection("canvas_templates")
        .orderBy("createdAt", descending: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return snap.docs.first.data();
  }
}
