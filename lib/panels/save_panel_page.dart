import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../common/canvas_side.dart';

enum PdfLayoutType {
  vertical,   // 1 × 2 (Top - Bottom)
  horizontal, // 2 × 1 (Left - Right)
}

class SavePanelPage extends StatefulWidget {
  final GlobalKey canvasKey;
  final ValueNotifier<CanvasSide> canvasSide;
  final ValueNotifier<double> widthCm;
  final ValueNotifier<double> heightCm;
  final Function() onStartExport;
  final Function(double) onProgress;
  final Function() onEndExport;


  const SavePanelPage({
    super.key,
    required this.canvasKey,
    required this.canvasSide,
    required this.widthCm,
    required this.heightCm,
    required this.onStartExport,
    required this.onProgress,
    required this.onEndExport,

  });

  @override
  State<SavePanelPage> createState() => _SavePanelPageState();
}

class _SavePanelPageState extends State<SavePanelPage> {
  bool _downloading = false;
  double _progress = 0;

  PdfLayoutType _selectedLayout = PdfLayoutType.vertical;

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 320,
          margin: const EdgeInsets.all(12),
          decoration: _cardDecoration(),
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  "Save Panel",
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [

                      _button(
                        Icons.image,
                        "Download Front (PNG)",
                            () => _downloadImage(CanvasSide.front),
                      ),
                      _button(
                        Icons.image_outlined,
                        "Download Back (PNG)",
                            () => _downloadImage(CanvasSide.back),
                      ),

                      const Divider(height: 24),

                      DropdownButtonFormField<PdfLayoutType>(
                        value: _selectedLayout,
                        decoration: const InputDecoration(
                          labelText: "PDF Layout",
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: PdfLayoutType.vertical,
                            child: Text("1 × 2 (Top - Bottom)"),
                          ),
                          DropdownMenuItem(
                            value: PdfLayoutType.horizontal,
                            child: Text("2 × 1 (Left - Right)"),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedLayout = value!;
                          });
                        },
                      ),

                      const SizedBox(height: 12),

                      Container(
                        height: 120,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _buildLayoutPreview(),
                      ),

                      const SizedBox(height: 16),

                      _button(
                        Icons.picture_as_pdf,
                        "Download A4 PDF",
                        _downloadPdf,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ================= PREVIEW =================

  Widget _buildLayoutPreview() {
    if (_selectedLayout == PdfLayoutType.vertical) {
      return Column(
        children: [
          Expanded(child: _previewBox("Front")),
          const Divider(height: 1),
          Expanded(child: _previewBox("Back")),
        ],
      );
    } else {
      return Row(
        children: [
          Expanded(child: _previewBox("Front")),
          const VerticalDivider(width: 1),
          Expanded(child: _previewBox("Back")),
        ],
      );
    }
  }

  Widget _previewBox(String text) {
    return Container(
      alignment: Alignment.center,
      color: Colors.grey.shade100,
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  // ================= BUTTON =================

  Widget _button(
      IconData icon, String text, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: SizedBox(
        width: double.infinity,
        height: 46,
        child: ElevatedButton.icon(
          icon: Icon(icon, color: Colors.white),
          label: Text(text,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _downloading ? null : onTap,
        ),
      ),
    );
  }



  // ================= PDF LABEL WIDGET =================

  pw.Widget _pdfItem(Uint8List bytes, String label) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Expanded(
          child: pw.Image(
            pw.MemoryImage(bytes),
            fit: pw.BoxFit.contain,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ================= CONVERSION =================

  int _cmToPx(double cm) {
    const dpi = 150; // 300 se 150 (faster + still good quality)
    return ((cm / 2.54) * dpi).round();
  }


  // ================= PNG DOWNLOAD =================

  Future<void> _downloadImage(CanvasSide side) async {
    widget.onStartExport();   // 🔥 ADD THIS

    double progress = 0.0;
    widget.onProgress(progress);

    final bytes = await _captureSide(side);
    progress = 0.8;
    widget.onProgress(progress);

    _download(
      bytes,
      side == CanvasSide.front ? "front.png" : "back.png",
    );

    widget.onProgress(1.0);
    await Future.delayed(const Duration(milliseconds: 200));

    widget.onEndExport();     // 🔥 ADD THIS
  }


  // ================= PDF DOWNLOAD =================

  Future<void> _downloadPdf() async {
    widget.onStartExport();

    await _animateGlobalProgress(0.0, 0.15);

    final frontBytes = await _captureSide(CanvasSide.front);

    await _animateGlobalProgress(0.15, 0.45);

    final backBytes = await _captureSide(CanvasSide.back);

    await _animateGlobalProgress(0.45, 0.75);

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (context) {
          if (_selectedLayout == PdfLayoutType.vertical) {
            return pw.Column(
              children: [
                pw.Expanded(child: _pdfItem(frontBytes, "Front")),
                pw.SizedBox(height: 20),
                pw.Expanded(child: _pdfItem(backBytes, "Back")),
              ],
            );
          } else {
            return pw.Row(
              children: [
                pw.Expanded(child: _pdfItem(frontBytes, "Front")),
                pw.SizedBox(width: 20),
                pw.Expanded(child: _pdfItem(backBytes, "Back")),
              ],
            );
          }
        },
      ),
    );

    final pdfBytes = await pdf.save();

    await _animateGlobalProgress(0.75, 0.95);

    _download(pdfBytes, "design_A4_layout.pdf");

    await _animateGlobalProgress(0.95, 1.0);

    await Future.delayed(const Duration(milliseconds: 200));
    widget.onEndExport();
  }


  Future<void> _animateGlobalProgress(
      double from,
      double to,
      ) async {
    double value = from;

    while (value < to) {
      await Future.delayed(const Duration(milliseconds: 15));
      value += 0.01;
      if (value > to) value = to;
      widget.onProgress(value);
    }
  }





  // ================= CAPTURE =================
  Future<Uint8List> _captureSide(CanvasSide side) async {
    widget.canvasSide.value = side;
    widget.canvasSide.notifyListeners();

    await Future.delayed(const Duration(milliseconds: 50));
    await WidgetsBinding.instance.endOfFrame;

    final boundary =
    widget.canvasKey.currentContext!.findRenderObject()
    as RenderRepaintBoundary;

    final image = await boundary.toImage(
      pixelRatio: 2, // fixed for speed
    );

    final byteData =
    await image.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }

  Future<void> _animateProgress(double target) async {
    while (_progress < target) {
      await Future.delayed(const Duration(milliseconds: 20));
      setState(() {
        _progress += 0.01;
        if (_progress > target) _progress = target;
      });
    }
  }



  // ================= HELPERS =================

  void _download(Uint8List bytes, String name) {
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', name)
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: const [
      BoxShadow(color: Colors.black12, blurRadius: 10),
    ],
  );
}
