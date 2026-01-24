import 'package:flutter/material.dart';

class SensorCalibrationScreen extends StatelessWidget {
  const SensorCalibrationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sensor Calibration')),
      body: const Center(child: Text('Sensor calibration placeholder')),
    );
  }
}
