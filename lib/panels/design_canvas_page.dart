

import 'dart:async';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import '../common/canvas_orientation.dart';
import '../common/canvas_side.dart';
import '../models/text_item.dart';
import '../models/graphic_item.dart';
import '../models/qr_item.dart';
import '../models/table_item.dart';
import '../services/UnitToPixelDialog.dart';
import '../widgets/CanvasSizeEditor.dart';
import '../widgets/design_canvas_top_bar.dart';

import '../widgets/popup_diloage.dart';
import '../widgets/text_top_toolbar.dart';
import '../widgets/zoom_control_popup.dart';
import 'helpers/design_canvas_persistence_helper.dart';
import 'helpers/design_canvas_view_helper.dart';
import 'helpers/design_canvas_helpers.dart';

class DesignCanvasPage extends StatefulWidget {
  final ValueNotifier<List<TextItem>> frontText;
  final ValueNotifier<List<TextItem>> backText;
  final ValueNotifier<List<GraphicItem>> frontGraphics;
  final ValueNotifier<List<GraphicItem>> backGraphics;
  final ValueNotifier<List<QrItem>> frontQrs;


  final ValueNotifier<double> zoomNotifier;

  final ValueNotifier<List<QrItem>> backQrs;
  final ValueNotifier<List<TableItem>> frontTables;
  final ValueNotifier<List<TableItem>> backTables;
  final ValueNotifier<Color> frontBg;
  final ValueNotifier<Color> backBg;
  final ValueNotifier<String?> frontImage;
  final ValueNotifier<String?> backImage;
  final ValueNotifier<CanvasOrientation> orientation;
  final ValueNotifier<CanvasSide> canvasSide;
  final GlobalKey canvasKey;
  final ValueNotifier<double> widthCm;
  final ValueNotifier<double> heightCm;
  final ValueNotifier<bool> frontShowGrid;
  final ValueNotifier<bool> backShowGrid;
  final ValueNotifier<double> frontImageScale;
  final ValueNotifier<Offset> frontImagePosition;
  final ValueNotifier<double> backImageScale;
  final ValueNotifier<Offset> backImagePosition;
  final ValueNotifier<List<List<String>>> excelDataNotifier;
  final String? currentTemplateName;


  const DesignCanvasPage({
    super.key,
    required this.frontText,
    required this.backText,
    required this.frontGraphics,
    required this.backGraphics,
    required this.frontQrs,
    this.currentTemplateName, // ⭐ ADD

    required this.backQrs,
    required this.frontTables,
    required this.backTables,
    required this.frontBg,
    required this.backBg,
    required this.frontImage,
    required this.backImage,
    required this.orientation,
    required this.canvasSide,
    required this.canvasKey,
    required this.widthCm,
    required this.heightCm,
    required this.frontShowGrid,
    required this.backShowGrid,
    required this.frontImageScale,
    required this.frontImagePosition,
    required this.backImageScale,
    required this.backImagePosition, required this.excelDataNotifier, required this.zoomNotifier,
  });

  @override
  State<DesignCanvasPage> createState() => _DesignCanvasPageState();
}

class _DesignCanvasPageState extends State<DesignCanvasPage> {
  String? selectedFrontTextId;
  String? selectedBackTextId;
  String? _currentTemplateId;
  String? _currentTemplateName;


  late final ValueNotifier<bool> isCanvasSizeDialogOpen;
  late final canvasWidthPx = widget.widthCm.value * _pxPerCm;
  late final canvasHeightPx = widget.heightCm.value * _pxPerCm;
  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();
  late final ValueNotifier<double> _bgUploadProgress;
  late final ValueNotifier<bool> _isBgUploading;



  String? selectedGraphicId;
  late final ValueNotifier<bool> imageEditEnabled;
  late final ValueNotifier<bool> isUploading;
  late Timer? _autosaveTimer;
  String? _tempCanvasId;
  String? selectedQrId;
  String? selectedTableId;
  static const double _pxPerCm = 10;
  static const double _borderPadding = 10;
  ValueNotifier<List<TextItem>> get _currentText =>
      DesignCanvasHelper.currentText(
        canvasSide: widget.canvasSide,
        front: widget.frontText,
        back: widget.backText,
      );
  ValueNotifier<bool> get _currentShowGrid =>
      widget.canvasSide.value == CanvasSide.front
          ? widget.frontShowGrid
          : widget.backShowGrid;
  ValueNotifier<List<GraphicItem>> get _currentGraphics =>
      DesignCanvasHelper.currentGraphics(
        canvasSide: widget.canvasSide,
        front: widget.frontGraphics,
        back: widget.backGraphics,
      );

