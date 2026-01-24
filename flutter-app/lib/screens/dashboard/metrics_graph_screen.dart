import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/device_provider.dart';
import '../../widgets/app_logo.dart';

class MetricsGraphScreen extends StatelessWidget {
  const MetricsGraphScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final deviceProvider = Provider.of<DeviceProvider>(context);
    final readings = deviceProvider.readings;
    return Scaffold(
      appBar: AppBar(title: const Text('Metrics Graph'), leading: const Padding(padding: EdgeInsets.only(left:12), child: AppLogo(size:32))),
      body: readings.isEmpty
          ? const Center(child: Text('No data available'))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  const Text('Graph unavailable: chart dependency removed.'),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: readings.length,
                      itemBuilder: (context, index) {
                        final r = readings[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            title: Text('Reading ${r.timestamp.toString()}'),
                            subtitle: Text('pH: ${r.ph.toStringAsFixed(2)}, turbidity: ${r.turbidity.toStringAsFixed(2)}, temp: ${r.temperature.toStringAsFixed(1)} °C'),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
