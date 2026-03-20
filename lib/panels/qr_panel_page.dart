import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:http/http.dart' as http;

import '../models/qr_item.dart';

class QrPanelPage extends StatefulWidget {
  final ValueNotifier<List<QrItem>> qrs;
  final VoidCallback? onHide;

  const QrPanelPage({
    super.key,
    required this.qrs,
    this.onHide,
  });

  @override
  State<QrPanelPage> createState() => _QrPanelPageState();
}

class _QrPanelPageState extends State<QrPanelPage> {
  final TextEditingController _controller = TextEditingController();
  bool _loading = false;

  static const String _imgbbKey = "333a3b74bae238f78922ba5bc75e021cr";

  bool get _isValid => _controller.text.trim().isNotEmpty;

  // ============================================================
  // ADD QR
  // ============================================================
  Future<void> _addQr() async {
    if (!_isValid || _loading) return;

    setState(() => _loading = true);

    final data = _controller.text.trim();

    // 1️⃣ Create QR item immediately
    final newItem = QrItem(
      id: const Uuid().v4(),
      data: data,
      imageUrl: "", // empty initially
      position: const Offset(150, 150),
      scale: 1.0,
      rotation: 0,
      color: Colors.black,
      locked: false,
    );

    // 2️⃣ Add to canvas instantly
    widget.qrs.value = [...widget.qrs.value, newItem];
    widget.qrs.notifyListeners();
    _controller.clear();

    debugPrint("QR added locally: ${newItem.data}");

    // 3️⃣ Upload to imgbb in background
    _generateQrAndUpload(data).then((url) {
      if (url != null) {
        newItem.imageUrl = url;
        widget.qrs.notifyListeners();
        debugPrint("QR uploaded successfully: $url");
      } else {
        debugPrint("QR upload failed for: $data");
      }
    });

    setState(() => _loading = false);
  }

  // ============================================================
  // QR → PNG → IMGBB
  // ============================================================
  Future<String?> _generateQrAndUpload(String data) async {
    try {
      const double size = 300;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      final painter = QrPainter(
        data: data,
        version: QrVersions.auto,
        gapless: true,
      );

      painter.paint(canvas, const Size(size, size));

      final image =
      await recorder.endRecording().toImage(size.toInt(), size.toInt());

      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) return null;

      final base64Image = base64Encode(byteData.buffer.asUint8List());

      final response = await http.post(
        Uri.parse("https://api.imgbb.com/1/upload?key=$_imgbbKey"),
        body: {"image": base64Image},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json["data"]["url"];
      }
    } catch (e) {
      debugPrint("QR upload error: $e");
    }
    return null;
  }

  // ============================================================
  // UI
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
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
                      _inputSection(),
                      const SizedBox(height: 12),
                      _actionSection(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        if (_loading) _loadingOverlay(),
      ],
    );
  }

  // ================= HEADER =================
  Widget _header() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "QR Code Panel",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (widget.onHide != null)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: widget.onHide,
            ),
        ],
      ),
    );
  }

  // ================= INPUT CARD =================
  Widget _inputSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _innerCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "QR Data",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Enter URL or text to generate QR code",
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            enabled: !_loading,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: "https://www.example.com/",
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  // ================= ACTION =================
  Widget _actionSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _innerCard(),
      child: SizedBox(
        width: double.infinity,
        height: 46,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.qr_code, color: Colors.white),
          label: const Text(
            "Add QR Code",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
          ),
          onPressed: _isValid && !_loading ? _addQr : null,
        ),
      ),
    );
  }

  // ================= LOADING =================
  Widget _loadingOverlay() {
    return Container(
      color: Colors.black45,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircularProgressIndicator(strokeWidth: 4),
            SizedBox(height: 14),
            Text(
              "Generating QR Code...",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= DECORATION =================
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
