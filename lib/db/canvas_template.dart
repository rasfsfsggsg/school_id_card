class CanvasTemplate {
  final String id;
  final double widthCm;
  final double heightCm;
  final String orientation;
  final Map<String, dynamic> front;
  final Map<String, dynamic> back;
  final DateTime createdAt;

  CanvasTemplate({
    required this.id,
    required this.widthCm,
    required this.heightCm,
    required this.orientation,
    required this.front,
    required this.back,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    "widthCm": widthCm,
    "heightCm": heightCm,
    "orientation": orientation,
    "front": front,
    "back": back,
    "createdAt": createdAt.toIso8601String(),
  };

  factory CanvasTemplate.fromJson(String id, Map<String, dynamic> json) {
    return CanvasTemplate(
      id: id,
      widthCm: json["widthCm"],
      heightCm: json["heightCm"],
      orientation: json["orientation"],
      front: Map<String, dynamic>.from(json["front"]),
      back: Map<String, dynamic>.from(json["back"]),
      createdAt: DateTime.parse(json["createdAt"]),
    );
  }
}
