import 'package:flutter/material.dart';
import '../../widgets/app_logo.dart';

class DispensingScreen extends StatelessWidget {
  const DispensingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dispensing'), leading: const Padding(padding: EdgeInsets.only(left:12), child: AppLogo(size:32))),
      body: const Center(
        child: Text('Dispensing functionality coming soon!'),
      ),
    );
  }
}
