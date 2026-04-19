import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/device.dart';
import '../providers/device_provider.dart';

class SensorLineChart extends StatelessWidget {
  final List<SensorReading> readings;
  final String metric;
  final Color color;
  final DeviceProvider deviceProvider;

  const SensorLineChart({
    Key? key,
    required this.readings,
    required this.metric,
    required this.color,
    required this.deviceProvider,
  }) : super(key: key);

  double _getValue(SensorReading r) {
    switch (metric) {
      case 'ph':
        return r.ph;
      case 'turbidity':
        return r.turbidity;
      case 'temperature':
        return r.temperature;
      case 'chlorine':
        return deviceProvider.estimateChlorineForReading(r);
      default:
        return 0;
    }
  }

  String _getUnit() {
    switch (metric) {
      case 'ph':
        return '';
      case 'turbidity':
        return ' NTU';
      case 'temperature':
        return '°C';
      case 'chlorine':
        return ' ppm';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final sorted = [...readings]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (sorted.isEmpty) {
      return const Center(
        child: Text('No historical data', style: TextStyle(color: Colors.grey)),
      );
    }

    final spots = sorted.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), _getValue(e.value));
    }).toList();

    final values = spots.map((s) => s.y).toList();
    final rawMin = values.reduce(min);
    final rawMax = values.reduce(max);
    final padding = (rawMax - rawMin) * 0.15;
    final minY = rawMin - padding;
    final maxY = rawMax + padding;

    final interval = sorted.length > 6
        ? (sorted.length / 5).roundToDouble()
        : 1.0;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.withOpacity(0.15),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: (value, meta) => Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  '${value.toStringAsFixed(1)}${_getUnit()}',
                  style: const TextStyle(fontSize: 9, color: Colors.grey),
                  textAlign: TextAlign.right,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: interval,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= sorted.length) return const SizedBox();
                var t = DateTime.tryParse(sorted[idx].timestamp);
                if (t == null) return const SizedBox();
                if (!t.isUtc) t = DateTime.utc(t.year, t.month, t.day, t.hour, t.minute, t.second);
                final local = t.toLocal();
                return Text(
                  '${local.hour}:${local.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 9, color: Colors.grey),
                );
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (sorted.length - 1).toDouble(),
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 2.5,
            dotData: FlDotData(show: sorted.length <= 12),
            belowBarData: BarAreaData(
              show: true,
              color: color.withOpacity(0.08),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.white.withOpacity(0.9),
            getTooltipItems: (spots) => spots
                .map((s) => LineTooltipItem(
                      '${s.y.toStringAsFixed(2)}${_getUnit()}',
                      TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }
}
