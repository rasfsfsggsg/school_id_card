import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/text_item.dart';
import '../models/qr_item.dart';
import '../models/graphic_item.dart';
import '../models/table_item.dart';

class TemplatePanelPage extends StatefulWidget {
  final void Function({
  required String templateId,
  required String templateName, // 🔥 ADD

  required double widthCm,
  required double heightCm,
  required bool showGrid,
  required Color frontBg,
  required Color backBg,
  required String? frontImage,
  required Offset frontImagePosition,
  required double frontImageScale,
  required String? backImage,
  required Offset backImagePosition,
  required double backImageScale,
  required List<TextItem> frontTexts,
  required List<TextItem> backTexts,
  required List<QrItem> frontQrs,
  required List<QrItem> backQrs,
  required List<GraphicItem> frontGraphics,
  required List<GraphicItem> backGraphics,
  required List<TableItem> frontTables,
  required List<TableItem> backTables,
  })? onApply;

  final VoidCallback? onHide;

  const TemplatePanelPage({super.key, this.onApply, this.onHide});

  @override
  State<TemplatePanelPage> createState() => _TemplatePanelPageState();
}

class _TemplatePanelPageState extends State<TemplatePanelPage> {
  int selectedTemplate = -1;
  final List<_TemplateData> firestoreTemplates = [];

  String searchQuery = "";
  final TextEditingController searchController = TextEditingController();

  bool showTemp = false; // false = Saved, true = Autosave

  @override
  void initState() {
    super.initState();
    _loadFirestoreTemplates();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  /// ================= LOAD TEMPLATES (TEMP + FINAL) =================
  Future<void> _loadFirestoreTemplates() async {
    // 1️⃣ Final templates
    final finalSnap = await FirebaseFirestore.instance
        .collection("canvas_templates")
        .orderBy("createdAt", descending: true)
        .get();
    final Map<String, QueryDocumentSnapshot> latestTemplates = {};

    for (var doc in finalSnap.docs) {
      final data = doc.data();
      final name = data['templateName'] ?? "Template";

      if (!latestTemplates.containsKey(name)) {
        latestTemplates[name] = doc;
      } else {
        final old = latestTemplates[name]!;
        final oldTime = (old.data() as Map)['createdAt'];
        final newTime = data['createdAt'];

        if (newTime != null && oldTime != null) {
          if ((newTime as Timestamp).toDate().isAfter((oldTime as Timestamp).toDate())) {
            latestTemplates[name] = doc;
          }
        }
      }
    }

    final finalTemplates = latestTemplates.values.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return _parseTemplateData(doc.id, data, isTemp: false);
    }).toList();

    final tempSnap = await FirebaseFirestore.instance
        .collection("canvas_temp")
        .orderBy("lastUpdated", descending: true)
        .limit(1)
        .get();




    final tempTemplates = tempSnap.docs.map((doc) {
      final data = doc.data();
      return _parseTemplateData(doc.id, data, isTemp: true);
    }).toList();

