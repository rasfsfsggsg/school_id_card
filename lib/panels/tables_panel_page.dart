import 'package:flutter/material.dart';
import '../models/table_item.dart';

class TablesPanelPage extends StatefulWidget {
  final ValueNotifier<List<TableItem>> tables;
  final VoidCallback? onHide;

  const TablesPanelPage({
    super.key,
    required this.tables,
    this.onHide,
  });

  @override
  State<TablesPanelPage> createState() => _TablesPanelPageState();
}

class _TablesPanelPageState extends State<TablesPanelPage> {
  int rows = 2;
  int cols = 2;
  double cellWidth = 80;
  double cellHeight = 40;

  List<List<String>> initialData = [];

  final List<_TablePreset> presets = const [
    _TablePreset(rows: 2, cols: 2, label: "2 × 2"),
    _TablePreset(rows: 3, cols: 3, label: "3 × 3"),
    _TablePreset(rows: 4, cols: 3, label: "4 × 3"),
    _TablePreset(rows: 5, cols: 4, label: "5 × 4"),
    _TablePreset(rows: 6, cols: 6, label: "6 × 6"),
  ];

  // ================= ADD TABLE =================
  void _addTable(int r, int c) {
    if (initialData.length != r ||
        initialData.any((row) => row.length != c)) {
      initialData = List.generate(r, (_) => List.generate(c, (_) => ""));
    }

    widget.tables.value = [
      ...widget.tables.value,
      TableItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        rows: r,
        cols: c,
        position: const Offset(140, 140),
        cellWidth: cellWidth,
        cellHeight: cellHeight,
        data: initialData.map((e) => [...e]).toList(),
      ),
    ];
    widget.tables.notifyListeners();
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      margin: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _header(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _presetSection(),
                  const SizedBox(height: 14),
                  _customSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= HEADER =================
  Widget _header() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Text(
            "Tables",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          if (widget.onHide != null)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: widget.onHide,
            ),
        ],
      ),
    );
  }

  // ================= PRESETS =================
  Widget _presetSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _innerCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Quick layouts",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: presets.map(_presetTile).toList(),
          ),
        ],
      ),
    );
  }

  Widget _presetTile(_TablePreset p) {
    return GestureDetector(
      onTap: () => _addTable(p.rows, p.cols),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.table_chart_outlined,
                size: 26, color: Colors.blue.shade700),
            const SizedBox(height: 6),
            Text(
              p.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= CUSTOM =================
  Widget _customSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _innerCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Custom table",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          _counter("Columns", cols, (v) => setState(() => cols = v)),
          _counter("Rows", rows, (v) => setState(() => rows = v)),
          _doubleCounter(
              "Cell Width", cellWidth, (v) => setState(() => cellWidth = v)),
          _doubleCounter(
              "Cell Height", cellHeight, (v) => setState(() => cellHeight = v)),

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                "Add Table",
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => _addTable(rows, cols),
            ),
          ),
        ],
      ),
    );
  }

  // ================= CONTROLS =================
  Widget _counter(String label, int value, Function(int) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(label),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: value > 1 ? () => onChanged(value - 1) : null,
          ),
          _counterValue(value.toString()),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => onChanged(value + 1),
          ),
        ],
      ),
    );
  }

  Widget _doubleCounter(
      String label, double value, Function(double) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(label),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: () => onChanged((value - 5).clamp(20, 500)),
          ),
          _counterValue(value.toInt().toString()),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => onChanged((value + 5).clamp(20, 500)),
          ),
        ],
      ),
    );
  }

  Widget _counterValue(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.blue.shade900,
        ),
      ),
    );
  }

  // ================= STYLES =================
  BoxDecoration _cardDecoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: const [
      BoxShadow(color: Colors.black12, blurRadius: 10),
    ],
  );

  BoxDecoration _innerCard() => BoxDecoration(
    color: Colors.grey.shade50,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Colors.grey.shade300),
  );
}

// ================= PRESET MODEL =================
class _TablePreset {
  final int rows;
  final int cols;
  final String label;

  const _TablePreset({
    required this.rows,
    required this.cols,
    required this.label,
  });
}
