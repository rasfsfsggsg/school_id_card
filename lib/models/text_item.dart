import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

/// LIST TYPE
enum TextListType { none, bullet, number }

/// SCRIPT TYPE
enum TextScriptType { normal, superscript, subscript }

/// VERTICAL ALIGN
enum VerticalAlign { top, center, bottom }

class TextItem {
  // ================= BASIC =================
  final String id;
  Offset position;
  int zIndex;
  bool isVisible;


  // ================= TRANSFORM =================
  double scale;
  double rotation;
  double skewX;
  double skewY;
  bool flipX;
  bool flipY;
  bool locked;

  // ================= FONT =================
  String fontFamily;
  double fontSize;
  FontWeight fontWeight;
  FontStyle fontStyle;

  // ================= DECORATION =================
  bool underline;
  bool strike;

  // ================= SCRIPT =================
  TextScriptType scriptType;

  // ================= COLOR & ALIGN =================
  Color color;
  Gradient? textGradient;
  Color? backgroundColor;
  Gradient? backgroundGradient;
  double backgroundRadius;
  EdgeInsets backgroundPadding;
  TextAlign align;
  VerticalAlign verticalAlign;

  // ================= SPACING =================
  double letterSpacing;
  double lineSpacing;

  // ================= EFFECTS =================
  double opacity;

  // ================= SHADOW =================
  bool shadow;
  Color shadowColor;
  double shadowBlur;
  Offset shadowOffset;

  // ================= STROKE =================
  bool stroke;
  Color strokeColor;
  double strokeWidth;
  StrokeJoin strokeJoin;
  StrokeCap strokeCap;
  List<double>? strokeDashArray;

  // ================= BLUR =================
  double blur;

  // ================= LIST =================
  TextListType listType;
  int listIndex;

  // ================= STATE =================
  bool isEditing;

  // ================= CONTROLLER =================
  final TextEditingController controller;

  // ================= EXCEL BINDING =================
  String? excelColumn;
  int excelRow;
  bool excelBound;
  double boxHeight = 0; // 0 = auto
  FocusNode? focusNode;
  final GlobalKey boxKey = GlobalKey();
  final LayerLink layerLink = LayerLink(); // ⭐ MUST
  Size size; // ✅ ADD THIS






  // ================= BORDERS / POPUP FIELDS =================
  Color borderColor;
  double borderWidth;
  double roundCorner;
  bool shrinkToFit;
  int posX;
  int posY;
  String justification; // e.g., TopLeft / Center / BottomLeft
  bool border;
  bool autoSize;
  bool wrapText;

  // ================= WRAP WIDTH =================
  double wrapWidth;

  // ================= CONSTRUCTOR =================
  TextItem({
    String? id,
    required String text,
    this.position = const Offset(100, 100),
    this.zIndex = 0,
    this.isVisible = true,
    this.scale = 1,
    this.rotation = 0,
    this.skewX = 0,
    this.skewY = 0,
    this.size = const Size(150, 50), // ✅ DEFAULT VALUE

    this.flipX = false,
    this.flipY = false,
    this.locked = false,
    this.fontFamily = 'Arimo',
    this.fontSize = 28,
    this.fontWeight = FontWeight.normal,
    this.fontStyle = FontStyle.normal,
    this.underline = false,
    this.strike = false,
    this.scriptType = TextScriptType.normal,
    this.color = Colors.black,
    this.textGradient,
    this.backgroundColor,
    this.backgroundGradient,
    this.backgroundRadius = 0,
    this.backgroundPadding = const EdgeInsets.all(4),
    this.align = TextAlign.left,
    this.verticalAlign = VerticalAlign.top,
    this.letterSpacing = 0,
    this.lineSpacing = 1.2,
    this.opacity = 1,
    this.shadow = false,
    this.shadowColor = const Color(0x55000000),
    this.shadowBlur = 6,
    this.shadowOffset = const Offset(2, 2),
    this.stroke = false,
    this.strokeColor = Colors.black,
    this.strokeWidth = 1,
    this.strokeJoin = StrokeJoin.round,
    this.strokeCap = StrokeCap.round,
    this.strokeDashArray,
    this.blur = 0,
    this.listType = TextListType.none,
    this.listIndex = 0,
    this.isEditing = false,
    this.excelColumn,
    this.excelRow = 1,
    this.excelBound = false,
    this.posX = 40,
    this.posY = 26,
    this.justification = 'BottomLeft',
    this.border = false,
    this.borderColor = Colors.black,
    this.borderWidth = 1.0,
    this.roundCorner = 0.0,
    this.shrinkToFit = false,
    this.autoSize = false,
    this.wrapText = false,
    this.wrapWidth = 150, // default wrap width
  })  : id = id ?? const Uuid().v4(),
        controller = TextEditingController(text: text);

