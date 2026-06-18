import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:intl/intl.dart';

void main() => runApp(MaterialApp(home: HeatStressApp(), theme: ThemeData(primarySwatch: Colors.indigo)));

class HeatStressApp extends StatefulWidget {
  @override
  _HeatStressAppState createState() => _HeatStressAppState();
}

class _HeatStressAppState extends State<HeatStressApp> {
  int _currentIndex = 0;
  String _temp = "0", _hum = "0", _report = "No data yet";
  final TextRecognizer _textRecognizer = TextRecognizer();

  void _calculateLogic(double t, double h) {
    double hi = t + (0.55 * (1 - (h / 100)) * (t - 14.5));
    String f, r, wr, w;
    if (hi >= 54) { f = "Red 🔴"; r = "Stop work"; wr = "Stop work"; w = "Stop work"; }
    else if (hi >= 50) { f = "Red 🔴"; r = "Extreme Danger"; wr = "20:10"; w = "1 Cup every 10 min"; }
    else if (hi >= 39) { f = "Orange 🟠"; r = "Danger"; wr = "30:10"; w = "1 Cup every 15 min"; }
    else if (hi >= 32) { f = "Yellow 🟡"; r = "Extreme Caution"; wr = "40:10"; w = "1 Cup every 20 min"; }
    else { f = "Green 🟢"; r = "Caution"; wr = "50:10"; w = "1 Cup every 20 min"; }

    setState(() {
      _report = "Company : MEDGULF\nLocation : Corridor F area 1\nTime : ${DateFormat('h:mm a').format(DateTime.now())}\nDate : ${DateFormat('dd/MM/yyyy').format(DateTime.now())}\nTemp : ${t.toStringAsFixed(1)}°C\nHumidity : ${h.toStringAsFixed(0)}%\nHeat Index : ${hi.toStringAsFixed(1)}°C\nFlag Colour : $f\nRisk : $r\nWork/Rest : $wr\nWater Consumption : $w";
    });
  }

  Future<void> _extractData(ImageSource source) async {
    final XFile? picked = await ImagePicker().pickImage(source: source);
    if (picked == null) return;
    final inputImage = InputImage.fromFilePath(picked.path);
    final recognizedText = await _textRecognizer.processImage(inputImage);
    // Logic: In a live app, you would parse recognizedText.text to find numbers. 
    // For now, we simulate extraction based on image upload.
    setState(() { _temp = "35.5"; _hum = "45"; });
    _calculateLogic(35.5, 45);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Color(0xFF1A365D), title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("Heat Stress Monitor", style: TextStyle(fontSize: 16)), Text("🛡 MEDGULF HSE Dashboard", style: TextStyle(fontSize: 10))
      ])),
      body: _currentIndex == 0 ? Padding(padding: EdgeInsets.all(16), child: ListView(children: [
        Card(child: Padding(padding: EdgeInsets.all(20), child: Column(children: [
          Text("📷 Meter Image", style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          Container(height: 120, decoration: BoxDecoration(border: Border.all(color: Colors.grey, style: BorderStyle.dash)), child: Center(child: Icon(Icons.photo_library, size: 50))),
          Row(children: [
            Expanded(child: TextButton.icon(onPressed: () => _extractData(ImageSource.camera), icon: Icon(Icons.camera_alt), label: Text("Camera"))),
            Expanded(child: TextButton.icon(onPressed: () => _extractData(ImageSource.gallery), icon: Icon(Icons.upload), label: Text("Upload"))),
          ]),
          Divider(),
          SelectableText(_report, style: TextStyle(fontFamily: 'monospace')),
        ])))
      ])) : Center(child: Text("Dashboard/History")),
      bottomNavigationBar: BottomNavigationBar(currentIndex: _currentIndex, onTap: (i) => setState(() => _currentIndex = i), items: [
        BottomNavigationBarItem(icon: Icon(Icons.description), label: 'Report'),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Dashboard'),
        BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'History'),
      ]),
    );
  }
}
