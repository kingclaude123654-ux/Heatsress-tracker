import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'dart:io';
import 'package:intl/intl.dart';

void main() {
  runApp(const MedGulfApp());
}

class MedGulfApp extends StatelessWidget {
  const MedGulfApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Heat Stress Monitor',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    const ReportPage(),
    const DashboardPlaceholder(),
    const HistoryPlaceholder(),
  ];

  void _onItemTapped(int index) {
    setState(() { _selectedIndex = index; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Heat Stress Monitor"),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFF1A237E),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.note_add), label: 'Report'),
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
        ],
      ),
    );
  }
}

// --- PAGE 1: REPORT ---
class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  String _location = "Corridor F area 1";
  File? _image;
  bool _isProcessing = false;
  String _resultText = "";

  // Variables for extracted data
  double _temp = 0.0;
  double _humidity = 0.0;
  double _heatIdx = 0.0;

  // 1. FUNCTION TO PICK AND ANALYZE IMAGE
  Future<void> _pickAndAnalyzeImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? imageFile = await picker.pickImage(source: source);

    if (imageFile == null) return;

    setState(() {
      _image = File(imageFile.path);
      _isProcessing = true;
      _resultText = "Analyzing image... This may take a moment.";
    });

    // 2. LOCAL TEXT RECOGNITION (ML KIT)
    final inputImage = InputImage.fromFilePath(imageFile.path);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    
    try {
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      String fullText = recognizedText.text;
      
      // 3. EXTRACT NUMBERS FROM TEXT
      // This uses Regex to find all numbers (including decimals)
      RegExp regExp = RegExp(r'(\d+\.?\d*)');
      Iterable<RegExpMatch> matches = regExp.allMatches(fullText);
      
      List<double> numbers = matches.map((m) => double.tryParse(m.group(0)!) ?? 0.0).toList();
      
      // 4. LOGIC TO ASSIGN NUMBERS TO DATA
      // Since we don't know the exact format of the Kestrel meter,
      // we assume the first 3 numbers found are: Temperature, Humidity, Heat Index.
      if (numbers.length >= 3) {
        _temp = numbers[0];
        _humidity = numbers[1];
        _heatIdx = numbers[2];
      } else {
        _resultText = "Error: Could not detect enough numbers in the image. Please ensure the meter screen is clear.";
        return;
      }

      // 5. GENERATE THE REPORT USING YOUR CHART
      _generateReport();

    } catch (e) {
      setState(() {
        _resultText = "Error analyzing image: $e";
      });
    } finally {
      await textRecognizer.close();
      setState(() {
        _isProcessing = false;
      });
    }
  }

  // 6. YOUR EXACT LOGIC AND CHART
  void _generateReport() {
    String flagColor = "";
    String risk = "";
    String workRest = "";
    String water = "";

    if (_heatIdx >= 54) {
      flagColor = "🔴 Red";
      risk = "Stop Work";
      workRest = "---";
      water = "Stop work";
    } else if (_heatIdx >= 50) {
      flagColor = "🔴 Red";
      risk = "Extreme Danger";
      workRest = "20:10";
      water = "1 cup every 10 min";
    } else if (_heatIdx >= 39) {
      flagColor = "🟠 Orange";
      risk = "Danger";
      workRest = "30:10";
      water = "1 cup every 15 min";
    } else if (_heatIdx >= 32) {
      flagColor = "🟡 Yellow";
      risk = "Extreme Caution";
      workRest = "40:10";
      water = "1 cup every 20 min";
    } else if (_heatIdx >= 27) {
      flagColor = "🟢 Green";
      risk = "Caution";
      workRest = "50:10";
      water = "1 cup every 20 min";
    } else {
      flagColor = "🟢 Green";
      risk = "Safe";
      workRest = "Normal";
      water = "Standard hydration";
    }

    // Qatar Time & Date formatting
    DateTime now = DateTime.now().toUtc().add(const Duration(hours: 3)); // UTC+3 for Qatar
    String date = DateFormat('dd/MM/yyyy').format(now);
    String time = DateFormat('hh:mm a').format(now);

    _resultText = """
*Company* : MEDGULF
*Location* : $_location
*Time* : $time
*Date* : $date
*Temp* : ${_temp.toStringAsFixed(1)}°C
*Humidity* : ${_humidity.toStringAsFixed(1)}%
*Heat Index* : ${_heatIdx.toStringAsFixed(1)}°C
*Flag Colour* : $flagColor
*Risk* : $risk
*Work/Rest* : $workRest
*Water Consumption* : $water
""";
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("📷 Meter Image", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey, style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                if (_image != null) ...[
                  Image.file(_image!, height: 150),
                  const SizedBox(height: 10),
                  if(_isProcessing) const Center(child: CircularProgressIndicator())
                ] else ...[
                  const Icon(Icons.image, size: 50, color: Colors.grey),
                  const SizedBox(height: 10),
                  const Text("Take a photo or upload an image of the temperature/humidity meter"),
                ],
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _pickAndAnalyzeImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text("Take Photo"),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E)),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: () => _pickAndAnalyzeImage(ImageSource.gallery),
                      icon: const Icon(Icons.upload_file),
                      label: const Text("Upload File"),
                    ),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 20),

          const Text("📍 Location", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _location,
                  items: ["Corridor F area 1", "Area A", "Main Site"].map((String val) {
                    return DropdownMenuItem(value: val, child: Text(val));
                  }).toList(),
                  onChanged: (val) => setState(() => _location = val!),
                  decoration: const InputDecoration(border: OutlineInputBorder(), prefixIcon: Icon(Icons.place)),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filled(onPressed: () {}, icon: const Icon(Icons.add))
            ],
          ),
          const SizedBox(height: 20),

          // Generate Button (Will just re-run the report based on existing numbers)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if(_image != null) _generateReport();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo.shade200,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.flash_on, color: Colors.white),
                  SizedBox(width: 8),
                  Text("Generate Report", style: TextStyle(color: Colors.white, fontSize: 16)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          if (_resultText.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100, 
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300)
            ),
            child: Text(_resultText, style: const TextStyle(fontFamily: 'monospace', fontSize: 14)),
          )
        ],
      ),
    );
  }
}

class DashboardPlaceholder extends StatelessWidget {
  const DashboardPlaceholder({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Dashboard Graphs go here"));
  }
}

class HistoryPlaceholder extends StatelessWidget {
  const HistoryPlaceholder({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("History Logs go here"));
  }
}