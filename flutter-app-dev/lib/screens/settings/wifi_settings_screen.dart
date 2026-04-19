import 'package:flutter/material.dart';

class WiFiSettingsScreen extends StatelessWidget {
  const WiFiSettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WiFi Settings')),
      body: const Center(child: Text('WiFi settings placeholder')),
    );
  }
}
