import 'package:flutter/material.dart';

class LanguageSettingsScreen extends StatelessWidget {
  const LanguageSettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Language')),
      body: const Center(child: Text('Language settings placeholder')),
    );
  }
}