  ValueNotifier<List<QrItem>> get _currentQrs =>
      DesignCanvasHelper.currentQrs(
        canvasSide: widget.canvasSide,
        front: widget.frontQrs,
        back: widget.backQrs,
      );

  ValueNotifier<List<TableItem>> get _currentTables =>
      DesignCanvasHelper.currentTables(
        canvasSide: widget.canvasSide,
        front: widget.frontTables,
        back: widget.backTables,
      );

  ValueNotifier<Color> get _currentBg =>
      DesignCanvasHelper.currentBg(
        canvasSide: widget.canvasSide,
        front: widget.frontBg,
        back: widget.backBg,
      );

  /// ================= IMAGE & CROP INFO =================
  ValueNotifier<String?> get _currentImage =>
      DesignCanvasHelper.currentImage(
        canvasSide: widget.canvasSide,
        front: widget.frontImage,
        back: widget.backImage,
      ) ?? ValueNotifier<String?>(null);

  ValueNotifier<double> get _currentImageScale =>
      widget.canvasSide.value == CanvasSide.front
          ? widget.frontImageScale
          : widget.backImageScale;

  ValueNotifier<Offset> get _currentImagePosition =>
      widget.canvasSide.value == CanvasSide.front
          ? widget.frontImagePosition
          : widget.backImagePosition;

  String? get selectedTextId =>
      widget.canvasSide.value == CanvasSide.front
          ? selectedFrontTextId
          : selectedBackTextId;

  set selectedTextId(String? id) {
    if (widget.canvasSide.value == CanvasSide.front) {
      selectedFrontTextId = id;
    } else {
      selectedBackTextId = id;
    }
  }

  TextItem? get _selectedText {
    try {
      return _currentText.value.firstWhere((e) => e.id == selectedTextId);
    } catch (_) {
      return null;
    }
  }


  void _clearSelection() {
    FocusScope.of(context).unfocus();
    setState(() {
      selectedFrontTextId = null;
      selectedBackTextId = null;
      selectedGraphicId = null;
      selectedQrId = null;
      selectedTableId = null;
    });
  }



  @override
  void initState() {
    super.initState();
    isCanvasSizeDialogOpen = ValueNotifier(false);
    widget.zoomNotifier.value = 1.0; // ✅ Default 100%
    _bgUploadProgress = ValueNotifier(0.0);
    _isBgUploading = ValueNotifier(false);
    _currentTemplateName = widget.currentTemplateName;




    imageEditEnabled = ValueNotifier(false);
    isUploading = ValueNotifier(false);

    _tempCanvasId =
        DesignCanvasPersistenceHelper.getOrCreateTempCanvasId();

    DesignCanvasPersistenceHelper.loadTempCanvas(
      canvasId: _tempCanvasId!,
      widthCm: widget.widthCm,
      heightCm: widget.heightCm,
      orientation: ValueNotifier(widget.orientation.value.name),
      frontBg: widget.frontBg,
      backBg: widget.backBg,
      frontImage: widget.frontImage,
      backImage: widget.backImage,
      frontImageScale: widget.frontImageScale,
      frontImagePosition: widget.frontImagePosition,
      backImageScale: widget.backImageScale,
      backImagePosition: widget.backImagePosition,
      frontText: widget.frontText,
      backText: widget.backText,
      frontGraphics: widget.frontGraphics,
      backGraphics: widget.backGraphics,
      frontQrs: widget.frontQrs,
      backQrs: widget.backQrs,
      frontTables: widget.frontTables,
      backTables: widget.backTables,
    );
    Future.microtask(() async {
      final tempData =
      await DesignCanvasPersistenceHelper.getTempCanvas(_tempCanvasId!);



      if (tempData != null && tempData["templateId"] != null) {
        setState(() {
          _currentTemplateId = tempData["templateId"];
        });
      }
    });

    _autosaveTimer =
        Timer.periodic(const Duration(seconds: 15), (_) {
          DesignCanvasPersistenceHelper.autosave(
            canvasId: _tempCanvasId!,
            widthCm: widget.widthCm,
            templateId: _currentTemplateId, // 🔥 ADD THIS
            templateName: _currentTemplateName, // ⭐ ADD THIS

            heightCm: widget.heightCm,
            orientation: ValueNotifier(widget.orientation.value.name),
            showGrid: _currentShowGrid,
            frontBg: widget.frontBg,
            backBg: widget.backBg,
            frontImage: widget.frontImage,
            backImage: widget.backImage,
            frontImageScale: widget.frontImageScale,
            frontImagePosition: widget.frontImagePosition,
            backImageScale: widget.backImageScale,
            backImagePosition: widget.backImagePosition,
            frontText: widget.frontText,
            backText: widget.backText,
            frontGraphics: widget.frontGraphics,
            backGraphics: widget.backGraphics,
            frontQrs: widget.frontQrs,
            backQrs: widget.backQrs,
            frontTables: widget.frontTables,
            backTables: widget.backTables,
          );
        });
  }