  // ================= DISPLAY TEXT =================
  String get displayText {
    switch (listType) {
      case TextListType.bullet:
        return "• ${controller.text}";
      case TextListType.number:
        return "${listIndex + 1}. ${controller.text}";
      default:
        return controller.text;
    }
  }

  double get scriptScale => scriptType == TextScriptType.normal ? 1 : 0.7;

  Offset get scriptOffset {
    switch (scriptType) {
      case TextScriptType.superscript:
        return const Offset(0, -8);
      case TextScriptType.subscript:
        return const Offset(0, 6);
      default:
        return Offset.zero;
    }
  }

  void toggleLock() => locked = !locked;

  String get text => controller.text;

  void setText(String value) {
    controller.value = controller.value.copyWith(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  void bindToExcel({required String column, int startRow = 1}) {
    excelColumn = column;
    excelRow = startRow;
    excelBound = true;
  }

  void nextExcelRow(List<String>? columnData) {
    if (!excelBound || columnData == null) return;
    excelRow++;
    if (excelRow < columnData.length) setText(columnData[excelRow]);
  }

  void dispose() => controller.dispose();

  // ================= COPYWITH =================
  TextItem copyWith({
    String? id,
    Offset? position,
    int? zIndex,   // 👈 ADD THIS

    double? scale,
    double? rotation,
    String? fontFamily,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    bool? underline,
    bool? strike,
    Color? color,
    TextAlign? align,
    VerticalAlign? verticalAlign,
    int? posX,
    int? posY,
    String? justification,
    bool? border,
    Color? borderColor,
    double? borderWidth,
    double? roundCorner,
    bool? shrinkToFit,
    bool? autoSize,
    bool? wrapText,
    double? wrapWidth,
  }) {
    return TextItem(
      id: id ?? this.id,
      text: controller.text,
      position: position ?? this.position,
      zIndex: zIndex ?? this.zIndex,   // 👈 ADD THIS

      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      fontWeight: fontWeight ?? this.fontWeight,
      fontStyle: fontStyle ?? this.fontStyle,
      underline: underline ?? this.underline,
      strike: strike ?? this.strike,
      color: color ?? this.color,
      align: align ?? this.align,
      verticalAlign: verticalAlign ?? this.verticalAlign,
      posX: posX ?? this.posX,
      posY: posY ?? this.posY,
      justification: justification ?? this.justification,
      border: border ?? this.border,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      roundCorner: roundCorner ?? this.roundCorner,
      shrinkToFit: shrinkToFit ?? this.shrinkToFit,
      autoSize: autoSize ?? this.autoSize,
      wrapText: wrapText ?? this.wrapText,
      wrapWidth: wrapWidth ?? this.wrapWidth,
    );
  }

  // ================= FIRESTORE SERIALIZATION =================
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'position': {'dx': position.dx, 'dy': position.dy},
      'zIndex': zIndex,
      'isVisible': isVisible,
      'scale': scale,
      'rotation': rotation,
      'skewX': skewX,
      'skewY': skewY,
      'flipX': flipX,
      'flipY': flipY,
      'locked': locked,
      'fontFamily': fontFamily,
      'fontSize': fontSize,
      'fontWeight': fontWeight.index,
      'fontStyle': fontStyle.index,
      'underline': underline,
      'strike': strike,
      'scriptType': scriptType.index,
      'color': color.value,
      'textGradient': null,
      'backgroundColor': backgroundColor?.value,
      'backgroundGradient': null,
      'backgroundRadius': backgroundRadius,
      'backgroundPadding': {
        'left': backgroundPadding.left,
        'top': backgroundPadding.top,
        'right': backgroundPadding.right,
        'bottom': backgroundPadding.bottom,
      },
      'align': align.index,
      'verticalAlign': verticalAlign.index,
      'letterSpacing': letterSpacing,
      'lineSpacing': lineSpacing,
      'opacity': opacity,
      'shadow': shadow,
      'shadowColor': shadowColor.value,
      'shadowBlur': shadowBlur,
      'shadowOffset': {'dx': shadowOffset.dx, 'dy': shadowOffset.dy},
      'stroke': stroke,
      'strokeColor': strokeColor.value,
      'strokeWidth': strokeWidth,
      'strokeJoin': strokeJoin.index,
      'strokeCap': strokeCap.index,
      'strokeDashArray': strokeDashArray,
      'blur': blur,
      'listType': listType.index,
      'listIndex': listIndex,
      'isEditing': isEditing,
      'excelColumn': excelColumn,
      'excelRow': excelRow,
      'excelBound': excelBound,
      'posX': posX,
      'posY': posY,
      'justification': justification,
      'border': border,
      'borderColor': borderColor.value,
      'borderWidth': borderWidth,
      'roundCorner': roundCorner,
      'shrinkToFit': shrinkToFit,
      'autoSize': autoSize,
      'wrapText': wrapText,
      'wrapWidth': wrapWidth,
      'text': controller.text,
    };
  }

