import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/device_provider.dart';
import '../../widgets/app_logo.dart';

class MetricDetailScreen extends StatelessWidget {
  final String metric;
  const MetricDetailScreen({Key? key, required this.metric}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final deviceProvider = Provider.of<DeviceProvider>(context);
    final reading = deviceProvider.latestReading;
    if (reading == null) {
      return Scaffold(
        appBar: AppBar(title: Text('$metric Details')),
        body: const Center(child: Text('No data available')),
      );
    }
    double value;
    String unit = '';
    switch (metric) {
      case 'ph':
        value = reading.ph;
        break;
      case 'turbidity':
        value = reading.turbidity;
        break;
      case 'temperature':
        value = reading.temperature;
        unit = '°C';
        break;
      default:
        value = 0;
    }
    return Scaffold(
      appBar: AppBar(title: Text('$metric Details'), leading: const Padding(padding: EdgeInsets.only(left:12), child: AppLogo(size:32))),
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(32),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  metric.toUpperCase(),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Text(
                  '${value.toStringAsFixed(2)} $unit',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(color: Colors.blue),
                ),
                const SizedBox(height: 16),
                Text('Last updated: ${reading.timestamp}'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
