import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/device_provider.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/sensor_chart.dart';

class MetricsGraphScreen extends StatefulWidget {
  const MetricsGraphScreen({Key? key}) : super(key: key);

  @override
  State<MetricsGraphScreen> createState() => _MetricsGraphScreenState();
}

class _MetricsGraphScreenState extends State<MetricsGraphScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dp = Provider.of<DeviceProvider>(context, listen: false);
      final deviceId = dp.selectedDevice?.deviceId;
      if (deviceId != null && dp.readings.isEmpty) {
        dp.loadDeviceReadings(deviceId, limit: 48);
      }
    });
  }

  static const _metrics = ['ph', 'temperature', 'turbidity', 'chlorine'];
  static const _labels = ['pH Level', 'Temperature', 'Turbidity', 'Chlorine (Est.)'];
  static const _colors = [
    Color(0xFF43A047),
    Color(0xFFFB8C00),
    Color(0xFF546E7A),
    Color(0xFF1E88E5),
  ];

  @override
  Widget build(BuildContext context) {
    final deviceProvider = Provider.of<DeviceProvider>(context);
    final readings = deviceProvider.readings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Metrics Graph'),
        leading: const Padding(
          padding: EdgeInsets.only(left: 12),
          child: Center(child: AppLogo(size: 32)),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
      body: deviceProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : readings.isEmpty
              ? const Center(child: Text('No historical data available'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: List.generate(_metrics.length, (i) {
                    return _buildMetricChartCard(
                      deviceProvider,
                      readings,
                      _metrics[i],
                      _labels[i],
                      _colors[i],
                    );
                  }),
                ),
    );
  }

  Widget _buildMetricChartCard(
    DeviceProvider deviceProvider,
    readings,
    String metric,
    String label,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A2332),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: SensorLineChart(
              readings: readings,
              metric: metric,
              color: color,
              deviceProvider: deviceProvider,
            ),
          ),
        ],
      ),
    );
  }
}
