import 'package:flutter/material.dart';

class UnitConverterPopup extends StatefulWidget {
  final double pxPerCm; // pixels per cm
  const UnitConverterPopup({super.key, required this.pxPerCm});

  @override
  State<UnitConverterPopup> createState() => _UnitConverterPopupState();
}

class _UnitConverterPopupState extends State<UnitConverterPopup> {
  final TextEditingController _inputController = TextEditingController(text: "0");

  String inputUnit = "cm";
  String outputUnit = "px";

  double convertedValue = 0;

  final List<String> units = ["cm", "mm", "inch", "px"];

  @override
  void initState() {
    super.initState();
    _updateConversion();
  }

  void _updateConversion() {
    double input = double.tryParse(_inputController.text) ?? 0;
    double valueInCm = 0;

    // Convert input to cm first
    switch (inputUnit) {
      case "cm":
        valueInCm = input;
        break;
      case "mm":
        valueInCm = input / 10;
        break;
      case "inch":
        valueInCm = input * 2.54;
        break;
      case "px":
        valueInCm = input / widget.pxPerCm;
        break;
    }

    // Convert cm to output unit
    double output = 0;
    switch (outputUnit) {
      case "cm":
        output = valueInCm;
        break;
      case "mm":
        output = valueInCm * 10;
        break;
      case "inch":
        output = valueInCm / 2.54;
        break;
      case "px":
        output = valueInCm * widget.pxPerCm;
        break;
    }

    setState(() {
      convertedValue = output;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Row: Title + Close button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Unit Converter",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            const SizedBox(height: 12),

            // Input Row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: "Input",
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (_) => _updateConversion(),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: inputUnit,
                  items: units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() {
                        inputUnit = v;
                        _updateConversion();
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Output Row
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      convertedValue.toStringAsFixed(2),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: outputUnit,
                  items: units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() {
                        outputUnit = v;
                        _updateConversion();
                      });
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Bottom replace icon (just UI)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.swap_horiz, color: Colors.blueAccent, size: 32),
                  tooltip: "Swap Units",
                  onPressed: () {
                    setState(() {
                      String temp = inputUnit;
                      inputUnit = outputUnit;
                      outputUnit = temp;

                      double tempValue = convertedValue;
                      _inputController.text = tempValue.toStringAsFixed(2);
                      _updateConversion();
                    });
                  },
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