    setState(() {
      firestoreTemplates
        ..clear()
        ..addAll(finalTemplates)
        ..addAll(tempTemplates);
    });
  }

  _TemplateData _parseTemplateData(String id, Map<String, dynamic> data, {bool isTemp = false}) {

    // 🔍 DEBUG START
    debugPrint("📄 Template ID: $id");

    debugPrint("📊 Excel Name: ${data['excelName']}");
    // 🔍 DEBUG END


    final front = data["front"] ?? {};
    final back = data["back"] ?? {};

    Offset parsePosition(Map? pos) => Offset(
      (pos?["dx"] ?? 0).toDouble(),
      (pos?["dy"] ?? 0).toDouble(),
    );

    final frontTables = (front["tables"] as List? ?? []).map((e) => TableItem.fromMap(e)).toList();
    final backTables = (back["tables"] as List? ?? []).map((e) => TableItem.fromMap(e)).toList();

    return _TemplateData(
      id: id,
      title: data['templateName'] ?? (isTemp ? "Autosave" : "Template"),
      excelName: data["excelName"], // 🔥 ADD THIS

      icon: isTemp ? Icons.timer : Icons.layers,
      widthCm: (data["widthCm"] ?? 10).toDouble(),
      heightCm: (data["heightCm"] ?? 10).toDouble(),
      showGrid: data["showGrid"] ?? false,
      frontBg: Color(front["bg"] ?? 0xFFFFFFFF),
      backBg: Color(back["bg"] ?? 0xFFFFFFFF),
      frontImage: front["image"],
      backImage: back["image"],
      frontImageScale: (front["imageScale"] ?? 1.0).toDouble(),
      backImageScale: (back["imageScale"] ?? 1.0).toDouble(),
      frontImagePosition: parsePosition(front["imagePosition"]),
      backImagePosition: parsePosition(back["imagePosition"]),
      frontTexts: (front["texts"] as List? ?? []).map((e) => TextItem.fromJson(e)).toList(),
      backTexts: (back["texts"] as List? ?? []).map((e) => TextItem.fromJson(e)).toList(),
      frontQrs: (front["qrs"] as List? ?? []).map((e) => QrItem.fromJson(e)).toList(),
      backQrs: (back["qrs"] as List? ?? []).map((e) => QrItem.fromJson(e)).toList(),
      frontGraphics: (front["graphics"] as List? ?? []).map((e) => GraphicItem.fromJson(e)).toList(),
      backGraphics: (back["graphics"] as List? ?? []).map((e) => GraphicItem.fromJson(e)).toList(),
      frontTables: frontTables,
      backTables: backTables,
    );
  }

  /// ================= DELETE FIRESTORE TEMPLATE =================
  Future<void> _deleteTemplate(String id) async {
    await FirebaseFirestore.instance.collection("canvas_templates").doc(id).delete();
    setState(() => firestoreTemplates.removeWhere((t) => t.id == id));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Template deleted successfully")));
  }

  /// ================= FILTERED TEMPLATES =================
  List<_TemplateData> get filteredTemplates {
    List<_TemplateData> templates = [];

    if (showTemp) {
      // Only show latest temp template
      final tempTemplates = firestoreTemplates.where((t) => t.icon == Icons.timer).toList();
      if (tempTemplates.isNotEmpty) templates.add(tempTemplates.first); // latest one
    } else {
      // Show saved templates
      templates = firestoreTemplates.where((t) => t.icon != Icons.timer).toList();
    }

    if (searchQuery.isNotEmpty) {
      final lowerQuery = searchQuery.toLowerCase();
      templates = templates.where((t) => t.title.toLowerCase().contains(lowerQuery)).toList();
    }

    return templates;
  }

  @override
  Widget build(BuildContext context) {
    final allTemplates = filteredTemplates;

    return Container(
      width: MediaQuery.of(context).size.width * 0.45,
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ================= HEADER (TextPanel style) =================
          Row(
            children: [
              const Text(
                "Templates",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),

            ],
          ),

          const SizedBox(height: 12),

          // ================= TOGGLE BUTTONS =================
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () => setState(() => showTemp = false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      showTemp ? Colors.grey[300] : Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                    ),
                    child: const Text("Saved Templates"),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () => setState(() => showTemp = true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      showTemp ? Colors.blue : Colors.grey[300],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                    ),
                    child: const Text("Autosave"),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ================= HELP TEXT =================
          const Text(
            "Tap a template to apply & edit",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),

          const SizedBox(height: 12),

          // ================= SEARCH BAR =================
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: "Search templates...",
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onChanged: (val) {
              setState(() => searchQuery = val);
            },
          ),

          const SizedBox(height: 16),

          // ================= GRID VIEW =================
          Expanded(
            child: allTemplates.isEmpty
                ? Center(
              child: Text(
                searchQuery.isEmpty
                    ? "No templates available"
                    : "No templates found",
                style:
                const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            )
                : GridView.builder(
              itemCount: allTemplates.length,
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.1,
              ),
              itemBuilder: (_, i) =>
                  _templateCard(allTemplates, i),
            ),
          ),
        ],
      ),
    );
  }

  /// ================= EDIT TEMPLATE NAME =================
  Future<void> _editTemplateName(_TemplateData template) async {
    final controller = TextEditingController(text: template.title);

    final updated = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Template Name"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "Template Name"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text("Save")),
        ],
      ),
    );

    if (updated != null && updated.trim().isNotEmpty) {
      await FirebaseFirestore.instance
          .collection("canvas_templates")
          .doc(template.id)
          .update({"templateName": updated.trim()});

      setState(() {
        final idx = firestoreTemplates.indexWhere((t) => t.id == template.id);
        if (idx != -1) {
          firestoreTemplates[idx] = template.copyWith(title: updated.trim());
        }
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Template name updated")));
    }
  }

  /// ================= TEMPLATE CARD =================
  Widget _templateCard(List<_TemplateData> list, int index) {
    final t = list[index];
    final isActive = selectedTemplate == index;

    return GestureDetector(
      onTap: () => _applyTemplate(index, t),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: t.previewColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive ? Colors.blueAccent : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: isActive ? 14 : 8,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: 8,
              right: 8,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(t.icon, size: 28, color: Colors.white70),
                  if (t.icon != Icons.timer)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () => _editTemplateName(t),
                          child: const Icon(Icons.edit, color: Colors.yellowAccent, size: 20),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text("Delete Template?"),
                                content: const Text("Are you sure you want to delete this template?"),
                                actions: [
                                  TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text("Cancel")),
                                  ElevatedButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      child: const Text("Delete")),
                                ],
                              ),
                            );
                            if (confirm == true) _deleteTemplate(t.id);
                          },
                          child: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  if (t.excelName != null)
                    Text(
                      t.excelName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),

          ],
        ),
      ),
    );
  }

  /// ================= APPLY TEMPLATE =================
  void _applyTemplate(int index, _TemplateData t) {
    setState(() => selectedTemplate = index);
    // 🔥 DEBUG PRINT
    debugPrint("✅ Template Applied:");
    debugPrint("Template ID: ${t.id}");
    debugPrint("Template Name: ${t.title}");
    debugPrint("Excel Name: ${t.excelName}");


    widget.onHide?.call();

    widget.onApply?.call(
      templateId: t.id,
      widthCm: t.widthCm,
      templateName: t.title, // 🔥 ADD

      heightCm: t.heightCm,
      showGrid: t.showGrid,
      frontBg: t.frontBg,
      backBg: t.backBg,
      frontImage: t.frontImage,
      frontImagePosition: t.frontImagePosition,
      frontImageScale: t.frontImageScale,
      backImage: t.backImage,
      backImagePosition: t.backImagePosition,
      backImageScale: t.backImageScale,
      frontTexts: t.frontTexts.map((e) => e.copyWith()).toList(),
      backTexts: t.backTexts.map((e) => e.copyWith()).toList(),
      frontQrs: t.frontQrs.map((e) => e.copyWith()).toList(),
      backQrs: t.backQrs.map((e) => e.copyWith()).toList(),
      frontGraphics: t.frontGraphics.map((e) => e.copyWith()).toList(),
      backGraphics: t.backGraphics.map((e) => e.copyWith()).toList(),
      frontTables: t.frontTables.map((e) => e.copyWith()).toList(),
      backTables: t.backTables.map((e) => e.copyWith()).toList(),
    );
  }
}

