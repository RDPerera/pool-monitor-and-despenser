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
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.white.withOpacity(0.9),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: config == null
            ? const Center(child: Text('No configuration loaded'))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pool Parameters',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Adjust the optimal values for your pool monitoring.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            initialValue: config.thresholds?['ph']?['optimal']?.toString() ?? '',
                            decoration: InputDecoration(
                              labelText: 'pH Optimal',
                              prefixIcon: const Icon(Icons.science),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            onSaved: (v) => _phOptimal = double.tryParse(v ?? ''),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            initialValue: config.thresholds?['turbidity']?['optimal']?.toString() ?? '',
                            decoration: InputDecoration(
                              labelText: 'Turbidity Optimal',
                              prefixIcon: const Icon(Icons.opacity),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            onSaved: (v) => _turbidityOptimal = double.tryParse(v ?? ''),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            initialValue: config.thresholds?['temperature']?['optimal']?.toString() ?? '',
                            decoration: InputDecoration(
                              labelText: 'Temperature Optimal (°C)',
                              prefixIcon: const Icon(Icons.thermostat),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            onSaved: (v) => _temperatureOptimal = double.tryParse(v ?? ''),
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
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
                                    SnackBar(
                                      content: const Text('Configuration updated!'),
                                      backgroundColor: Colors.green,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: const Text('Save Settings'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
