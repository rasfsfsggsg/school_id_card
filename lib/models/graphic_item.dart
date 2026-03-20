import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';

/// ================= GRAPHIC TYPES =================
enum GraphicType {
  rectangle,
  circle,
  icon,
  image,
  line,
  dashedLine,
  thickLine,
  arrowLine,
  doubleLine,
  star,
  polygon,
}

/// ================= GRAPHIC ITEM =================
class GraphicItem {
  // ================= BASIC =================
  final String id;
  final GraphicType type;
  int zIndex;
  Color? borderColor;
  double? borderWidth;
  bool showProtectIcon = false; // NEW
  bool showRotationHandle = false; // new optional flag


  // ================= DATA =================
  final IconData? icon;

  /// Network image (imgbb / assets / templates)
  final String? imageUrl;

  /// Mobile / Desktop picked image
  final File? imageFile;

  /// Web picked image / image bytes
  Uint8List? imageBytes;
  double? borderRadius;


  /// For lines selection
  ValueNotifier<GraphicItem?> selectedLine = ValueNotifier(null);

  /// ===== EXCEL BINDING =====
  String? name;        // Excel cell value
  bool excelBound;     // true if bound to Excel cell
  String? excelColumn; // column letter (A, B, etc.)
  double? imageOriginalWidth;
  double? imageOriginalHeight;
  double aspectRatio; // width / height

  // ================= TRANSFORM =================
  Offset position;
  double scale;
  double rotation;
  double width;
  bool isRotating = false;
  double height;
  bool showResizeHandles = false;

  // ================= STYLE =================
  Color color;
  bool locked;
  GlobalKey boxKey = GlobalKey();
  BoxFit fitMode;

  // ================= CONSTRUCTOR =================
  GraphicItem({
    required this.id,
    required this.type,
    this.zIndex = 0,
    this.aspectRatio = 1.0,
    this.width = 100,      // 🔥 NEW
    this.height = 100,     // 🔥 NEW
    this.icon,
    this.imageUrl,
    this.imageFile,
    this.imageBytes,
    this.position = const Offset(150, 150),
    this.fitMode = BoxFit.contain,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.borderRadius, // NEW

    Color? color,
    this.locked = false,
    this.borderColor,
    this.borderWidth,
    this.name,
    this.excelBound = false,
    this.excelColumn,
  }) : color = color ?? Colors.black;

  // ================= COPY / DUPLICATE =================
  GraphicItem copyWith({
    Offset? position,
    double? scale,
    double? rotation,
    BoxFit? fitMode,
    Color? color,
    bool? locked,
    String? name,
    bool? excelBound,
    String? excelColumn,
    Uint8List? imageBytes,
    String? imageUrl,
    int? zIndex,   // 👈 ADD THIS

    Color? borderColor,
    double? borderWidth,
  }) {
    return GraphicItem(
      id: id,
      type: type,
      icon: icon,
      imageUrl: imageUrl ?? this.imageUrl,
      imageFile: imageFile,
      imageBytes: imageBytes ?? this.imageBytes,
      zIndex: zIndex ?? this.zIndex,   // 👈 ADD THIS

      position: position ?? this.position,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      color: color ?? this.color,
      locked: locked ?? this.locked,
      name: name ?? this.name,
      excelBound: excelBound ?? this.excelBound,
      excelColumn: excelColumn ?? this.excelColumn,
      fitMode: fitMode ?? this.fitMode,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
    );
  }

  /// Create a new duplicate with a new ID
  GraphicItem duplicate(String newId) {
    return GraphicItem(
      id: newId,
      type: type,
      icon: icon,
      borderRadius: borderRadius, // COPY the radius

      imageUrl: imageUrl,
      imageFile: imageFile,
      imageBytes: imageBytes,
      position: position + const Offset(20, 20), // slight offset
      scale: scale,
      rotation: rotation,
      color: color,
      locked: false,
      name: name,
      excelBound: excelBound,
      excelColumn: excelColumn,
      borderColor: borderColor,
      borderWidth: borderWidth,
    );
  }

  void toggleLock() => locked = !locked;

  // ================= STYLE HELPERS =================
  Color get safeColor => (color.opacity == 0 || color == Colors.transparent) ? Colors.black : color;

  // ================= IMAGE HELPERS =================
  bool get hasImage => imageBytes != null || imageFile != null || (imageUrl != null && imageUrl!.isNotEmpty);

  ImageProvider? get imageProvider {
    if (imageBytes != null) return MemoryImage(imageBytes!);
    if (imageFile != null) return FileImage(imageFile!);
    if (imageUrl != null && imageUrl!.isNotEmpty) return NetworkImage(imageUrl!);
    return null;
  }

  // ================= TRANSFORM SAFETY =================
  void clampScale({double min = 0.2, double max = 5.0}) => scale = scale.clamp(min, max);
  void normalizeRotation() => rotation = rotation % (2 * 3.141592653589793);

  // ================= VALIDATION =================
  bool get isValid {
    switch (type) {
      case GraphicType.icon:
        return icon != null;
      case GraphicType.image:
        return imageProvider != null;
      case GraphicType.rectangle:
      case GraphicType.circle:
      case GraphicType.line:
      case GraphicType.dashedLine:
      case GraphicType.thickLine:
      case GraphicType.arrowLine:
      case GraphicType.doubleLine:
      case GraphicType.star:
      case GraphicType.polygon:
        return true;
    }
  }

  // ================= FIRESTORE / JSON SERIALIZATION =================
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.index,
      'iconCodePoint': icon?.codePoint,
      'iconFontFamily': icon?.fontFamily,
      'iconFontPackage': icon?.fontPackage,
      'imageUrl': imageUrl,
      'imageBytes': imageBytes != null ? base64Encode(imageBytes!) : null,
      'position': {'dx': position.dx, 'dy': position.dy},
      'scale': scale,
      'rotation': rotation,
      'color': color.value,
      'locked': locked,
      'name': name,
      'excelBound': excelBound,
      'excelColumn': excelColumn,
      'borderColor': borderColor?.value,
      'borderWidth': borderWidth,
    };
  }

  factory GraphicItem.fromMap(Map<String, dynamic> map) {
    return GraphicItem(
      id: map['id'],
      type: GraphicType.values[map['type']],
      icon: map['iconCodePoint'] != null
          ? IconData(map['iconCodePoint'],
          fontFamily: map['iconFontFamily'], fontPackage: map['iconFontPackage'])
          : null,
      imageUrl: map['imageUrl'],
      imageBytes: map['imageBytes'] != null ? base64Decode(map['imageBytes']) : null,
      position: map['position'] != null
          ? Offset((map['position']['dx'] as num).toDouble(), (map['position']['dy'] as num).toDouble())
          : const Offset(150, 150),
      scale: (map['scale'] as num?)?.toDouble() ?? 1.0,
      rotation: (map['rotation'] as num?)?.toDouble() ?? 0.0,
      color: map['color'] != null ? Color(map['color']) : Colors.black,
      locked: map['locked'] ?? false,
      name: map['name'],
      excelBound: map['excelBound'] ?? false,
      excelColumn: map['excelColumn'],
      borderColor: map['borderColor'] != null ? Color(map['borderColor']) : null,
      borderWidth: (map['borderWidth'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => toMap();
  factory GraphicItem.fromJson(Map<String, dynamic> json) => GraphicItem.fromMap(json);

}