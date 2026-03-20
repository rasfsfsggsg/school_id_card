import 'package:flutter/material.dart';

class QrItem {
  final String id;
  int zIndex;

  /// QR data (URL or text)
  String data;

  GlobalKey boxKey = GlobalKey();
  final LayerLink layerLink = LayerLink();

  /// Optional image URL
  String? imageUrl;

  /// Canvas properties
  Offset position;
  double scale;
  double rotation;
  Color color;

  /// Border properties
  Color? borderColor;
  double borderWidth;
  double borderRadius;

  bool locked;
  double width;
  double height;

  QrItem({
    this.zIndex = 0,
    required this.id,
    required this.data,
    this.imageUrl,
    this.position = const Offset(100, 100),
    this.scale = 1.0,
    this.rotation = 0,
    this.width = 140,
    this.height = 140,
    this.color = Colors.black,

    /// Border defaults
    this.borderColor = Colors.transparent,
    this.borderWidth = 0,
    this.borderRadius = 0,

    this.locked = false,
  });

  // ================= COPY WITH =================
  QrItem copyWith({
    String? id,
    String? data,
    String? imageUrl,
    Offset? position,
    double? scale,
    double? rotation,
    int? zIndex,
    Color? color,
    bool? locked,
    double? width,
    double? height,

    /// Border
    Color? borderColor,
    double? borderWidth,
    double? borderRadius,
  }) {
    return QrItem(
      id: id ?? this.id,
      data: data ?? this.data,
      imageUrl: imageUrl ?? this.imageUrl,
      position: position ?? this.position,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      zIndex: zIndex ?? this.zIndex,
      color: color ?? this.color,
      locked: locked ?? this.locked,
      width: width ?? this.width,
      height: height ?? this.height,

      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      borderRadius: borderRadius ?? this.borderRadius,
    );
  }

  // ================= FIRESTORE MAP =================
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'data': data,
      'imageUrl': imageUrl,
      'position': {
        'dx': position.dx,
        'dy': position.dy,
      },
      'scale': scale,
      'rotation': rotation,
      'color': color.value,
      'locked': locked,
      'width': width,
      'height': height,

      /// Border
      'borderColor': borderColor?.value,
      'borderWidth': borderWidth,
      'borderRadius': borderRadius,
    };
  }

  // ================= FROM MAP =================
  factory QrItem.fromMap(Map<String, dynamic> map) {
    return QrItem(
      id: map['id'],
      data: map['data'],
      imageUrl: map['imageUrl'],

      position: map['position'] != null
          ? Offset(
        (map['position']['dx'] as num).toDouble(),
        (map['position']['dy'] as num).toDouble(),
      )
          : const Offset(100, 100),

      scale: (map['scale'] as num?)?.toDouble() ?? 1.0,
      rotation: (map['rotation'] as num?)?.toDouble() ?? 0,
      color: map['color'] != null ? Color(map['color']) : Colors.black,
      locked: map['locked'] ?? false,

      width: (map['width'] as num?)?.toDouble() ?? 140,
      height: (map['height'] as num?)?.toDouble() ?? 140,

      /// Border
      borderColor:
      map['borderColor'] != null ? Color(map['borderColor']) : Colors.transparent,
      borderWidth: (map['borderWidth'] as num?)?.toDouble() ?? 0,
      borderRadius: (map['borderRadius'] as num?)?.toDouble() ?? 0,
    );
  }

  // ================= JSON =================
  Map<String, dynamic> toJson() => toMap();

  factory QrItem.fromJson(Map<String, dynamic> json) => QrItem.fromMap(json);
}