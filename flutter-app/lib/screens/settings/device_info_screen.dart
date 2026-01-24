import 'package:flutter/material.dart';

class DeviceInfoScreen extends StatelessWidget {
  const DeviceInfoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Device Information')),
      body: const Center(child: Text('Device info placeholder')),
    );
  }
}
