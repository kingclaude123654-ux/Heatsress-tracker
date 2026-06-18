import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

void main() => runApp(MaterialApp(home: HeatStressTracker(), debugShowCheckedModeBanner: false));

class HeatStressTracker extends StatefulWidget {
  @override
  _HeatStressTrackerState createState() => _HeatStressTrackerState();
}

class _HeatStressTrackerState extends State<HeatStressTracker> {
  final TextEditingController _locController = TextEditingController(text: "Corridor F area 1");
  final TextEditingController _tempController = TextEditingController();
  final TextEditingController _humController = TextEditingController();
  String _result = "Enter data to see report";
  final ImagePicker _picker = ImagePicker();

  void _calculate() {
    double temp = double.tryParse(_tempController.text) ?? 0;
    double hum = double.tryParse(_humController.text) ?? 0;
    double heatIndex = temp + (0.55 * (1 - (hum / 100)) * (temp - 14.5));

    String flag, risk, workRest, water;
    if (heatIndex >= 54) {
      flag = "Red 🔴"; risk = "Stop work"; workRest = "Stop work"; water = "Stop work";
    } else if (heatIndex >= 50) {
      flag = "Red 🔴"; risk = "Extreme Danger"; workRest = "20:10"; water = "1 cup every 10 min";
    } else if (heatIndex >= 39) {
      flag = "Orange 🟠"; risk = "Danger"; workRest = "30:10"; water = "1 cup every 15 min";
    } else if (heatIndex >= 32) {
      flag = "Yellow 🟡"; risk = "Extreme Caution"; workRest = "40:10"; water = "1 cup every 20 min";
    } else if (heatIndex >= 27) {
      flag = "Green 🟢"; risk = "Caution"; workRest = "50:10"; water = "1 cup every 20 min";
    } else {
      flag = "Green 🟢"; risk = "Low Risk"; workRest = "Normal"; water = "Regular hydration";
    }

    setState(() {
      _result = "Company : MEDGULF\nLocation : ${_locController.text}\nTime : ${DateFormat('h:mm a').format(DateTime.now())}\nDate : ${DateFormat('dd/MM/yyyy').format(DateTime.now())}\nTemp : ${temp.toStringAsFixed(1)}°C\nHumidity : ${hum.toStringAsFixed(0)}%\nHeat Index : ${heatIndex.toStringAsFixed(1)}°C\nFlag Colour : $flag\nRisk : $risk\nWork/Rest : $workRest\nWater Consumption : $water";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Heat Stress Tracker")),
      body: SingleChildScrollView(padding: EdgeInsets.all(16.0), child: Column(children: [
        TextField(controller: _locController, decoration: InputDecoration(labelText: "Location")),
        TextField(controller: _tempController, decoration: InputDecoration(labelText: "Temp (°C)"), keyboardType: TextInputType.number),
        TextField(controller: _humController, decoration: InputDecoration(labelText: "Humidity (%)"), keyboardType: TextInputType.number),
        SizedBox(height: 20),
        ElevatedButton(onPressed: () async { await _picker.pickImage(source: ImageSource.camera); _calculate(); }, child: Text("Capture & Calculate")),
        SizedBox(height: 20),
        Container(padding: EdgeInsets.all(10), color: Colors.grey[200], child: SelectableText(_result)),
      ])),
    );
  }
}
