import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/device_provider.dart';

class MetricsGraphScreen extends StatelessWidget {
  const MetricsGraphScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final deviceProvider = Provider.of<DeviceProvider>(context);
    final readings = deviceProvider.readings;
    return Scaffold(
      appBar: AppBar(title: const Text('Metrics Graph')),
      body: readings.isEmpty
          ? const Center(child: Text('No data available'))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Expanded(
                    child: LineChart(
                      LineChartData(
                        lineBarsData: [
                          _buildLineBar(readings, 'ph', Colors.green),
                          _buildLineBar(readings, 'turbidity', Colors.orange),
                          _buildLineBar(readings, 'temperature', Colors.blue),
                        ],
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: true),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        gridData: FlGridData(show: true),
                        borderData: FlBorderData(show: true),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      _Legend(color: Colors.green, label: 'pH'),
                      SizedBox(width: 16),
                      _Legend(color: Colors.orange, label: 'Turbidity'),
                      SizedBox(width: 16),
                      _Legend(color: Colors.blue, label: 'Temperature'),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  LineChartBarData _buildLineBar(List readings, String metric, Color color) {
    final spots = <FlSpot>[];
    for (int i = 0; i < readings.length; i++) {
      final r = readings[i];
      double y;
      switch (metric) {
        case 'ph':
          y = r.ph;
          break;
        case 'turbidity':
          y = r.turbidity;
          break;
        case 'temperature':
          y = r.temperature;
          break;
        default:
          y = 0;
      }
      spots.add(FlSpot(i.toDouble(), y));
    }
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 2,
      dotData: FlDotData(show: false),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 16, height: 16, color: color),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }
}
