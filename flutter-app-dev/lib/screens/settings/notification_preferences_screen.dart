import 'package:flutter/material.dart';

class NotificationPreferencesScreen extends StatelessWidget {
  const NotificationPreferencesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notification Preferences')),
      body: const Center(child: Text('Notification preferences placeholder')),
    );
  }
}
