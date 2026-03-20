

import 'dart:typed_data';
import 'dart:html' as html;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../common/canvas_side.dart';
import '../models/excel_cell_selection.dart';
import '../models/text_item.dart';
import '../services/popup_page_preview.dart';

class MultiTemplatePanel extends StatefulWidget {
  final GlobalKey canvasKey;
  final ValueNotifier<List<List<String>>> excelDataNotifier;
  final ValueNotifier<ExcelCellSelection?> selectedExcelCell;
  final ValueNotifier<List<TextItem>> frontText;
  final ValueNotifier<List<TextItem>> backText;
  final ValueNotifier<CanvasSide> canvasSide;
  final ValueNotifier<List<int>> selectedExcelRows;

  final double widthCm;
  final double heightCm;

  final VoidCallback onStartExport;
  final Function(double) onProgress;
  final VoidCallback onEndExport;

  const MultiTemplatePanel({
    super.key,
    required this.canvasKey,
    required this.excelDataNotifier,
    required this.selectedExcelCell,
    required this.frontText,
    required this.backText,
    required this.canvasSide,
    required this.selectedExcelRows,
    required this.widthCm,
    required this.heightCm,
    required this.onStartExport,
    required this.onProgress,
    required this.onEndExport,
  });

  @override
  State<MultiTemplatePanel> createState() => _MultiTemplatePanelState();
}

class _MultiTemplatePanelState extends State<MultiTemplatePanel> {
  String _pageSize = 'A4';

  final Map<String, PdfPageFormat> _pageSizes = {
    'A4': PdfPageFormat.a4,
    'A3': PdfPageFormat.a3,
    'Letter': PdfPageFormat.letter,
  };

  List<Uint8List> _capturedImages = [];
  int _currentRow = -1;

  /// ✅ Editable margins
  final ValueNotifier<EdgeInsets> _margins =
  ValueNotifier(const EdgeInsets.all(1));

  final ValueNotifier<double> _horizontalGap =
  ValueNotifier(0.2);
  final ValueNotifier<double> _verticalGap =
  ValueNotifier(0.2);

