import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

class BackgroundImageUploader extends StatelessWidget {
  final ValueNotifier<String?> imageUrlNotifier;
  final ValueNotifier<double> scaleNotifier;
  final ValueNotifier<Offset> positionNotifier;
  final ValueNotifier<bool> isUploading; // 🔹 passed from parent

  BackgroundImageUploader({
    super.key,
    required this.imageUrlNotifier,
    required this.scaleNotifier,
    required this.positionNotifier,
    required this.isUploading, // 🔹 parent notifier
  });

  Future<void> _pickAndUpload(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result == null || result.files.isEmpty) return;

      final fileBytes = result.files.first.bytes;
      if (fileBytes == null) return;

      isUploading.value = true; // show canvas overlay

      final base64Image = base64Encode(fileBytes);
      const apiKey = "333a3b74bae238f78922ba5bc75e021c";
      final uri = Uri.parse("https://api.imgbb.com/1/upload?key=$apiKey");

      final response = await http.post(uri, body: {
        'image': base64Image,
        'name': result.files.first.name,
      });

      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        final uploadedUrl = data['data']['url'] as String;
        imageUrlNotifier.value = uploadedUrl;

        debugPrint("Uploaded image URL: $uploadedUrl");

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Background image set")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Image upload failed")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      isUploading.value = false; // hide overlay
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Delete Background Image"),
          content: const Text("Are you sure you want to delete the background image?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      imageUrlNotifier.value = null;
      scaleNotifier.value = 1.0;
      positionNotifier.value = Offset.zero;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Background removed")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 🔹 Upload button
        IconButton(
          tooltip: "Upload Background Image",
          icon: const Icon(Icons.image),
          onPressed: () => _pickAndUpload(context),
        ),

        // 🔹 Background image delete icon
        ValueListenableBuilder<String?>(
          valueListenable: imageUrlNotifier,
          builder: (_, imgUrl, __) {
            if (imgUrl == null) return const SizedBox();

            return Positioned(
              top: 8,
              right: 8,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Tooltip(
                  message: "Delete Image",
                  child: GestureDetector(
                    onTap: () => _confirmDelete(context), // 🔹 show confirmation
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),


      ],
    );
  }
}
