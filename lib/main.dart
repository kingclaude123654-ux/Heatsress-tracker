import 'dart:io';
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await Hive.openBox('reports');

  runApp(const HeatStressApp());
}

class HeatStressApp extends StatelessWidget {
  const HeatStressApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Heat Stress Monitor',
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class Report {
  final String company;
  final String location;
  final String date;
  final String time;
  final double temp;
  final double humidity;
  final double heatIndex;
  final String flag;
  final String risk;
  final String workRest;
  final String water;

  Report({
    required this.company,
    required this.location,
    required this.date,
    required this.time,
    required this.temp,
    required this.humidity,
    required this.heatIndex,
    required this.flag,
    required this.risk,
    required this.workRest,
    required this.water,
  });

  Map<String, dynamic> toMap() {
    return {
      'company': company,
      'location': location,
      'date': date,
      'time': time,
      'temp': temp,
      'humidity': humidity,
      'heatIndex': heatIndex,
      'flag': flag,
      'risk': risk,
      'workRest': workRest,
      'water': water,
    };
  }

  factory Report.fromMap(Map map) {
    return Report(
      company: map['company'],
      location: map['location'],
      date: map['date'],
      time: map['time'],
      temp: map['temp'],
      humidity: map['humidity'],
      heatIndex: map['heatIndex'],
      flag: map['flag'],
      risk: map['risk'],
      workRest: map['workRest'],
      water: map['water'],
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const ReportPage(),
      const DashboardPage(),
      const HistoryPage(),
    ];

    return Scaffold(
      body: pages[tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) {
          setState(() {
            tab = i;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.note_add),
            label: 'Report',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.history),
            label: 'History',
          ),
        ],
      ),
    );
  }
}

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final picker = ImagePicker();

  File? imageFile;

  final locationController =
      TextEditingController(text: 'Corridor F area 1');

  double? temp;
  double? humidity;

  Future<void> pickImage(ImageSource source) async {
    final file = await picker.pickImage(
      source: source,
      imageQuality: 85,
    );

    if (file == null) return;

    imageFile = File(file.path);

    setState(() {});

    await processImage();
  }

  Future<void> processImage() async {
    if (imageFile == null) return;

    final inputImage = InputImage.fromFile(imageFile!);

    final recognizer = TextRecognizer();

    final result = await recognizer.processImage(inputImage);

    final text = result.text;

    final tempRegex = RegExp(r'(\d+(\.\d+)?)\s*°?\s*C');
    final humidityRegex = RegExp(r'(\d+(\.\d+)?)\s*%');

    final tempMatch = tempRegex.firstMatch(text);
    final humidityMatch = humidityRegex.firstMatch(text);

    if (tempMatch != null) {
      temp = double.tryParse(tempMatch.group(1)!);
    }

    if (humidityMatch != null) {
      humidity = double.tryParse(humidityMatch.group(1)!);
    }

    recognizer.close();

    setState(() {});
  }

  double calculateHeatIndex(double t, double h) {
    return t + (0.33 * h / 100 * 6) + 4;
  }

  Map<String, String> riskData(double hi) {
    if (hi >= 54) {
      return {
        'flag': '🔴 Red',
        'risk': 'Extreme Danger',
        'rest': 'Stop all work',
        'water': 'Stop work'
      };
    }

    if (hi >= 50) {
      return {
        'flag': '🟠 Orange',
        'risk': 'Danger',
        'rest': '20:10',
        'water': '1 cup every 10 minutes'
      };
    }

    if (hi >= 39) {
      return {
        'flag': '🟠 Orange',
        'risk': 'Danger',
        'rest': '30:10',
        'water': '1 cup every 15 minutes'
      };
    }

    if (hi >= 32) {
      return {
        'flag': '🟡 Yellow',
        'risk': 'Extreme Caution',
        'rest': '40:10',
        'water': '1 cup every 20 minutes'
      };
    }

    return {
      'flag': '🟢 Green',
      'risk': 'Caution',
      'rest': '50:10',
      'water': '1 cup every 20 minutes'
    };
  }

  void saveReport() {
    if (temp == null || humidity == null) return;

    final now = DateTime.now();

    final heatIndex = calculateHeatIndex(temp!, humidity!);

    final risk = riskData(heatIndex);

    final report = Report(
      company: 'MEDGULF',
      location: locationController.text,
      date: DateFormat('dd/MM/yyyy').format(now),
      time: DateFormat('h:mm a').format(now),
      temp: temp!,
      humidity: humidity!,
      heatIndex: heatIndex,
      flag: risk['flag']!,
      risk: risk['risk']!,
      workRest: risk['rest']!,
      water: risk['water']!,
    );

    Hive.box('reports').add(report.toMap());

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report Saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final heatIndex = (temp != null && humidity != null)
        ? calculateHeatIndex(temp!, humidity!)
        : null;

    final risk = heatIndex != null ? riskData(heatIndex) : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Heat Stress Monitor'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (imageFile != null)
              Image.file(
                imageFile!,
                height: 220,
              ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Take Photo'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.upload),
                    label: const Text('Upload'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            TextField(
              controller: locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            if (heatIndex != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SelectableText(
                    '''
Company : MEDGULF
Location : ${locationController.text}
Time : ${DateFormat('h:mm a').format(DateTime.now())}
Date : ${DateFormat('dd/MM/yyyy').format(DateTime.now())}
Temp : ${temp!.toStringAsFixed(1)}°C
Humidity : ${humidity!.toStringAsFixed(0)}%
Heat Index : ${heatIndex.toStringAsFixed(1)}°C
Flag Colour : ${risk!['flag']}
Risk : ${risk['risk']}
Work/Rest : ${risk['rest']}
Water Consumption : ${risk['water']}
''',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: heatIndex == null ? null : saveReport,
              child: const Text('Generate Report'),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('reports');

    final items = box.values.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: items.isEmpty
          ? const Center(child: Text('No data'))
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  SizedBox(
                    height: 250,
                    child: LineChart(
                      LineChartData(
                        lineBarsData: [
                          LineChartBarData(
                            spots: List.generate(
                              items.length,
                              (i) => FlSpot(
                                i.toDouble(),
                                (items[i]['heatIndex'] as num).toDouble(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final reports = Hive.box('reports').values.toList().reversed.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
      ),
      body: ListView.builder(
        itemCount: reports.length,
        itemBuilder: (context, index) {
          final r = reports[index];

          return ListTile(
            title: Text(r['location']),
            subtitle: Text(
              '${r['date']} | ${r['heatIndex'].toStringAsFixed(1)}°C',
            ),
            trailing: Text(r['flag']),
          );
        },
      ),
    );
  }
}