  ValueNotifier<List<TextItem>> get _currentText =>
      widget.canvasSide.value == CanvasSide.front
          ? widget.frontText
          : widget.backText;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      margin: const EdgeInsets.all(12),
      decoration: _panelDecoration(),
      child: Column(
        children: [
          _header(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  _controlsSection(),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Text(
        "Multi Template PDF",
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _controlsSection() {
    return _card(
      child: Column(
        children: [
          _blueButton("Download PDF", Icons.download, _generatePdf),
          const SizedBox(height: 8),
          _blueButton("Preview Pages", Icons.preview, _showPagePreview),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text("Page Size: "),
              DropdownButton<String>(
                value: _pageSize,
                items: _pageSizes.keys
                    .map((e) => DropdownMenuItem(
                    value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _pageSize = v!),
              ),
            ],
          ),
        ],
      ),
    );
  }


  void _selectRow(int row) {
    _currentRow = row;
    widget.selectedExcelCell.value =
        ExcelCellSelection(
            row: row, col: 0, value: '', address: '');
    setState(() {});
  }

  double cmToPt(double cm) => cm * 28.3464567;

  Future<void> _generatePdf() async {
    final selectedRows =
        widget.selectedExcelRows.value;
    if (selectedRows.isEmpty) return;

    widget.onStartExport();
    widget.onProgress(0);
    _capturedImages.clear();

    final pdf = pw.Document();
    final pageFormat = _pageSizes[_pageSize]!;

    final margin = _margins.value;

    final marginLeftPt = cmToPt(margin.left);
    final marginTopPt = cmToPt(margin.top);
    final marginRightPt = cmToPt(margin.right);
    final marginBottomPt = cmToPt(margin.bottom);

    final horizontalGapPt =
    cmToPt(_horizontalGap.value);
    final verticalGapPt =
    cmToPt(_verticalGap.value);

    for (int i = 0; i < selectedRows.length; i++) {
      _selectRow(selectedRows[i]);
      await Future.delayed(
          const Duration(milliseconds: 80));

      final img = await _captureCanvas();
      _capturedImages.add(img);

      widget.onProgress(
          (i + 1) / selectedRows.length);
    }

    final imgWidthPt =
    cmToPt(widget.widthCm);
    final imgHeightPt =
    cmToPt(widget.heightCm);

    final usableWidth =
        pageFormat.width -
            (marginLeftPt + marginRightPt);

    final usableHeight =
        pageFormat.height -
            (marginTopPt + marginBottomPt);

    int colsFit =
    ((usableWidth + horizontalGapPt) /
        (imgWidthPt + horizontalGapPt))
        .floor();

    int rowsFit =
    ((usableHeight + verticalGapPt) /
        (imgHeightPt + verticalGapPt))
        .floor();

    if (colsFit < 1) colsFit = 1;
    if (rowsFit < 1) rowsFit = 1;

    final perPage = colsFit * rowsFit;

    for (int i = 0;
    i < _capturedImages.length;
    i += perPage) {
      final pageImages =
      _capturedImages.sublist(
          i,
          i + perPage >
              _capturedImages.length
              ? _capturedImages.length
              : i + perPage);

      pdf.addPage(
        pw.Page(
          pageFormat: pageFormat,
          margin: pw.EdgeInsets.only(
            left: marginLeftPt,
            top: marginTopPt,
            right: marginRightPt,
            bottom: marginBottomPt,
          ),
          build: (_) {
            return pw.Wrap(
              spacing: horizontalGapPt,
              runSpacing: verticalGapPt,
              children: pageImages.map((img) {
                return pw.Container(
                  width: imgWidthPt,
                  height: imgHeightPt,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(
                        color: PdfColors.grey300),
                  ),
                  child: pw.Image(
                    pw.MemoryImage(img),
                    fit: pw.BoxFit.contain,
                  ),
                );
              }).toList(),
            );
          },
        ),
      );
    }

    final bytes = await pdf.save();
    final blob =
    html.Blob([bytes], 'application/pdf');
    final url =
    html.Url.createObjectUrlFromBlob(blob);

    html.AnchorElement(href: url)
      ..setAttribute(
          'download', 'multi_template.pdf')
      ..click();

    html.Url.revokeObjectUrl(url);

    widget.onEndExport();
  }

  Future<Uint8List> _captureCanvas() async {
    final boundary = widget.canvasKey
        .currentContext!
        .findRenderObject() as RenderRepaintBoundary;

    final image =
    await boundary.toImage(pixelRatio: 3);
    final data = await image.toByteData(
        format: ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  Future<void> _showPagePreview() async {
    final selectedRows = widget.selectedExcelRows.value;
    if (selectedRows.isEmpty) return;

    widget.onStartExport();
    _capturedImages.clear();

    for (int i = 0; i < selectedRows.length; i++) {
      _selectRow(selectedRows[i]);
      await Future.delayed(const Duration(milliseconds: 80));

      final img = await _captureCanvas();
      _capturedImages.add(img);

      widget.onProgress((i + 1) / selectedRows.length);
    }

    widget.onEndExport();

    showDialog(
      context: context,
      builder: (_) => PagePreview(
        canvasWidthCm: widget.widthCm,
        canvasHeightCm: widget.heightCm,
        pageSize: _pageSize,
        pageFormats: _pageSizes,
        margins: _margins,
        horizontalGap: _horizontalGap,
        verticalGap: _verticalGap,
        capturedImages: _capturedImages,   // ✅ REAL IMAGES
        onDownload: _generatePdf,          // ✅ Download callback
      ),
    );
  }


  Widget _blueButton(
      String text,
      IconData icon,
      VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton.icon(
        icon: Icon(icon, color: Colors.white),
        label: Text(text,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          shape: RoundedRectangleBorder(
              borderRadius:
              BorderRadius.circular(12)),
        ),
        onPressed: onTap,
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius:
        BorderRadius.circular(12),
        border: Border.all(
            color: Colors.grey.shade300),
      ),
      child: child,
    );
  }

  BoxDecoration _panelDecoration() =>
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12,
              blurRadius: 10)
        ],
      );
}