  factory TextItem.fromMap(Map<String, dynamic> map) {
    return TextItem(
      id: map['id'],
      text: map['text'] ?? '',
      position: Offset(
        (map['position']?['dx'] ?? 0).toDouble(),
        (map['position']?['dy'] ?? 0).toDouble(),
      ),
      zIndex: map['zIndex'] ?? 0,
      isVisible: map['isVisible'] ?? true,
      scale: (map['scale'] ?? 1).toDouble(),
      rotation: (map['rotation'] ?? 0).toDouble(),
      skewX: (map['skewX'] ?? 0).toDouble(),
      skewY: (map['skewY'] ?? 0).toDouble(),
      flipX: map['flipX'] ?? false,
      flipY: map['flipY'] ?? false,
      locked: map['locked'] ?? false,
      fontFamily: map['fontFamily'] ?? 'Arimo',
      fontSize: (map['fontSize'] ?? 28).toDouble(),
      fontWeight: FontWeight.values[map['fontWeight'] ?? 3],
      fontStyle: FontStyle.values[map['fontStyle'] ?? 0],
      underline: map['underline'] ?? false,
      strike: map['strike'] ?? false,
      scriptType: TextScriptType.values[map['scriptType'] ?? 0],
      color: Color(map['color'] ?? 0xFF000000),
      backgroundColor: map['backgroundColor'] != null ? Color(map['backgroundColor']) : null,
      backgroundRadius: (map['backgroundRadius'] ?? 0).toDouble(),
      backgroundPadding: EdgeInsets.fromLTRB(
        (map['backgroundPadding']?['left'] ?? 4).toDouble(),
        (map['backgroundPadding']?['top'] ?? 4).toDouble(),
        (map['backgroundPadding']?['right'] ?? 4).toDouble(),
        (map['backgroundPadding']?['bottom'] ?? 4).toDouble(),
      ),
      align: TextAlign.values[map['align'] ?? 0],
      verticalAlign: VerticalAlign.values[map['verticalAlign'] ?? 0],
      letterSpacing: (map['letterSpacing'] ?? 0).toDouble(),
      lineSpacing: (map['lineSpacing'] ?? 1.2).toDouble(),
      opacity: (map['opacity'] ?? 1).toDouble(),
      shadow: map['shadow'] ?? false,
      shadowColor: Color(map['shadowColor'] ?? 0x55000000),
      shadowBlur: (map['shadowBlur'] ?? 6).toDouble(),
      shadowOffset: Offset(
        (map['shadowOffset']?['dx'] ?? 2).toDouble(),
        (map['shadowOffset']?['dy'] ?? 2).toDouble(),
      ),
      stroke: map['stroke'] ?? false,
      strokeColor: Color(map['strokeColor'] ?? 0xFF000000),
      strokeWidth: (map['strokeWidth'] ?? 1).toDouble(),
      strokeJoin: StrokeJoin.values[map['strokeJoin'] ?? 0],
      strokeCap: StrokeCap.values[map['strokeCap'] ?? 0],
      strokeDashArray: map['strokeDashArray'] != null ? List<double>.from(map['strokeDashArray']) : null,
      blur: (map['blur'] ?? 0).toDouble(),
      listType: TextListType.values[map['listType'] ?? 0],
      listIndex: map['listIndex'] ?? 0,
      isEditing: map['isEditing'] ?? false,
      excelColumn: map['excelColumn'],
      excelRow: map['excelRow'] ?? 1,
      excelBound: map['excelBound'] ?? false,
      posX: map['posX'] ?? 40,
      posY: map['posY'] ?? 26,
      justification: map['justification'] ?? 'BottomLeft',
      border: map['border'] ?? false,
      borderColor: Color(map['borderColor'] ?? 0xFF000000),
      borderWidth: (map['borderWidth'] ?? 1.0).toDouble(),
      roundCorner: (map['roundCorner'] ?? 0.0).toDouble(),
      shrinkToFit: map['shrinkToFit'] ?? false,
      autoSize: map['autoSize'] ?? false,
      wrapText: map['wrapText'] ?? false,
      wrapWidth: (map['wrapWidth'] ?? 150).toDouble(),
    );
  }

  // ================= JSON ALIAS =================
  Map<String, dynamic> toJson() => toMap();

  factory TextItem.fromJson(Map<String, dynamic> json) => TextItem.fromMap(json);

}
