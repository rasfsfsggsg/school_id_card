import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';

class PagePreview extends StatefulWidget {
  final double canvasWidthCm;
  final double canvasHeightCm;
  final String pageSize;
  final Map<String, PdfPageFormat> pageFormats;

  final ValueNotifier<EdgeInsets> margins;
  final ValueNotifier<double> horizontalGap;
  final ValueNotifier<double> verticalGap;

  final List<Uint8List> capturedImages;
  final VoidCallback onDownload;

  const PagePreview({
    super.key,
    required this.canvasWidthCm,
    required this.canvasHeightCm,
    required this.pageSize,
    required this.pageFormats,
    required this.margins,
    required this.horizontalGap,
    required this.verticalGap,
    required this.capturedImages,
    required this.onDownload,
  });

  @override
  State<PagePreview> createState() => _PagePreviewState();
}

class _PagePreviewState extends State<PagePreview> {
  final List<double> spacingOptions = List.generate(51, (index) => index * 0.1);

  // ✅ Current page tracker for multi-page preview
  final ValueNotifier<int> _currentPage = ValueNotifier(0);

  double cmToPt(double cm) => cm * 28.3464567;

  @override
  Widget build(BuildContext context) {
    final pageFormat =
        widget.pageFormats[widget.pageSize] ?? widget.pageFormats.values.first;

    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final leftPanelWidth = 300.0;

          final previewAreaWidth = constraints.maxWidth - leftPanelWidth - 40;
          final previewAreaHeight = constraints.maxHeight - 80;

          final scaleHeight = previewAreaHeight / pageFormat.height;
          final scaleWidth = previewAreaWidth / pageFormat.width;
          final scale = scaleHeight < scaleWidth ? scaleHeight : scaleWidth;

          final previewWidth = pageFormat.width * scale;
          final previewHeight = pageFormat.height * scale;

          return Column(
            children: [
              /// ================= HEADER =================
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "Page Preview",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                ),
              ),

              /// ================= BODY =================
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      /// ===== LEFT SETTINGS =====
                      _buildLeftPanel(),

                      const SizedBox(width: 20),

                      /// ===== PREVIEW =====
                      Expanded(
                        child: _buildPreview(pageFormat, previewWidth, previewHeight, scale),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLeftPanel() {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Page Settings",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          const Text(
            "Page Margin (cm)",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          ValueListenableBuilder<EdgeInsets>(
            valueListenable: widget.margins,
            builder: (context, margin, _) {
              return Column(
                children: [
                  _marginSlider("Top", margin.top, (v) => widget.margins.value = margin.copyWith(top: v)),
                  _marginSlider("Bottom", margin.bottom, (v) => widget.margins.value = margin.copyWith(bottom: v)),
                  _marginSlider("Left", margin.left, (v) => widget.margins.value = margin.copyWith(left: v)),
                  _marginSlider("Right", margin.right, (v) => widget.margins.value = margin.copyWith(right: v)),
                ],
              );
            },
          ),

          const SizedBox(height: 20),
          const Text(
            "Card Spacing (cm)",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          ValueListenableBuilder2<double, double>(
            first: widget.horizontalGap,
            second: widget.verticalGap,
            builder: (context, hGap, vGap, _) {
              return Column(
                children: [
                  _gapSlider(
                    "Horizontal"
                        " Gap",
                    hGap,
                        (v) => widget.horizontalGap.value = v,
                  ),
                  _gapSlider(
                    "Vertical"
                        " Gap",
                    vGap,
                        (v) => widget.verticalGap.value = v,
                  ),
                ],
              );
            },
          ),

          const Spacer(),
          Text("Canvas: ${widget.canvasWidthCm} × ${widget.canvasHeightCm} cm"),
        ],
      ),
    );
  }
  Widget _gapSlider(String label, double value, Function(double) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 6,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
              ),
              child: Slider(
                value: value,
                min: 0,
                max: 5,
                divisions: 50,
                label: value.toStringAsFixed(1),
                onChanged: onChanged,
              ),
            ),
          ),
          SizedBox(
            width: 50,
            child: Text(
              value.toStringAsFixed(1),
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildPreview(PdfPageFormat pageFormat, double previewWidth, double previewHeight, double scale) {
    return ValueListenableBuilder3<EdgeInsets, double, double>(
      first: widget.margins,
      second: widget.horizontalGap,
      third: widget.verticalGap,
      builder: (context, margin, hGap, vGap, _) {
        final pageWidthPt = pageFormat.width;
        final pageHeightPt = pageFormat.height;

        final canvasWidthPt = cmToPt(widget.canvasWidthCm);
        final canvasHeightPt = cmToPt(widget.canvasHeightCm);

        final marginLeftPt = cmToPt(margin.left);
        final marginRightPt = cmToPt(margin.right);
        final marginTopPt = cmToPt(margin.top);
        final marginBottomPt = cmToPt(margin.bottom);

        final usableWidth = pageWidthPt - (marginLeftPt + marginRightPt);
        final usableHeight = pageHeightPt - (marginTopPt + marginBottomPt);

        final horizontalGapPt = cmToPt(hGap);
        final verticalGapPt = cmToPt(vGap);

        int cols = ((usableWidth + horizontalGapPt) / (canvasWidthPt + horizontalGapPt)).floor();
        int rows = ((usableHeight + verticalGapPt) / (canvasHeightPt + verticalGapPt)).floor();

        if (cols <= 0) cols = 1;
        if (rows <= 0) rows = 1;

        // ✅ Split images into pages
        final pageImages = <List<Uint8List>>[];
        int imagesPerPage = cols * rows;
        for (int i = 0; i < widget.capturedImages.length; i += imagesPerPage) {
          pageImages.add(widget.capturedImages.sublist(
            i,
            i + imagesPerPage > widget.capturedImages.length
                ? widget.capturedImages.length
                : i + imagesPerPage,
          ));
        }

        return Column(
          children: [
            /// ===== PAGE NAVIGATION =====
            if (pageImages.length > 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      if (_currentPage.value > 0) _currentPage.value--;
                    },
                  ),
                  ValueListenableBuilder<int>(
                    valueListenable: _currentPage,
                    builder: (_, page, __) {
                      return Text("Page ${page + 1} / ${pageImages.length}");
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: () {
                      if (_currentPage.value < pageImages.length - 1) _currentPage.value++;
                    },
                  ),
                ],
              ),

            /// ===== PREVIEW AREA =====
            Expanded(
              child: Center(
                child: Container(
                  width: previewWidth,
                  height: previewHeight,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 15, offset: Offset(0, 6))
                    ],
                  ),
                  child: ValueListenableBuilder<int>(
                    valueListenable: _currentPage,
                    builder: (_, page, __) {
                      final images = pageImages[page];

                      return Stack(
                        children: [
                          for (int i = 0; i < images.length; i++)
                            Positioned(
                              left: (marginLeftPt + (i % cols) * (canvasWidthPt + horizontalGapPt)) * scale,
                              top: (marginTopPt + (i ~/ cols) * (canvasHeightPt + verticalGapPt)) * scale,
                              width: canvasWidthPt * scale,
                              height: canvasHeightPt * scale,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.memory(
                                  images[i],
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),
            Text("Columns: $cols  |  Rows: $rows  |  Total per page: ${cols * rows}"),
            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: widget.capturedImages.isEmpty
                  ? null
                  : () {
                Navigator.pop(context);
                widget.onDownload();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text("Download PDF", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _marginSlider(String label, double value, Function(double) onChanged) {
    return Row(
      children: [
        SizedBox(width: 60, child: Text(label)),
        Expanded(
          child: Slider(value: value, min: 0, max: 5, divisions: 50, label: value.toStringAsFixed(1), onChanged: onChanged),
        ),
        SizedBox(width: 40, child: Text(value.toStringAsFixed(1), textAlign: TextAlign.right)),
      ],
    );
  }

  Widget _dropdown(String label, double value, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 5),
        DropdownButton<double>(
          value: value,
          isExpanded: true,
          items: spacingOptions.map((e) => DropdownMenuItem(value: e, child: Text(e.toStringAsFixed(1)))).toList(),
          onChanged: (v) => onChanged(v!),
        ),
      ],
    );
  }
}

/// ================= MULTI LISTENABLE BUILDER =================
class ValueListenableBuilder2<A, B> extends StatelessWidget {
  final ValueNotifier<A> first;
  final ValueNotifier<B> second;
  final Widget Function(BuildContext, A, B, Widget?) builder;

  const ValueListenableBuilder2({super.key, required this.first, required this.second, required this.builder});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<A>(
      valueListenable: first,
      builder: (context, a, _) {
        return ValueListenableBuilder<B>(
          valueListenable: second,
          builder: (context, b, _) {
            return builder(context, a, b, null);
          },
        );
      },
    );
  }
}

class ValueListenableBuilder3<A, B, C> extends StatelessWidget {
  final ValueNotifier<A> first;
  final ValueNotifier<B> second;
  final ValueNotifier<C> third;
  final Widget Function(BuildContext, A, B, C, Widget?) builder;

  const ValueListenableBuilder3({super.key, required this.first, required this.second, required this.third, required this.builder});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<A>(
      valueListenable: first,
      builder: (context, a, _) {
        return ValueListenableBuilder<B>(
          valueListenable: second,
          builder: (context, b, _) {
            return ValueListenableBuilder<C>(
              valueListenable: third,
              builder: (context, c, _) {
                return builder(context, a, b, c, null);
              },
            );
          },
        );
      },
    );
  }
}