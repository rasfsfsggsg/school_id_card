import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:image_cropper/image_cropper.dart';

import '../models/graphic_item.dart';
import '../models/excel_cell_selection.dart';

class UploadsPanelPage extends StatefulWidget {
  final ValueNotifier<List<GraphicItem>> graphics;
  final ValueNotifier<List<List<String>>> excelDataNotifier;
  final ValueNotifier<ExcelCellSelection?> selectedExcelCell;

  const UploadsPanelPage({
    super.key,
    required this.graphics,
    required this.excelDataNotifier,
    required this.selectedExcelCell,
  });

  @override
  State<UploadsPanelPage> createState() => _UploadsPanelPageState();
}

class _UploadsPanelPageState extends State<UploadsPanelPage> {
  final _uuid = const Uuid();

  int? _imageNameCol;
  int? _imageUrlCol;

  /// 🔹 UI-only mapping (NO backend)
  final Map<String, int> _imageNameColumnMap = {};

  @override
  void initState() {
    super.initState();

    widget.selectedExcelCell.addListener(() {
      final cell = widget.selectedExcelCell.value;
      if (cell != null) {
        _updateImagesFromExcel(cell);
      }
    });
  }

  // ============================================================
  // 1️⃣ SIMPLE IMAGE UPLOAD
  // ============================================================
  Future<void> _uploadSimpleImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result == null || result.files.first.bytes == null) return;

    widget.graphics.value = [
      ...widget.graphics.value,
      GraphicItem(
        id: _uuid.v4(),
        type: GraphicType.image,
        imageBytes: result.files.first.bytes,
        position: const Offset(150, 150),
      ),
    ];

    widget.graphics.notifyListeners();
  }

  // ============================================================
  // 2️⃣ UPDATE IMAGE + NAME FROM EXCEL ROW
  // ============================================================
  void _updateImagesFromExcel(ExcelCellSelection cell) {
    final excel = widget.excelDataNotifier.value;
    if (excel.isEmpty) return;
    if (cell.row < 0 || cell.row >= excel.length) return;

    final row = excel[cell.row];

    for (int i = 0; i < widget.graphics.value.length; i++) {
      final g = widget.graphics.value[i];

      if (!g.excelBound || g.excelColumn == null) continue;

      final imgCol = g.excelColumn!.codeUnitAt(0) - 65;
      if (imgCol < 0 || imgCol >= row.length) continue;

      final nameCol = _imageNameColumnMap[g.id];
      final name =
      (nameCol != null && nameCol < row.length) ? row[nameCol] : g.name;

      // ✅ Preserve existing border and scale
      widget.graphics.value[i] = g.copyWith(
        imageUrl: row[imgCol],  // Excel se nayi image
        name: name,             // Excel se naya name
        borderColor: g.borderColor, // Purana borderColor preserve
        borderWidth: g.borderWidth, // Purana borderWidth preserve
        scale: g.scale,             // Scale preserve
        rotation: g.rotation,       // Rotation preserve
      );
    }

    widget.graphics.notifyListeners();
  }

  // ============================================================
  // 3️⃣ BIND IMAGE (NAME + URL)
  // ============================================================
  Future<void> _bindExcelColumns() async {
    final excel = widget.excelDataNotifier.value;
    if (excel.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Excel data empty")),
      );
      return;
    }

    final headers = excel.first;

    await showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Bind Image from Excel"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: "Image Name Column",
                      border: OutlineInputBorder(),
                    ),
                    value: _imageNameCol,
                    items: List.generate(headers.length, (i) {
                      return DropdownMenuItem(
                        value: i,
                        child: Text(
                          "${String.fromCharCode(65 + i)} : ${headers[i]}",
                        ),
                      );
                    }),
                    onChanged: (v) => setState(() => _imageNameCol = v),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: "Image URL Column",
                      border: OutlineInputBorder(),
                    ),
                    value: _imageUrlCol,
                    items: List.generate(headers.length, (i) {
                      return DropdownMenuItem(
                        value: i,
                        child: Text(
                          "${String.fromCharCode(65 + i)} : ${headers[i]}",
                        ),
                      );
                    }),
                    onChanged: (v) => setState(() => _imageUrlCol = v),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed:
                  (_imageNameCol != null && _imageUrlCol != null)
                      ? () {
                    _createExcelBoundImage(
                      _imageNameCol!,
                      _imageUrlCol!,
                    );
                    Navigator.pop(context);
                  }
                      : null,
                  child: const Text("Bind"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // 4️⃣ CREATE IMAGE GRAPHIC
  // ============================================================
  void _createExcelBoundImage(int nameCol, int urlCol) {
    final excel = widget.excelDataNotifier.value;
    if (excel.length < 2) return;

    final row = excel[1];
    final id = _uuid.v4();

    _imageNameColumnMap[id] = nameCol;

    final graphic = GraphicItem(
      id: id,
      type: GraphicType.image,
      name: row[nameCol],
      imageUrl: row[urlCol],
      borderColor: Colors.blue,  // default border only first time
      borderWidth: 2,
      excelBound: true,
      excelColumn: String.fromCharCode(65 + urlCol),
      position: const Offset(150, 150),
    );

    widget.graphics.value = [...widget.graphics.value, graphic];
    widget.graphics.notifyListeners();
  }

  // ============================================================
  // 5️⃣ CROP IMAGE FUNCTION
  // ============================================================
  Future<Uint8List?> _cropImage(Uint8List imageBytes) async {
    // Save bytes temporarily
    final tempDir = await getTemporaryDirectory();
    final tempFile = await File('${tempDir.path}/${_uuid.v4()}.png').writeAsBytes(imageBytes);

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: tempFile.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          lockAspectRatio: false,
        ),
        IOSUiSettings(
          title: 'Crop Image',
        ),
      ],
    );

    if (croppedFile != null) {
      return await croppedFile.readAsBytes();
    }
    return null;
  }

  // ============================================================
  // UI
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  "Uploads",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _uploadSimpleImage,
                    icon: const Icon(Icons.upload_file, color: Colors.white),
                    label: const Text(
                      "Upload Image",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _bindExcelColumns,
                    icon: const Icon(Icons.table_chart, color: Colors.white),
                    label: const Text(
                      "Bind Image from Sheet",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),
              ],
            ),
          ),

          // ============================================================
          // 6️⃣ SHOW IMAGES IN GRID BOX WITH CROP ON TAP
          // ============================================================
          Expanded(
            child: ValueListenableBuilder<List<GraphicItem>>(
              valueListenable: widget.graphics,
              builder: (context, graphics, _) {
                if (graphics.isEmpty) {
                  return const Center(child: Text("No images uploaded yet"));
                }

                return Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1,
                    ),
                    itemCount: graphics.length,
                    itemBuilder: (context, index) {
                      final g = graphics[index];
                      return GestureDetector(
                        onTap: () async {
                          if (g.imageBytes != null) {
                            final cropped = await _cropImage(g.imageBytes!);
                            if (cropped != null) {
                              widget.graphics.value[index] =
                                  g.copyWith(imageBytes: cropped);
                              widget.graphics.notifyListeners();
                            }
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.black12),
                            boxShadow: const [
                              BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: Offset(2, 2)),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: g.imageBytes != null
                                ? Image.memory(g.imageBytes!, fit: BoxFit.cover)
                                : g.imageUrl != null
                                ? Image.network(g.imageUrl!,
                                fit: BoxFit.cover)
                                : const Icon(Icons.image, size: 40),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}