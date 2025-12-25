import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

void main() => runApp(const ARMissesUltimateApp());

class ARMissesUltimateApp extends StatelessWidget {
  const ARMissesUltimateApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.dark, useMaterial3: true),
      home: const PerformanceMasterScreen(),
    );
  }
}

class PerformanceMasterScreen extends StatefulWidget {
  const PerformanceMasterScreen({super.key});
  @override
  State<PerformanceMasterScreen> createState() => _PerformanceMasterScreenState();
}

class _PerformanceMasterScreenState extends State<PerformanceMasterScreen> {
  // --- ระบบแปลภาษา ---
  String _lang = 'TH';
  final Map<String, Map<String, String>> _text = {
    'TH': {'mon': 'ตรวจสอบสมรรถนะ 10Hz', 'weight': 'นน.รถ+คนขับ (KG)', 'start': 'เริ่ม', 'reset': 'รีเซ็ต', 'hp': 'แรงม้า', 'tq': 'แรงบิด (Nm)'},
    'EN': {'mon': '10Hz PERFORMANCE MONITOR', 'weight': 'WEIGHT + DRIVER (KG)', 'start': 'START', 'reset': 'RESET', 'hp': 'HORSEPOWER', 'tq': 'TORQUE (Nm)'}
  };

  // --- ตัวแปรหลัก ---
  double _speed = 0.0, _maxSpeed = 0.0, _weight = 1500.0;
  double _hp = 0.0, _torque = 0.0;
  double _t60ft = 0.0, _t200m = 0.0, _t402m = 0.0, _t1000m = 0.0;

  @override
  void initState() {
    super.initState();
    _startUltra10HzGPS();
  }

  // --- ระบบ GPS 10Hz เพื่อความแม่นยำ 1 ล้านเปอร์เซ็นต์ ---
  void _startUltra10HzGPS() async {
    await Geolocator.requestPermission();
    const settings = AndroidSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0,
      intervalDuration: Duration(milliseconds: 100), // ดึงข้อมูล 10 ครั้ง/วินาที
    );

    Geolocator.getPositionStream(locationSettings: settings).listen((pos) {
      if (!mounted) return;
      double sMs = pos.speed;
      double sKph = sMs * 3.6;
      setState(() {
        _speed = sKph < 0.3 ? 0.0 : sKph;
        if (_speed > _maxSpeed) _maxSpeed = _speed;
        if (_speed > 2.0) {
          _hp = (_weight * (sMs / 2)) * sMs / 745.7; // สูตรแรงม้า
          _torque = (_hp * 9548.8) / (sKph * 10 + 1); // สูตรแรงบิด
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text("ARMisses", style: GoogleFonts.bebasNeue(fontSize: 45, color: Colors.red, fontWeight: FontWeight.w900, letterSpacing: 4)),
        actions: [
          TextButton(
            onPressed: () => setState(() => _lang = _lang == 'TH' ? 'EN' : 'TH'),
            child: Text(_lang == 'TH' ? "EN 🇺🇸" : "TH 🇹🇭", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: OrientationBuilder(
        builder: (context, orientation) {
          return orientation == Orientation.portrait ? _buildPortrait() : _buildLandscape();
        },
      ),
    );
  }

  // ฟังก์ชันที่ 1: แนวตั้ง (หน้าปัด 350)
  Widget _buildPortrait() {
    return Column(
      children: [
        Text(_text[_lang]!['mon']!, style: const TextStyle(color: Colors.white24, fontSize: 10)),
        const Spacer(),
        _gauge(),
        const Spacer(),
        _weightField(),
        const SizedBox(height: 50),
      ],
    );
  }

  // ฟังก์ชันที่ 2 & 3: แนวนอน (Drag 3 แถว + แรงม้า)
  Widget _buildLandscape() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Column(
            children: [
              _row("200 M", _t200m), _row("402 M", _t402m), _row("1000 M", _t1000m),
              _controls(),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Container(
            color: Colors.red.withOpacity(0.05),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _val(_text[_lang]!['hp']!, _hp.toStringAsFixed(0), "HP"),
                const Divider(color: Colors.red, indent: 30, endIndent: 30),
                _val(_text[_lang]!['tq']!, _torque.toStringAsFixed(1), "NM"),
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget _gauge() {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(width: 310, height: 310, child: CircularProgressIndicator(value: _speed / 350, strokeWidth: 20, color: Colors.red, backgroundColor: Colors.white10)),
        Column(children: [
          Text(_speed.toStringAsFixed(0), style: GoogleFonts.orbitron(fontSize: 110, fontWeight: FontWeight.w900)),
          const Text("KM/H", style: TextStyle(color: Colors.red, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 5)),
        ]),
      ],
    );
  }

  Widget _row(String d, double t) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 10),
        decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text(d, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w900, fontSize: 26)),
            Text("60ft: ${_t60ft}s", style: const TextStyle(fontSize: 12, color: Colors.white38)),
            Text("${t}s", style: GoogleFonts.shareTechMono(fontSize: 32, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _val(String l, String v, String u) {
    return Column(children: [
      Text(l, style: const TextStyle(fontSize: 12, color: Colors.white38)),
      Text(v, style: const TextStyle(fontSize: 60, fontWeight: FontWeight.w900, color: Colors.red)),
      Text(u, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
    ]);
  }

  Widget _controls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: Colors.green), child: Text(_text[_lang]!['start']!)),
        ElevatedButton(onPressed: () => setState(() { _hp = 0; _torque = 0; }), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: Text(_text[_lang]!['reset']!)),
      ],
    );
  }

  Widget _weightField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 60),
      child: TextField(
        textAlign: TextAlign.center,
        decoration: InputDecoration(labelText: _text[_lang]!['weight'], labelStyle: const TextStyle(color: Colors.red)),
        keyboardType: TextInputType.number,
        onChanged: (v) => _weight = double.tryParse(v) ?? 1500,
      ),
    );
  }
}