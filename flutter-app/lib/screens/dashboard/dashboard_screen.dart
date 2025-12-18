import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/device_provider.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        deviceProvider.loadDevices();
      });
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceProvider = Provider.of<DeviceProvider>(context);
    final device = deviceProvider.selectedDevice;
    final reading = deviceProvider.latestReading;
    final devices = deviceProvider.devices;
    final error = deviceProvider.error;

    return Scaffold(
      appBar: AppBar(title: const Text('Pool Dashboard')),
      body: deviceProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text('Error: $error', style: const TextStyle(color: Colors.red)))
              : device == null
                  ? const Center(child: Text('No device available'))
                  : reading == null
                      ? Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    device.name,
                                    style: Theme.of(context).textTheme.headline6,
                                  ),
                                  if (devices.length > 1)
                                    DropdownButton<String>(
                                      value: device.deviceId,
                                      items: devices
                                          .map((d) => DropdownMenuItem(
                                                value: d.deviceId,
                                                child: Text(d.name),
                                              ))
                                          .toList(),
                                      onChanged: (id) {
                                        if (id != null) {
                                          deviceProvider.selectDevice(id);
                                        }
                                      },
                                    ),
                                ],
                              ),
                            ),
                            const Expanded(
                              child: Center(
                                child: Text('No sensor data available for this device.'),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    device.name,
                                    style: Theme.of(context).textTheme.headline6,
                                  ),
                                  if (devices.length > 1)
                                    DropdownButton<String>(
                                      value: device.deviceId,
                                      items: devices
                                          .map((d) => DropdownMenuItem(
                                                value: d.deviceId,
                                                child: Text(d.name),
                                              ))
                                          .toList(),
                                      onChanged: (id) {
                                        if (id != null) {
                                          deviceProvider.selectDevice(id);
                                        }
                                      },
                                    ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: GridView.count(
                                crossAxisCount: 2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 1.1,
                                children: [
                                  _MetricCard(
                                    title: 'pH',
                                    value: reading.ph.toStringAsFixed(2),
                                    color: _getMetricColor(reading.ph, 7.2, 7.8),
                                    icon: Icons.science,
                                    onTap: () => Navigator.pushNamed(context, '/metric/ph'),
                                  ),
                                  _MetricCard(
                                    title: 'Turbidity',
                                    value: reading.turbidity.toStringAsFixed(2),
                                    color: _getMetricColor(reading.turbidity, 0, 5),
                                    icon: Icons.opacity,
                                    onTap: () => Navigator.pushNamed(context, '/metric/turbidity'),
                                  ),
                                  _MetricCard(
                                    title: 'Temperature',
                                    value: reading.temperature.toStringAsFixed(1) + ' °C',
                                    color: _getMetricColor(reading.temperature, 26, 30),
                                    icon: Icons.thermostat,
                                    onTap: () => Navigator.pushNamed(context, '/metric/temperature'),
                                  ),
                                  _AllMetricsCard(
                                    onTap: () => Navigator.pushNamed(context, '/metrics/graph'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
    );
  }

  Color _getMetricColor(double value, double min, double max) {
    if (value < min || value > max) {
      return Colors.red;
    } else if (value < min + (max - min) * 0.1 || value > max - (max - min) * 0.1) {
      return Colors.orange;
    }
    return Colors.green;
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(value, style: TextStyle(fontSize: 20, color: color, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

class _AllMetricsCard extends StatelessWidget {
  final VoidCallback onTap;
  const _AllMetricsCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: Colors.deepPurple,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.show_chart, size: 40, color: Colors.white),
              SizedBox(height: 12),
              Text('All Metrics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}
