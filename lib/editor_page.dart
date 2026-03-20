import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vista_print24/panels/MultiTemplatePanel.dart';
import 'package:vista_print24/panels/save_panel_page.dart';
import 'package:vista_print24/widgets/popup_diloage.dart';

// ================= COMMON =================
import 'common/canvas_orientation.dart';
import 'common/canvas_side.dart';

// ================= PANELS =================
import 'panels/text_panel_page.dart';
import 'panels/uploads_panel_page.dart';
import 'panels/graphics_panel_page.dart';
import 'panels/background_panel_page.dart';
import 'panels/template_panel_page.dart';
import 'panels/qr_panel_page.dart';
import 'panels/tables_panel_page.dart';
import 'panels/design_canvas_page.dart';
import 'panels/full_excel_panel.dart';

// ================= MODELS =================
import 'models/text_item.dart';
import 'models/graphic_item.dart';
import 'models/qr_item.dart';
import 'models/table_item.dart';
import 'models/excel_cell_selection.dart';

enum ToolType {
  text,
  uploads,
  graphics,
  background,
  template,
  qr,
  tables,
  excel,
  savePanel, // <-- new
  multiTemplate, // <-- नया


}

String toolName(ToolType type) {
  switch (type) {
    case ToolType.text:
      return 'Text';
    case ToolType.uploads:
      return 'Uploads';
    case ToolType.graphics:
      return 'Graphics';
    case ToolType.background:
      return 'BG';
    case ToolType.template:
      return 'Template';
    case ToolType.qr:
      return 'QR';
    case ToolType.tables:
      return 'Tables';
    case ToolType.excel:
      return 'Excel';
    case ToolType.savePanel:
      return 'Single Export'; // <-- new
    case ToolType.multiTemplate:
      return 'Multi Export ';


  }
}

class EditorPage extends StatefulWidget {
  const EditorPage({super.key});

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  final ValueNotifier<double> zoomNotifier = ValueNotifier(0.8);

  // ================= UI STATE =================
  bool _templateLoadedFromFirestore = false;
  bool _canvasInitialized = false;
  bool _isLoadingTemplate = true;
  // ================= DOWNLOAD OVERLAY =================
  bool _isExporting = false;
  double _exportProgress = 0.0;
  String? _currentTemplateName; // add at top


  void startExport() {
    setState(() {
      _isExporting = true;
      _exportProgress = 0.0;
    });
  }

  void updateExportProgress(double value) {
    setState(() {
      _exportProgress = value;
    });
  }

  void endExport() {
    setState(() {
      _isExporting = false;
    });
  }



  ToolType activeTool = ToolType.text;
  bool showLeftPanel = true;
  bool showExcelPanel = false;
  bool panelsHiddenByClose = false;


  double excelPanelHeight = 120;
  static const double minExcelHeight = 100;
  static const double maxExcelHeight = 700;

  final ValueNotifier<List<int>> selectedRowIndexes =
  ValueNotifier<List<int>>([]);


  // ================= CANVAS =================
  final GlobalKey canvasKey = GlobalKey();
  final canvasSideNotifier = ValueNotifier<CanvasSide>(CanvasSide.front);
  final orientationNotifier =
  ValueNotifier<CanvasOrientation>(CanvasOrientation.horizontal);

  // ================= FRONT / BACK =================
  final frontText = ValueNotifier<List<TextItem>>([]);
  final backText = ValueNotifier<List<TextItem>>([]);

  final frontBg = ValueNotifier<Color>(Colors.white);
  final backBg = ValueNotifier<Color>(Colors.white);

  final frontImage = ValueNotifier<String?>(null);
  final backImage = ValueNotifier<String?>(null);



  final frontGraphics = ValueNotifier<List<GraphicItem>>([]);
  final backGraphics = ValueNotifier<List<GraphicItem>>([]);

  final frontQrs = ValueNotifier<List<QrItem>>([]);
  final backQrs = ValueNotifier<List<QrItem>>([]);

  // ================= IMAGE STATE (SAFE INIT) =================
  final ValueNotifier<double> frontImageScale = ValueNotifier(1.0);
  final ValueNotifier<Offset> frontImagePosition = ValueNotifier(Offset.zero);

