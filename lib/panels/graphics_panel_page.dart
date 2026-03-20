import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/graphic_item.dart';

class GraphicsPanelPage extends StatefulWidget {
  final ValueNotifier<List<GraphicItem>> graphics;
  final VoidCallback? onHide;

  const GraphicsPanelPage({
    super.key,
    required this.graphics,
    this.onHide,
  });

  @override
  State<GraphicsPanelPage> createState() => _GraphicsPanelPageState();
}

class _GraphicsPanelPageState extends State<GraphicsPanelPage> {
  final _uuid = const Uuid();
  final TextEditingController _searchCtrl = TextEditingController();

  // ================= COLORS =================
  final List<Color> colors = [
    Colors.black,
    Colors.white,
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.brown,
  ];

  // ================= SHAPES =================
  final List<Map<String, dynamic>> shapes = [
    {"icon": Icons.crop_square, "type": GraphicType.rectangle},
    {"icon": Icons.circle, "type": GraphicType.circle},
    {"icon": Icons.star, "type": GraphicType.star},
    {"icon": Icons.hexagon, "type": GraphicType.polygon},
  ];

  // ================= LINES =================
  final List<Map<String, dynamic>> lines = [
    {"icon": Icons.horizontal_rule, "type": GraphicType.line},
    {"icon": Icons.remove, "type": GraphicType.thickLine},
    {"icon": Icons.more_horiz, "type": GraphicType.dashedLine},
    {"icon": Icons.arrow_right_alt, "type": GraphicType.arrowLine},
    {"icon": Icons.drag_handle, "type": GraphicType.doubleLine},
  ];

  // ================= ICONS =================
  final List<IconData> icons = [
    Icons.favorite,
    Icons.star,
    Icons.check_circle,
    Icons.location_on,
    Icons.phone,
    Icons.email,
    Icons.shopping_cart,
    Icons.home,
    Icons.person,
  ];

  // ================= IMAGES =================
  final List<String> images = List.generate(
    12,
        (i) => "https://picsum.photos/200/200?random=$i",
  );

  // ================= ADD GRAPHIC =================
  void _addGraphic({
    required GraphicType type,
    IconData? icon,
    String? imageUrl,
    Color color = Colors.black,
  }) {
    widget.graphics.value = [
      ...widget.graphics.value,
      GraphicItem(
        id: _uuid.v4(),
        type: type,
        icon: icon,
        imageUrl: imageUrl,
        position: const Offset(150, 150),
        color: color,
      ),
    ];
    widget.graphics.notifyListeners();
  }

  // ================= ICON COLOR PICKER =================
  void _showIconColorPicker(IconData icon) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: colors.map((color) {
            return GestureDetector(
              onTap: () {
                Navigator.pop(context);
                _addGraphic(
                  type: GraphicType.icon,
                  icon: icon,
                  color: color,
                );
              },
              child: CircleAvatar(backgroundColor: color, radius: 22),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      margin: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _header(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: "Search graphics",
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _section("Shapes"),
                  _grid(shapes.map((s) {
                    return _tile(
                      Icon(s["icon"], size: 28),
                          () => _addGraphic(type: s["type"]),
                    );
                  }).toList()),

                  _section("Lines"),
                  _grid(lines.map((l) {
                    return _tile(
                      Icon(l["icon"], size: 28),
                          () => _addGraphic(type: l["type"]),
                    );
                  }).toList()),

                  _section("Images"),
                  _imageGrid(),

                  _section("Icons"),
                  _grid(icons.map((i) {
                    return _tile(
                      Icon(i, size: 26),
                          () => _addGraphic(
                        type: GraphicType.icon,
                        icon: i,
                        color: Colors.black,
                      ),
                    );
                  }).toList()),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= UI HELPERS =================
  Widget _header() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Text(
            "Graphics",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          if (widget.onHide != null)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: widget.onHide,
            ),
        ],
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    );
  }

  Widget _grid(List<Widget> children) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: children,
    );
  }

  Widget _tile(Widget child, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(child: child),
      ),
    );
  }

  Widget _imageGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: images.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemBuilder: (_, i) {
        final url = images[i];
        return GestureDetector(
          onTap: () =>
              _addGraphic(type: GraphicType.image, imageUrl: url),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(url, fit: BoxFit.cover),
          ),
        );
      },
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: const [
      BoxShadow(color: Colors.black12, blurRadius: 10),
    ],
  );
}
