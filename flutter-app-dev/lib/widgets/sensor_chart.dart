import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/device.dart';
import '../providers/device_provider.dart';

// ── All-parameters normalised chart ──────────────────────────────────────────

class AllParametersChart extends StatelessWidget {
  final List<SensorReading> readings;
  final DeviceProvider deviceProvider;

  const AllParametersChart({
    Key? key,
    required this.readings,
    required this.deviceProvider,
  }) : super(key: key);

  static const _colors = [
    Color(0xFF34C759), // pH     – green
    Color(0xFF5AC8FA), // turb   – cyan
    Color(0xFFFF9500), // temp   – orange
    Color(0xFF007AFF), // chlor  – blue
  ];
  static const _labels = ['pH', 'Turbidity', 'Temp', 'Chlorine'];

  // Normalise each metric to a 0-10 display scale
  double _normPh(double v)   => ((v - 6.0) / 3.0 * 10).clamp(0.0, 10.0);
  double _normTurb(double v) => (v / 5.0 * 10).clamp(0.0, 10.0);
  double _normTemp(double v) => ((v - 20.0) / 15.0 * 10).clamp(0.0, 10.0);
  double _normChl(double v)  => (v / 8.0 * 10).clamp(0.0, 10.0);

  LineChartBarData _bar(List<FlSpot> spots, Color color) => LineChartBarData(
    spots: spots,
    isCurved: true,
    color: color,
    barWidth: 2,
    dotData: FlDotData(show: false),
    belowBarData: BarAreaData(show: false),
  );

  @override
  Widget build(BuildContext context) {
    final sorted = [...readings]..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    if (sorted.isEmpty) {
      return const Center(child: Text('No data', style: TextStyle(color: Colors.grey)));
    }

    final phSpots   = sorted.asMap().entries.map((e) => FlSpot(e.key.toDouble(), _normPh(e.value.ph))).toList();
    final turbSpots = sorted.asMap().entries.map((e) => FlSpot(e.key.toDouble(), _normTurb(e.value.turbidity))).toList();
    final tempSpots = sorted.asMap().entries.map((e) => FlSpot(e.key.toDouble(), _normTemp(e.value.temperature))).toList();
    final chlSpots  = sorted.asMap().entries.map((e) => FlSpot(e.key.toDouble(), _normChl(deviceProvider.estimateChlorineForReading(e.value)))).toList();

    final interval = sorted.length > 6 ? (sorted.length / 5).roundToDouble() : 1.0;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
        height: 180,
        child: LineChart(LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.withOpacity(0.12), strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: interval,
                getTitlesWidget: (value, _) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= sorted.length) return const SizedBox();
                  var t = DateTime.tryParse(sorted[idx].timestamp);
                  if (t == null) return const SizedBox();
                  if (!t.isUtc) t = DateTime.utc(t.year, t.month, t.day, t.hour, t.minute, t.second);
                  final local = t.toLocal();
                  return Text('${local.hour}:${local.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 9, color: Colors.grey));
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0, maxX: (sorted.length - 1).toDouble(),
          minY: 0, maxY: 10,
          lineBarsData: [
            _bar(phSpots,   _colors[0]),
            _bar(turbSpots, _colors[1]),
            _bar(tempSpots, _colors[2]),
            _bar(chlSpots,  _colors[3]),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: Colors.white.withOpacity(0.95),
              getTooltipItems: (spots) {
                final idx = spots.first.x.toInt().clamp(0, sorted.length - 1);
                final r = sorted[idx];
                final chl = deviceProvider.estimateChlorineForReading(r);
                final actuals = [
                  '${r.ph.toStringAsFixed(2)} pH',
                  '${r.turbidity.toStringAsFixed(2)} NTU',
                  '${r.temperature.toStringAsFixed(1)}°C',
                  '${chl.toStringAsFixed(1)} ppm',
                ];
                return List.generate(spots.length, (i) => LineTooltipItem(
                  actuals[spots[i].barIndex],
                  TextStyle(color: _colors[spots[i].barIndex], fontWeight: FontWeight.w600, fontSize: 11),
                ));
              },
            ),
          ),
        )),
      ),
      const SizedBox(height: 10),
      // Legend
      Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(4, (i) =>
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 14, height: 2.5, decoration: BoxDecoration(
              color: _colors[i], borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 4),
            Text(_labels[i], style: const TextStyle(fontSize: 10, color: Color(0xFF8E8E93))),
          ]),
        ),
      )),
    ]);
  }
}

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
