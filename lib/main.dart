import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

void main() => runApp(MaterialApp(home: Dashboard(), theme: ThemeData.dark()));

class Dashboard extends StatefulWidget {
  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  List<String> logs = [];

  void _addNewReport() async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => EntryPage()));
    if (result != null) setState(() => logs.insert(0, result));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("HSE Heat Stress Dashboard")),
      body: ListView.builder(itemCount: logs.length, itemBuilder: (c, i) => Card(child: ListTile(title: Text(logs[i].split('\n')[1]), subtitle: Text(logs[i])))),
      floatingActionButton: FloatingActionButton(onPressed: _addNewReport, child: Icon(Icons.add)),
    );
  }
}

class EntryPage extends StatefulWidget {
  @override
  _EntryPageState createState() => _EntryPageState();
}

class _EntryPageState extends State<EntryPage> {
  File? _image;
  final _loc = TextEditingController(text: "Corridor F area 1");
  final _temp = TextEditingController();
  final _hum = TextEditingController();

  void _calculate() {
    double t = double.tryParse(_temp.text) ?? 0;
    double h = double.tryParse(_hum.text) ?? 0;
    double hi = t + (0.55 * (1 - (h / 100)) * (t - 14.5));
    String f, r, wr, w;
    if (hi >= 54) { f="Red 🔴"; r="Stop work"; wr="Stop work"; w="Stop work"; }
    else if (hi >= 50) { f="Red 🔴"; r="Extreme Danger"; wr="20:10"; w="1 cup/10 min"; }
    else if (hi >= 39) { f="Orange 🟠"; r="Danger"; wr="30:10"; w="1 cup/15 min"; }
    else if (hi >= 32) { f="Yellow 🟡"; r="Extreme Caution"; wr="40:10"; w="1 cup/20 min"; }
    else { f="Green 🟢"; r="Caution"; wr="50:10"; w="1 cup/20 min"; }

    String report = "Company : MEDGULF\nLocation : ${_loc.text}\nTime : ${DateFormat('h:mm a').format(DateTime.now())}\nDate : ${DateFormat('dd/MM/yyyy').format(DateTime.now())}\nTemp : ${t.toStringAsFixed(1)}°C\nHumidity : ${h.toStringAsFixed(0)}%\nHeat Index : ${hi.toStringAsFixed(1)}°C\nFlag Colour : $f\nRisk : $r\nWork/Rest : $wr\nWater Consumption : $w";
    Navigator.pop(context, report);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text("New Report")), body: Padding(padding: EdgeInsets.all(16), child: ListView(children: [
      GestureDetector(onTap: () async { final p = await ImagePicker().pickImage(source: ImageSource.camera); if(p!=null) setState(()=>_image=File(p.path)); }, child: Container(height: 150, color: Colors.grey[800], child: _image == null ? Icon(Icons.camera_alt, size: 50) : Image.file(_image!, fit: BoxFit.cover))),
      TextField(controller: _loc, decoration: InputDecoration(labelText: "Location")),
      TextField(controller: _temp, decoration: InputDecoration(labelText: "Temp (°C)"), keyboardType: TextInputType.number),
      TextField(controller: _hum, decoration: InputDecoration(labelText: "Humidity (%)"), keyboardType: TextInputType.number),
      ElevatedButton(onPressed: _calculate, child: Text("Save & Generate Report"))
    ])));
  }
}
