import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/device_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  double? _phOptimal;
  double? _turbidityOptimal;
  double? _temperatureOptimal;

  @override
  Widget build(BuildContext context) {
    final deviceProvider = Provider.of<DeviceProvider>(context);
    final config = deviceProvider.deviceConfig;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: config == null
          ? const Center(child: Text('No configuration loaded'))
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      initialValue: config.thresholds?['ph']?['optimal']?.toString() ?? '',
                      decoration: const InputDecoration(labelText: 'pH Optimal'),
                      keyboardType: TextInputType.number,
                      onSaved: (v) => _phOptimal = double.tryParse(v ?? ''),
                    ),
                    TextFormField(
                      initialValue: config.thresholds?['turbidity']?['optimal']?.toString() ?? '',
                      decoration: const InputDecoration(labelText: 'Turbidity Optimal'),
                      keyboardType: TextInputType.number,
                      onSaved: (v) => _turbidityOptimal = double.tryParse(v ?? ''),
                    ),
                    TextFormField(
                      initialValue: config.thresholds?['temperature']?['optimal']?.toString() ?? '',
                      decoration: const InputDecoration(labelText: 'Temperature Optimal'),
                      keyboardType: TextInputType.number,
                      onSaved: (v) => _temperatureOptimal = double.tryParse(v ?? ''),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () async {
                        _formKey.currentState?.save();
                        final newConfig = config;
                        newConfig.thresholds?['ph']?['optimal'] = _phOptimal;
                        newConfig.thresholds?['turbidity']?['optimal'] = _turbidityOptimal;
                        newConfig.thresholds?['temperature']?['optimal'] = _temperatureOptimal;
                        final success = await deviceProvider.updateDeviceConfig(
                          deviceProvider.selectedDevice!.deviceId,
                          newConfig,
                        );
                        if (success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Configuration updated!')),
                          );
                        }
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