extension on _TemplateData {
  _TemplateData copyWith({
    String? title,
    String? excelName,

  }) {
    return _TemplateData(
      id: id,
      title: title ?? this.title,
      excelName: excelName ?? this.excelName,

      icon: icon,
      widthCm: widthCm,
      heightCm: heightCm,
      showGrid: showGrid,
      frontBg: frontBg,
      backBg: backBg,
      frontImage: frontImage,
      frontImagePosition: frontImagePosition,
      frontImageScale: frontImageScale,
      backImage: backImage,
      backImagePosition: backImagePosition,
      backImageScale: backImageScale,
      frontTexts: frontTexts,
      backTexts: backTexts,
      frontQrs: frontQrs,
      backQrs: backQrs,
      frontGraphics: frontGraphics,
      backGraphics: backGraphics,
      frontTables: frontTables,
      backTables: backTables,
    );
  }
}

/// ================= TEMPLATE MODEL =================
class _TemplateData {
  final String id;
  final String title;
  final String? excelName;
  final IconData icon;

  final double widthCm;
  final double heightCm;
  final bool showGrid;

  final Color frontBg;
  final Color backBg;

  final String? frontImage;
  final Offset frontImagePosition;
  final double frontImageScale;

  final String? backImage;
  final Offset backImagePosition;
  final double backImageScale;

  final List<TextItem> frontTexts;
  final List<TextItem> backTexts;

  final List<QrItem> frontQrs;
  final List<QrItem> backQrs;

  final List<GraphicItem> frontGraphics;
  final List<GraphicItem> backGraphics;

  final List<TableItem> frontTables;
  final List<TableItem> backTables;

  Color get previewColor => frontBg;

  _TemplateData({
    required this.id,
    required this.title,
    required this.icon,
    this.excelName,

    required this.widthCm,
    required this.heightCm,
    required this.showGrid,
    required this.frontBg,
    required this.backBg,
    this.frontImage,
    this.frontImagePosition = Offset.zero,
    this.frontImageScale = 1.0,
    this.backImage,
    this.backImagePosition = Offset.zero,
    this.backImageScale = 1.0,
    required this.frontTexts,
    required this.backTexts,
    required this.frontQrs,
    required this.backQrs,
    required this.frontGraphics,
    required this.backGraphics,
    required this.frontTables,
    required this.backTables,
  });
}