  final ValueNotifier<double> backImageScale = ValueNotifier(1.0);
  final ValueNotifier<Offset> backImagePosition = ValueNotifier(Offset.zero);

// ================= GRID STATE =================
  final ValueNotifier<bool> frontShowGrid = ValueNotifier(true);
  final ValueNotifier<bool> backShowGrid = ValueNotifier(true);

  final frontTables = ValueNotifier<List<TableItem>>([]);
  final backTables = ValueNotifier<List<TableItem>>([]);

  // ================= EXCEL =================
  final selectedExcelCell = ValueNotifier<ExcelCellSelection?>(null);
  final excelDataNotifier = ValueNotifier<List<List<String>>>([]);



  final widthCmNotifier = ValueNotifier<double>(0);
  final heightCmNotifier = ValueNotifier<double>(0);

  final showGridNotifier = ValueNotifier<bool>(false);


  void _closeAllPanelsExceptExcel() {
    setState(() {
      panelsHiddenByClose = true;
      activeTool = ToolType.text; // ya koi dummy/default
    });
  }


  @override
  void initState() {
    super.initState();
    _loadExcelPanelState();
    showExcelPanel = true; // ✅ always visible


    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      final sizeSelected = prefs.getBool('canvasSizeSelected') ?? false;

      if (!sizeSelected) {
        _showStartupSizeDialog();
      } else {
        // ✅ Yahan Firestore se latest template load hoga
        await _loadLatestTemplateOnStartup();
      }
    });
  }


  void _checkAndShowStartupDialog() {
    // Agar template ya autosave load ho chuka hai
    if (_templateLoadedFromFirestore || _canvasInitialized) {
      return;
    }

    _showStartupSizeDialog();
  }


  // ================= TEMPLATE APPLY =================
  void applyTemplate({
    required String templateId,
    required double widthCm,
    required String templateName, // ✅ ADD THIS


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
  }) {

    // 🔥 DEBUG PRINT
    debugPrint("=========== TEMPLATE RECEIVED IN EDITOR ===========");
    debugPrint("Template ID   : $templateId");
    debugPrint("Template Name : $templateName");
    debugPrint("Size          : $widthCm x $heightCm");
    debugPrint("===================================================");
    _templateLoadedFromFirestore = true;
    _canvasInitialized = true;

    widthCmNotifier.value = widthCm;
    heightCmNotifier.value = heightCm;
    showGridNotifier.value = showGrid;

    this.frontBg.value = frontBg;
    this.frontImage.value = frontImage;
    this.frontText.value = frontTexts;
    this.frontQrs.value = frontQrs;
    this.frontGraphics.value = frontGraphics;
    this.frontTables.value = frontTables;

    this.backBg.value = backBg;
    this.backImage.value = backImage;
    this.backText.value = backTexts;
    this.backQrs.value = backQrs;
    this.backGraphics.value = backGraphics;
    this.backTables.value = backTables;
    // 🔥 ADD THESE TWO LINES
    _isLoadingTemplate = false;
    _currentTemplateName = templateName; // ⭐ IMPORTANT

    Future.microtask(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("lastTemplateId", templateId);
    });
    setState(() {});
  }



  // ================= PANEL CONTROLS =================
  void _toggleLeftPanel() => setState(() => showLeftPanel = !showLeftPanel);


  void _switchCanvasSide() {
    final newSide = canvasSideNotifier.value == CanvasSide.front
        ? CanvasSide.back
        : CanvasSide.front;

    canvasSideNotifier.value = newSide;
    canvasSideNotifier.notifyListeners(); // ✅ FORCE canvas rebuild

    // Optional: small delay to ensure rebuild
    Future.delayed(const Duration(milliseconds: 100), () {
      frontText.notifyListeners();
      backText.notifyListeners();
      frontBg.notifyListeners();
      backBg.notifyListeners();
      frontGraphics.notifyListeners();
      backGraphics.notifyListeners();
      frontQrs.notifyListeners();
      backQrs.notifyListeners();
      frontTables.notifyListeners();
      backTables.notifyListeners();
    });

    selectedExcelCell.value = null;
    _saveExcelPanelState();

    setState(() {});
  }

  void _showStartupSizeDialog() {
    CanvasSizeSelectionDialog.show(

      context: context,
      onStart: (width, height, orientation) async {
        _canvasInitialized = true;

        widthCmNotifier.value = width;
        heightCmNotifier.value = height;
        orientationNotifier.value = orientation;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('canvasSizeSelected', true);

        // 🔥 IMPORTANT FIX
        _isLoadingTemplate = false;
        setState(() {});
      },
    );
  }







  // ================= EXCEL PANEL PERSISTENCE =================
  Future<void> _saveExcelPanelState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('excelPanelVisible', showExcelPanel);
    await prefs.setDouble('excelPanelHeight', excelPanelHeight);
    if (selectedExcelCell.value != null) {
      await prefs.setString('excelSelectedCell',
          '${selectedExcelCell.value!.row},${selectedExcelCell.value!.col}');
    } else {
      await prefs.remove('excelSelectedCell');
    }
  }

  Future<void> _loadExcelPanelState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      showExcelPanel = prefs.getBool('excelPanelVisible') ?? false;
      excelPanelHeight = prefs.getDouble('excelPanelHeight') ?? 420;

      final selectedCellString = prefs.getString('excelSelectedCell');
      if (selectedCellString != null) {
        final parts = selectedCellString.split(',');
        if (parts.length == 2) {
          selectedExcelCell.value = ExcelCellSelection(
            row: int.tryParse(parts[0]) ?? 0,
            col: int.tryParse(parts[1]) ?? 0, value: '', address: '',
          );
        }
      }
    });
  }

  Future<void> _loadLatestTemplateOnStartup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastTemplateId = prefs.getString('lastTemplateId');

      DocumentSnapshot? doc;

      if (lastTemplateId != null) {
        // Try to load last applied template
        final docSnap = await FirebaseFirestore.instance
            .collection("canvas_temp")
            .doc(lastTemplateId)
            .get();

        if (docSnap.exists) {
          doc = docSnap;
        }
      }

      // Agar lastTemplateId valid na ho, fetch latest
      if (doc == null) {
        final tempSnap = await FirebaseFirestore.instance
            .collection("canvas_temp")
            .orderBy("lastUpdated", descending: true)
            .limit(1)
            .get();

        if (tempSnap.docs.isNotEmpty) {
          doc = tempSnap.docs.first;
        }
      }

      if (doc != null && doc.exists) {
        final data = doc.data() as Map<String, dynamic>;

        final front = data["front"] ?? {};
        final back = data["back"] ?? {};

        Offset parsePosition(Map? pos) => Offset(
          (pos?["dx"] ?? 0).toDouble(),
          (pos?["dy"] ?? 0).toDouble(),
        );

        final templateName = data["templateName"] ?? data["name"] ?? "Untitled";

        applyTemplate(
          templateId: doc.id,
          templateName: templateName,
          widthCm: (data["widthCm"] ?? 10).toDouble(),
          heightCm: (data["heightCm"] ?? 10).toDouble(),
          showGrid: data["showGrid"] ?? false,
          frontBg: Color(front["bg"] ?? 0xFFFFFFFF),
          backBg: Color(back["bg"] ?? 0xFFFFFFFF),
          frontImage: front["image"],
          frontImagePosition: parsePosition(front["imagePosition"]),
          frontImageScale: (front["imageScale"] ?? 1.0).toDouble(),
          backImage: back["image"],
          backImagePosition: parsePosition(back["imagePosition"]),
          backImageScale: (back["imageScale"] ?? 1.0).toDouble(),
          frontTexts: (front["texts"] as List? ?? [])
              .map((e) => TextItem.fromJson(e))
              .toList(),
          backTexts: (back["texts"] as List? ?? [])
              .map((e) => TextItem.fromJson(e))
              .toList(),
          frontQrs: (front["qrs"] as List? ?? [])
              .map((e) => QrItem.fromJson(e))
              .toList(),
          backQrs: (back["qrs"] as List? ?? [])
              .map((e) => QrItem.fromJson(e))
              .toList(),
          frontGraphics: (front["graphics"] as List? ?? [])
              .map((e) => GraphicItem.fromJson(e))
              .toList(),
          backGraphics: (back["graphics"] as List? ?? [])
              .map((e) => GraphicItem.fromJson(e))
              .toList(),
          frontTables: (front["tables"] as List? ?? [])
              .map((e) => TableItem.fromMap(e))
              .toList(),
          backTables: (back["tables"] as List? ?? [])
              .map((e) => TableItem.fromMap(e))
              .toList(),
        );

        // 🔥 Save last template ID
        await prefs.setString('lastTemplateId', doc.id);

      } else {
        _showStartupSizeDialog();
      }
    } catch (e) {
      debugPrint("Error loading startup template: $e");
      _showStartupSizeDialog();
    }
  }

  // ================= BUILD =================
  @override
  Widget build(BuildContext context) {

    // ✅ Jab tak width ya height 0 hai tab tak loading dikhao
    if (!_canvasInitialized && !_templateLoadedFromFirestore) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }


    final isFront = canvasSideNotifier.value == CanvasSide.front;

    final currentText = isFront ? frontText : backText;
    final currentBg = isFront ? frontBg : backBg;
    final currentGraphics = isFront ? frontGraphics : backGraphics;
    final currentQrs = isFront ? frontQrs : backQrs;
    final currentTables = isFront ? frontTables : backTables;



    return Scaffold(
      backgroundColor: const Color(0xfff4f6f8),
      body: SafeArea(
        child: Stack(
          children: [
            // ================= MAIN LAYOUT =================
            Row(
              children: [
                // ================= LEFT TOOLBAR =================
                _leftToolbar(),

                // ================= LEFT PANEL =================
                if (showLeftPanel && !panelsHiddenByClose)
                  Container(
                    width: 320,
                    color: Colors.white,
                    child: _leftPanel(
                      currentText,
                      currentBg,
                      currentGraphics,
                      currentQrs,
                      currentTables,
                    ),
                  ),

                // ================= CENTER CANVAS =================
                Expanded(
                  child: Column(
                    children: [

                      // ================= CANVAS AREA =================
                      Expanded(
                        child: Center(
                          child: DesignCanvasPage(
                            canvasKey: canvasKey,
                            orientation: orientationNotifier,
                            canvasSide: canvasSideNotifier,
                            frontText: frontText,
                            backText: backText,
                            currentTemplateName: _currentTemplateName, // ⭐ ADD THIS
                            frontGraphics: frontGraphics,
                            backGraphics: backGraphics,
                            frontQrs: frontQrs,
                            backQrs: backQrs,
                            frontTables: frontTables,
                            backTables: backTables,
                            frontBg: frontBg,
                            backBg: backBg,
                            frontImage: frontImage,
                            backImage: backImage,
                            widthCm: widthCmNotifier,
                            heightCm: heightCmNotifier,
                            frontImageScale: frontImageScale,
                            frontImagePosition: frontImagePosition,
                            backImageScale: backImageScale,
                            backImagePosition: backImagePosition,
                            frontShowGrid: frontShowGrid,
                            backShowGrid: backShowGrid,
                            excelDataNotifier: excelDataNotifier,
                            zoomNotifier: zoomNotifier,
                          ),
                        ),
                      ),

                      // ================= EXCEL PANEL =================
                      if (showExcelPanel)
                        Container(
                          height: excelPanelHeight,
                          color: Colors.white,
                          child: Column(
                            children: [
                              MouseRegion(
                                cursor: SystemMouseCursors.resizeUpDown,
                                child: GestureDetector(
                                  onVerticalDragUpdate: (details) {
                                    setState(() {
                                      excelPanelHeight -= details.delta.dy;
                                      excelPanelHeight = excelPanelHeight.clamp(
                                        minExcelHeight,
                                        maxExcelHeight,
                                      );
                                    });
                                    _saveExcelPanelState();
                                  },
                                  child: Container(
                                    height: 8,
                                    color: const Color(0xffe0e0e0),
                                  ),
                                ),
                              ),
                              Container(
                                height: 30,
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: const Text(
                                  "Excel Panel",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Expanded(
                                child: FullExcelPanel(
                                  textItems: currentText,
                                  selectedExcelCell: selectedExcelCell,
                                  excelDataNotifier: excelDataNotifier,
                                  selectedRowIndexes: selectedRowIndexes,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),


              ],
            ),


            if (true)

              if (_isExporting)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.6), // fullscreen light black
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            value: _exportProgress,
                            strokeWidth: 6,
                            valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.white),
                            backgroundColor: Colors.white24,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            "${(_exportProgress * 100).toInt()}%",
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Downloading...",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),



          ],


        ),
      ),
    );
  }

  Widget _leftPanel(ValueNotifier<List<TextItem>> currentText,
      ValueNotifier<Color> currentBg,
      ValueNotifier<List<GraphicItem>> currentGraphics,
      ValueNotifier<List<QrItem>> currentQrs,
      ValueNotifier<List<TableItem>> currentTables,) {
    switch (activeTool) {
      case ToolType.text:
        return TextPanelPage(
          frontText: frontText,
          backText: backText,
          canvasSide: canvasSideNotifier,
          onToggle: _toggleLeftPanel,
          selectedExcelCell: selectedExcelCell,
          excelDataNotifier: excelDataNotifier,
        );
      case ToolType.uploads:
        return UploadsPanelPage(
          graphics: currentGraphics,
          excelDataNotifier: excelDataNotifier,
          selectedExcelCell: selectedExcelCell,
        );
      case ToolType.graphics:
        return GraphicsPanelPage(graphics: currentGraphics);
      case ToolType.background:
        return BackgroundPanelPage(backgroundColor: currentBg);
      case ToolType.template:
        return TemplatePanelPage(
          onApply: applyTemplate,

          onHide: _toggleLeftPanel,
        );
      case ToolType.qr:
        return QrPanelPage(qrs: currentQrs);
      case ToolType.tables:
        return TablesPanelPage(tables: currentTables);
      case ToolType.excel:
        return const SizedBox.shrink();
      case ToolType.savePanel:
        return SavePanelPage(
          canvasKey: canvasKey,
          canvasSide: canvasSideNotifier,
          widthCm: widthCmNotifier,
          heightCm: heightCmNotifier,

          onStartExport: startExport,
          onProgress: updateExportProgress,
          onEndExport: endExport,
        );

      case ToolType.multiTemplate:
        return MultiTemplatePanel(
          canvasKey: canvasKey,
          excelDataNotifier: excelDataNotifier,
          selectedExcelCell: selectedExcelCell,
          frontText: frontText,
          backText: backText,
          canvasSide: canvasSideNotifier,
          selectedExcelRows: selectedRowIndexes,
          widthCm: widthCmNotifier.value,
          heightCm: heightCmNotifier.value,

          // 🔥 ADD THESE 3 LINES
          onStartExport: startExport,
          onProgress: updateExportProgress,
          onEndExport: endExport,
        );








    }
  }

  Widget _leftToolbar() {
    return Container(
      width: 90,
      color: Colors.white,
      child: Column(
        children: [
          _tool(Icons.text_fields, ToolType.text),
          _tool(Icons.image, ToolType.uploads),
          _tool(Icons.brush, ToolType.graphics),
          _tool(Icons.crop_square, ToolType.background),
          _tool(Icons.view_module, ToolType.template),
          _tool(Icons.qr_code, ToolType.qr),
          _tool(Icons.table_chart, ToolType.tables),
          _tool(Icons.table_view, ToolType.excel),
          _tool(Icons.save, ToolType.savePanel),
          _tool(Icons.layers, ToolType.multiTemplate),


          _tool(
            Icons.swap_horiz,
            null,
            label: 'Swap',
            onTap: _switchCanvasSide,
          ),
        ],
      ),
    );
  }

  Widget _tool(
      IconData icon,
      ToolType? type, {
        String? label,
        VoidCallback? onTap,
      }) {
    final bool isActive =
        type != null && activeTool == type && type != ToolType.excel;

    return InkWell(
      onTap: () {
        if (onTap != null) {
          onTap();
          return;
        }

        if (type == null) return;

        setState(() {
          activeTool = type;

          if (type == ToolType.excel) {
            showLeftPanel = true;
            panelsHiddenByClose = true;
            showExcelPanel = true;
          } else {panelsHiddenByClose = false;
          showLeftPanel = true;
          }
        });

        _saveExcelPanelState();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        width: double.infinity,
        child: Column(
          children: [
            Icon(
              icon,
              size: 22,
              color: isActive ? Colors.blue : Colors.grey,
            ),
            const SizedBox(height: 4),
            Text(
              label ?? (type != null ? toolName(type) : ''),
              style: TextStyle(
                fontSize: 11,
                color: isActive ? Colors.blue : Colors.grey,
                fontWeight:
                isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

}