  @override
  void dispose() {
    _autosaveTimer?.cancel();
    super.dispose();
  }

  void applyTemplate({
    required String templateId,
    required double widthCm,
    required double heightCm,
    required String templateName, // 🔥 ADD

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
  }) {
    setState(() {
      _currentTemplateId = templateId;
      _currentTemplateName = templateName;
    });

    widget.widthCm.value = widthCm;
    widget.heightCm.value = heightCm;

    widget.frontShowGrid.value = showGrid;
    widget.backShowGrid.value = showGrid;

    widget.frontBg.value = frontBg;
    widget.backBg.value = backBg;

    widget.frontImage.value = frontImage;
    widget.backImage.value = backImage;

    widget.frontImagePosition.value = frontImagePosition;
    widget.backImagePosition.value = backImagePosition;

    widget.frontImageScale.value = frontImageScale;
    widget.backImageScale.value = backImageScale;

    widget.frontText.value = frontTexts;
    widget.backText.value = backTexts;

    widget.frontQrs.value = frontQrs;
    widget.backQrs.value = backQrs;

    widget.frontGraphics.value = frontGraphics;
    widget.backGraphics.value = backGraphics;

    widget.frontTables.value = frontTables;
    widget.backTables.value = backTables;

    setState(() {});
  }
  void _confirmNewTemplate() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("New Template"),
        content: const Text(
          "This will clear the canvas and start a fresh template.\nContinue?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);

              _resetCanvas();

              Future.delayed(const Duration(milliseconds: 100), () {
                isCanvasSizeDialogOpen.value = true; // ✅ Mark dialog open
                CanvasSizeSelectionDialog.show(
                  context: context,
                  onStart: (width, height, orientation) {
                    widget.widthCm.value = width;
                    widget.heightCm.value = height;
                    widget.orientation.value = orientation;

                    isCanvasSizeDialogOpen.value = false; // ✅ Mark dialog closed
                  },
                ).then((_) {
                  // Ensure it resets even if dialog is dismissed without selection
                  isCanvasSizeDialogOpen.value = false;
                });
              });
            },
            child: const Text("Yes, New"),
          ),
        ],
      ),
    );
  }



  void _resetCanvas() {
    _currentTemplateId = null;
    _currentTemplateName = null;
    /// TEXT
    widget.frontText.value = [];
    widget.backText.value = [];

    /// GRAPHICS
    widget.frontGraphics.value = [];
    widget.backGraphics.value = [];

    /// QR
    widget.frontQrs.value = [];
    widget.backQrs.value = [];

    /// TABLE
    widget.frontTables.value = [];
    widget.backTables.value = [];

    /// BACKGROUND COLORS
    widget.frontBg.value = Colors.white;
    widget.backBg.value = Colors.white;

    /// BACKGROUND IMAGE
    widget.frontImage.value = null;
    widget.backImage.value = null;

    /// IMAGE TRANSFORM RESET
    widget.frontImageScale.value = 1.0;
    widget.backImageScale.value = 1.0;
    widget.frontImagePosition.value = Offset.zero;
    widget.backImagePosition.value = Offset.zero;

    /// GRID
    widget.frontShowGrid.value = false;
    widget.backShowGrid.value = false;

    /// SELECTION CLEAR
    _clearSelection();

    /// TEMP AUTOSAVE CLEAR (optional but recommended)
    if (_tempCanvasId != null) {
      DesignCanvasHelper.deleteTempCanvas(_tempCanvasId!);
      _tempCanvasId =
          DesignCanvasPersistenceHelper.getOrCreateTempCanvasId();
    }

    /// UI REFRESH
    setState(() {});
  }

  void _showEditSizeDialog() {
    showDialog(
      context: context,
      builder: (_) =>
          CanvasSizeEditor(
            initialWidth: widget.widthCm.value,
            initialHeight: widget.heightCm.value,
            onUpdate: (w, h) {
              widget.widthCm.value = w;
              widget.heightCm.value = h;
            }, initialUnit: null,
          ),
    );
  }


  Future<void> _saveTemplate() async {
    final result = await _showSaveTemplateDialog(
      context,
      currentTemplateName: _currentTemplateName,
    );

    if (result == null) return;

    final templateName = result["templateName"]!;
    final excelName = result["excelName"]!;

    final isUpdate = _currentTemplateId != null;

    await DesignCanvasHelper.saveTemplate(
      templateId: _currentTemplateId,
      templateName: templateName,
      excelName: excelName,
      excelData: widget.excelDataNotifier.value,
      isUpdate: isUpdate,

      widthCm: widget.widthCm,
      heightCm: widget.heightCm,
      orientation: ValueNotifier(widget.orientation.value.name),
      showGrid: _currentShowGrid.value,

      frontBg: widget.frontBg,
      backBg: widget.backBg,
      frontImage: widget.frontImage,
      backImage: widget.backImage,

      frontImageScale: widget.frontImageScale,
      frontImagePosition: widget.frontImagePosition,
      backImageScale: widget.backImageScale,
      backImagePosition: widget.backImagePosition,

      frontText: widget.frontText,
      backText: widget.backText,

      frontGraphics: widget.frontGraphics,
      backGraphics: widget.backGraphics,

      frontQrs: widget.frontQrs,
      backQrs: widget.backQrs,

      frontTables: widget.frontTables,
      backTables: widget.backTables,
    );

    /// SAVE CURRENT TEMPLATE INFO
    _currentTemplateName = templateName;

    if (!isUpdate) {
      final doc = await FirebaseFirestore.instance
          .collection("canvas_templates")
          .where("templateName", isEqualTo: templateName)
          .limit(1)
          .get();

      if (doc.docs.isNotEmpty) {
        _currentTemplateId = doc.docs.first.id;
      }
    }



  }


  Future<Map<String, String>?> _showSaveTemplateDialog(
      BuildContext context, {
        String? currentTemplateName,
      }) async {

    String templateName = currentTemplateName ?? "Template 1";
    String excelName = "data.xlsx";

    final templateController = TextEditingController(text: templateName);
    final excelController = TextEditingController(text: excelName);

    final templateEditable = ValueNotifier(false);
    final excelEditable = ValueNotifier(false);

    return showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),

          title: const Text(
            "Save Template",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),

          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              /// TEMPLATE NAME FIELD
              ValueListenableBuilder<bool>(
                valueListenable: templateEditable,
                builder: (context, editable, _) {
                  return TextField(
                    controller: templateController,
                    readOnly: !editable,
                    decoration: InputDecoration(
                      labelText: "Template Name",

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),

                      suffixIcon: IconButton(
                        icon: Icon(
                          editable ? Icons.lock_open : Icons.edit,
                          color: editable ? Colors.orange : Colors.grey,
                        ),
                        onPressed: () {
                          templateEditable.value = !editable;
                        },
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              /// EXCEL NAME FIELD
              ValueListenableBuilder<bool>(
                valueListenable: excelEditable,
                builder: (context, editable, _) {
                  return TextField(
                    controller: excelController,
                    readOnly: !editable,
                    decoration: InputDecoration(
                      labelText: "Excel Name",

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),

                      suffixIcon: IconButton(
                        icon: Icon(
                          editable ? Icons.lock_open : Icons.edit,
                          color: editable ? Colors.orange : Colors.grey,
                        ),
                        onPressed: () {
                          excelEditable.value = !editable;
                        },
                      ),
                    ),
                  );
                },
              ),
            ],
          ),

          actions: [

            TextButton(
              onPressed: () {
                Navigator.pop(context, null);
              },
              child: const Text("Cancel"),
            ),

            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text("Save"),
              onPressed: () {

                String template = templateController.text.trim();
                String excel = excelController.text.trim();

                if (template.isEmpty) template = "Template 1";
                if (excel.isEmpty) excel = "data.xlsx";

                Navigator.pop(context, {
                  "templateName": template,
                  "excelName": excel,
                });
              },
            )
          ],
        );
      },
    );
  }

  @override
  void didUpdateWidget(covariant DesignCanvasPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.currentTemplateName != oldWidget.currentTemplateName) {
      _currentTemplateName = widget.currentTemplateName;

      debugPrint("Canvas Template Updated: $_currentTemplateName");
    }
  }



  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [

        /// ================= BASE LAYOUT =================
        Column(
          children: [

            /// ================= TOP BAR =================
            DesignCanvasTopBar(
              orientation: widget.orientation,
              showGrid: _currentShowGrid.value,
              onToggleGrid: () {
                _currentShowGrid.value = !_currentShowGrid.value;
              },
              onEditSize: _showEditSizeDialog,
              backgroundImage: _currentImage,
              scaleNotifier: widget.canvasSide.value == CanvasSide.front
                  ? widget.frontImageScale
                  : widget.backImageScale,
              positionNotifier: widget.canvasSide.value == CanvasSide.front
                  ? widget.frontImagePosition
                  : widget.backImagePosition,
              extraActions: [
                ValueListenableBuilder<bool>(
                  valueListenable: isCanvasSizeDialogOpen,
                  builder: (context, isDialogOpen, _) {
                    if (isDialogOpen) return const SizedBox.shrink();

                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ➕ New Template (conditionally hidden)
                        ValueListenableBuilder<bool>(
                          valueListenable: isCanvasSizeDialogOpen,
                          builder: (context, isDialogOpen, _) {
                            return IconButton(
                              tooltip: "New Template",
                              icon: const Icon(Icons.add_box_outlined, color: Colors.redAccent),
                              onPressed: isDialogOpen ? null : _confirmNewTemplate,
                            );
                          },
                        ),

                        // Lock/Unlock Image (conditionally visible only if image exists)
                        ValueListenableBuilder<String?>(
                          valueListenable: _currentImage, // listen to background image
                          builder: (_, image, __) {
                            if (image == null || image.isEmpty) return const SizedBox.shrink();

                            return ValueListenableBuilder<bool>(
                              valueListenable: imageEditEnabled,
                              builder: (_, enabled, __) {
                                return IconButton(
                                  tooltip: enabled ? "Lock Editing" : "Unlock Editing",
                                  icon: Icon(
                                    enabled ? Icons.edit : Icons.edit_off, // 🔹 changed icons
                                    color: enabled ? Colors.orange : Colors.grey,
                                  ),
                                  onPressed: () {
                                    imageEditEnabled.value = !enabled;   // 👈 YEH LINE
                                  },
                                );
                              },
                            );
                          },
                        ),

                        IconButton(
                          tooltip: "Unit Converter",
                          icon: const Icon(Icons.autorenew, color: Colors.blueAccent),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => UnitConverterPopup(
                                pxPerCm: 10, // 🔹 adjust to match your canvas pixels per cm
                              ),
                            );
                          },
                        ),



                        // Save (always visible)
                        IconButton(
                          tooltip: "Save Template", // ✅ Tooltip added
                          icon: const Icon(Icons.save),
                          onPressed: _saveTemplate,
                        ),

                        ValueListenableBuilder<double>(
                          valueListenable: widget.zoomNotifier,
                          builder: (context, zoom, _) {
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [

                                /// ➖ Zoom Out
                                IconButton(
                                  tooltip: "Zoom Out",
                                  icon: const Icon(Icons.remove),
                                  onPressed: () {
                                    widget.zoomNotifier.value =
                                        (zoom - 0.05).clamp(0.1, 3.0);
                                  },
                                ),

                                /// 🔢 Percentage Text
                                Text(
                                  "${(zoom * 100).round()}%",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),

                                /// 🔄 Reset
                                IconButton(
                                  tooltip: "Reset Zoom",
                                  icon: const Icon(Icons.refresh),
                                  onPressed: () {
                                    widget.zoomNotifier.value = 1.0;
                                  },
                                ),

                                /// ➕ Zoom In
                                IconButton(
                                  tooltip: "Zoom In",
                                  icon: const Icon(Icons.add),
                                  onPressed: () {
                                    widget.zoomNotifier.value =
                                        (zoom + 0.05).clamp(0.1, 3.0);
                                  },
                                ),

                              ],
                            );
                          },
                        ),




                      ],
                    );

                  },
                ),
              ],



              onShowSavedTemplates: () {}, isUploading: isUploading,
            ),

            /// ================= FIXED ZOOM BAR (TOP BAR KE NEECH) =================


            /// ================= CANVAS AREA (FIXED 300x300 SCROLLABLE BOX) =================
            /// ================= CANVAS AREA (LARGE SCROLL BOX, SMALLER CANVAS) =================
            // Outer scrollable box stays fixed size
            /// ================= CANVAS AREA =================
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double availableHeight = constraints.maxHeight;
                  final double availableWidth = constraints.maxWidth;

                  const double pxPerCm = 80;
                  final double canvasW = widget.widthCm.value * pxPerCm;
                  final double canvasH = widget.heightCm.value * pxPerCm;

                  const double topOffset = 30.0;

                  return Container(
                    width: availableWidth,
                    height: availableHeight,
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: ValueListenableBuilder2<CanvasSide, double>(
                      first: widget.canvasSide,
                      second: widget.zoomNotifier,
                      builder: (context, side, zoom, _) {

                        final double zoomedW = canvasW * zoom;
                        final double zoomedH = canvasH * zoom;

                        return ScrollConfiguration(
                          behavior: const ScrollBehavior().copyWith(
                            scrollbars: false,
                            overscroll: false,
                          ),
                          child: ScrollbarTheme(
                            data: ScrollbarThemeData(
                              thumbColor:
                              MaterialStateProperty.all(Colors.grey.shade500),
                              trackColor:
                              MaterialStateProperty.all(Colors.grey.shade300),
                              thickness: MaterialStateProperty.all(8),
                              radius: const Radius.circular(8),
                            ),
                            child: Scrollbar(
                              controller: _verticalScrollController,
                              thumbVisibility: true,
                              child: SingleChildScrollView(
                                controller: _verticalScrollController,
                                scrollDirection: Axis.vertical,
                                child: Scrollbar(
                                  controller: _horizontalScrollController,
                                  thumbVisibility: true,
                                  child: SingleChildScrollView(
                                    controller: _horizontalScrollController,
                                    scrollDirection: Axis.horizontal,
                                    child: SizedBox(
                                      width: zoomedW + _borderPadding * 2,
                                      height: zoomedH + _borderPadding * 2 + topOffset,
                                      child: Padding(
                                        padding: EdgeInsets.only(
                                          left: _borderPadding + 30,
                                          right: _borderPadding,
                                          top: _borderPadding + topOffset,
                                          bottom: _borderPadding + 30,
                                        ),
                                        child: Align(
                                          alignment: Alignment.topLeft,
                                          child: SizedBox(
                                            width: zoomedW,
                                            height: zoomedH,
                                            child: FittedBox(
                                              alignment: Alignment.topLeft,
                                              fit: BoxFit.fill,
                                              child: SizedBox(
                                                width: canvasW,
                                                height: canvasH,
                                                child: DesignCanvasViewHelper.buildMainCanvas(
                                                  orientation: widget.orientation.value,
                                                  context: context,
                                                  qrs: _currentQrs,
                                                  tables: _currentTables,  // ✅ ADD THIS// ✅ FIXED
                                                  graphics: _currentGraphics,   // ✅ ADD THIS LINE


                                                  textItems: _currentText,
                                                  canvasKey: widget.canvasKey,
                                                  imageEditEnabled: imageEditEnabled,
                                                  isUploading: isUploading,
                                                  widthCm: widget.widthCm,
                                                  heightCm: widget.heightCm,
                                                  backgroundColor: side == CanvasSide.front
                                                      ? widget.frontBg
                                                      : widget.backBg,
                                                  backgroundImage: side == CanvasSide.front
                                                      ? widget.frontImage
                                                      : widget.backImage,
                                                  imageScale: side == CanvasSide.front
                                                      ? widget.frontImageScale
                                                      : widget.backImageScale,
                                                  imagePosition: side == CanvasSide.front
                                                      ? widget.frontImagePosition
                                                      : widget.backImagePosition,
                                                  zoom: 1.0,
                                                  onZoomChange: (s) {
                                                    widget.zoomNotifier.value =
                                                        (zoom * (1 + (s - 1) * 0.3))
                                                            .clamp(0.3, 3.0);
                                                  },
                                                  buildLayers: (w, h) {
                                                    return DesignCanvasViewHelper
                                                        .buildCanvasLayers(
                                                      canvasSide: side,
                                                      showGrid: side == CanvasSide.front
                                                          ? widget.frontShowGrid
                                                          : widget.backShowGrid,
                                                      excelDataNotifier:
                                                      widget.excelDataNotifier,
                                                      backgroundImage: side ==
                                                          CanvasSide.front
                                                          ? widget.frontImage
                                                          : widget.backImage,
                                                      imageScale: side ==
                                                          CanvasSide.front
                                                          ? widget.frontImageScale
                                                          : widget.backImageScale,
                                                      imagePosition: side ==
                                                          CanvasSide.front
                                                          ? widget.frontImagePosition
                                                          : widget.backImagePosition,
                                                      textItems: side ==
                                                          CanvasSide.front
                                                          ? widget.frontText
                                                          : widget.backText,
                                                      graphics: side ==
                                                          CanvasSide.front
                                                          ? widget.frontGraphics
                                                          : widget.backGraphics,
                                                      qrs: side == CanvasSide.front
                                                          ? widget.frontQrs
                                                          : widget.backQrs,
                                                      tables: side ==
                                                          CanvasSide.front
                                                          ? widget.frontTables
                                                          : widget.backTables,
                                                      selectedTextId: selectedTextId,
                                                      selectedGraphicId: selectedGraphicId,
                                                      selectedQrId: selectedQrId,
                                                      selectedTableId: selectedTableId,
                                                      onClearSelection: _clearSelection,
                                                      onSelectText: (id) =>
                                                          setState(() => selectedTextId = id),
                                                      onSelectGraphic: (id) =>
                                                          setState(() => selectedGraphicId = id),
                                                      onSelectQr: (id) =>
                                                          setState(() => selectedQrId = id),
                                                      onSelectTable: (id) =>
                                                          setState(() => selectedTableId = id),
                                                      imageEditEnabled: imageEditEnabled,
                                                      canvasW: canvasW,
                                                      canvasH: canvasH,
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            )









          ],
        ),


        /// ================= FLOATING TEXT TOOLBAR =================
        if (_selectedText != null)
          Positioned(
            top: 8,
            left: 0,
            right: 0,
            child: Center(
              child: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: TextTopToolbar(
                    item: _selectedText!,
                    onUpdate: () {
                      _currentText.notifyListeners();
                      setState(() {});
                    },
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// ================= ValueListenableBuilder2 =================
class ValueListenableBuilder2<A, B> extends StatelessWidget {
  final ValueNotifier<A> first;
  final ValueNotifier<B> second;
  final Widget Function(BuildContext, A, B, Widget?) builder;

  const ValueListenableBuilder2({
    super.key,
    required this.first,
    required this.second,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<A>(
      valueListenable: first,
      builder: (_, a, __) {
        return ValueListenableBuilder<B>(
          valueListenable: second,
          builder: (_, b, ___) => builder(context, a, b, null),
        );
      },
    );
  }
}

/// ================= ValueListenableBuilder3 =================
class ValueListenableBuilder3<A, B, C> extends StatelessWidget {
  final ValueNotifier<A> first;
  final ValueNotifier<B> second;
  final ValueNotifier<C> third;
  final Widget Function(BuildContext, A, B, C, Widget?) builder;

  const ValueListenableBuilder3({
    super.key,
    required this.first,
    required this.second,
    required this.third,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<A>(
      valueListenable: first,
      builder: (_, a, __) {
        return ValueListenableBuilder<B>(
          valueListenable: second,
          builder: (_, b, ___) {
            return ValueListenableBuilder<C>(
              valueListenable: third,
              builder: (_, c, ____) => builder(context, a, b, c, null),
            );
          },
        );
      },
    );
  }
}