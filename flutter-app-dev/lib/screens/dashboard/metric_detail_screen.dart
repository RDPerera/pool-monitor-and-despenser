import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/device_provider.dart';
import '../../main.dart' show kBlue, kGreen, kOrange, kRed, kBg, kCardBg, kLabel, kLabel2, kLabel3, kSeparator;
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/sensor_chart.dart';

class MetricDetailScreen extends StatefulWidget {
  final String metric;
  const MetricDetailScreen({Key? key, required this.metric}) : super(key: key);
  @override
  State<MetricDetailScreen> createState() => _MetricDetailScreenState();
}

class _MetricDetailScreenState extends State<MetricDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dp = Provider.of<DeviceProvider>(context, listen: false);
      final id = dp.selectedDevice?.deviceId;
      if (id != null && dp.readings.isEmpty) dp.loadDeviceReadings(id, limit: 48);
    });
  }

  Widget _card({required Widget child, EdgeInsets padding = const EdgeInsets.all(20)}) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 20, offset: Offset(0, 2)),
          BoxShadow(color: Color(0x0F000000), blurRadius: 1,  offset: Offset(0, 1)),
        ],
      ),
      child: child,
    );
  }

  String _formatTs(String ts) {
    var dt = DateTime.tryParse(ts);
    if (dt == null) return ts;
    if (!dt.isUtc) dt = DateTime.utc(dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second);
    return DateFormat('MMM d, y · h:mm a').format(dt.toLocal());
  }

  String _status(double v) {
    switch (widget.metric) {
      case 'ph':
        if (v >= 7.2 && v <= 7.8) return 'SAFE';
        if ((v >= 6.8 && v < 7.2) || (v > 7.8 && v <= 8.2)) return 'WARNING';
        return 'CRITICAL';
      case 'turbidity':
        if (v <= 0.5) return 'SAFE';
        if (v <= 2.0) return 'WARNING';
        return 'CRITICAL';
      case 'chlorine':
        if (v >= 1.0 && v <= 3.0) return 'SAFE';
        if ((v >= 0.5 && v < 1.0) || (v > 3.0 && v <= 5.0)) return 'WARNING';
        return 'CRITICAL';
      case 'temperature':
        if (v >= 25 && v <= 30) return 'SAFE';
        if ((v >= 20 && v < 25) || (v > 30 && v <= 33)) return 'WARNING';
        return 'CRITICAL';
      default: return 'UNKNOWN';
    }
  }

  String _level(double v) {
    switch (widget.metric) {
      case 'ph':          return v > 7.8 ? 'High' : v < 7.2 ? 'Low' : 'Normal';
      case 'turbidity':   return v > 0.5 ? 'High' : 'Normal';
      case 'chlorine':    return v > 3.0 ? 'High' : v < 1.0 ? 'Low' : 'Normal';
      case 'temperature': return v > 30 ? 'High' : v < 25 ? 'Low' : 'Normal';
      default: return 'Normal';
    }
  }

  String _rec(String status, String level) {
    if (status == 'SAFE') return 'No action required. Water quality is in great condition.';
    switch (widget.metric) {
      case 'ph':
        if (level == 'High') return 'Add acid (HCl) to reduce pH level.';
        if (level == 'Low')  return 'Add base (soda ash) to increase pH level.';
        break;
      case 'turbidity':
        if (level == 'High') return 'Water is cloudy. Run filtration or add clarifier.';
        break;
      case 'chlorine':
        if (level == 'Low')  return 'Add chlorine to improve disinfection.';
        if (level == 'High') return 'Reduce chlorine level or dilute the pool water.';
        break;
      case 'temperature':
        if (level == 'High') return 'Cool down the water if possible.';
        if (level == 'Low')  return 'Increase water temperature if required.';
        break;
    }
    return 'Consult a professional for further advice.';
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'SAFE':     return kGreen;
      case 'WARNING':  return kOrange;
      case 'CRITICAL': return kRed;
      default:         return const Color(0xFF8E8E93);
    }
  }

  IconData _statusIcon(String s) {
    switch (s) {
      case 'SAFE':     return Icons.check_circle_rounded;
      case 'WARNING':  return Icons.warning_rounded;
      case 'CRITICAL': return Icons.cancel_rounded;
      default:         return Icons.help_rounded;
    }
  }

  Color _mColor() {
    switch (widget.metric) {
      case 'ph':          return kGreen;
      case 'turbidity':   return const Color(0xFF5AC8FA);
      case 'temperature': return kOrange;
      case 'chlorine':    return kBlue;
      default:            return kBlue;
    }
  }

  String _safeRange() {
    switch (widget.metric) {
      case 'ph':          return '7.2 – 7.8';
      case 'turbidity':   return '0 – 0.5 NTU';
      case 'chlorine':    return '1.0 – 3.0 ppm';
      case 'temperature': return '25 – 30 °C';
      default:            return '—';
    }
  }

  IconData _mIcon() {
    switch (widget.metric) {
      case 'ph':          return Icons.science_rounded;
      case 'turbidity':   return Icons.opacity_rounded;
      case 'temperature': return Icons.thermostat_rounded;
      case 'chlorine':    return Icons.water_drop_rounded;
      default:            return Icons.sensors;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dp      = Provider.of<DeviceProvider>(context);
    final reading = dp.latestReading;

    if (reading == null) {
      return Scaffold(
        backgroundColor: kBg,
        appBar: AppBar(title: Text(widget.metric.toUpperCase())),
        body: const Center(child: Text('No data available',
            style: TextStyle(color: kLabel2))),
      );
    }

    double value; String unit = ''; String? sub;
    switch (widget.metric) {
      case 'ph':          value = reading.ph; break;
      case 'turbidity':   value = reading.turbidity; unit = 'NTU'; break;
      case 'temperature': value = reading.temperature; unit = '°C'; break;
      case 'chlorine':
        value = reading.chlorineEstimated ?? dp.getEstimatedChlorine();
        unit = 'ppm';
        sub  = 'Estimated from pH, temperature & turbidity';
        break;
      default: value = 0;
    }

    final st   = _status(value);
    final lv   = _level(value);
    final sc   = _statusColor(st);
    final mc   = _mColor();
    final msg  = st == 'SAFE'
        ? 'Within the safe range'
        : lv == 'High'
            ? (st == 'WARNING' ? 'Slightly elevated' : 'Critically high')
            : (st == 'WARNING' ? 'Slightly below range' : 'Critically low');

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      backgroundColor: kBg,
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 0,
            backgroundColor: Colors.transparent,
            flexibleSpace: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                child: Container(color: Colors.white.withOpacity(0.8)),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(0.5),
              child: Container(height: 0.5, color: kSeparator),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kBlue, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(widget.metric.toUpperCase(),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kLabel)),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 12),
                width: 34, height: 34,
                decoration: BoxDecoration(color: mc.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(_mIcon(), color: mc, size: 18),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // Status row
                _card(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: sc.withOpacity(0.12),
                          shape: BoxShape.circle),
                      child: Icon(_statusIcon(st), color: sc, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(st, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: sc)),
                      Text(msg, style: const TextStyle(fontSize: 13, color: kLabel2)),
                    ])),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: sc.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(lv, style: TextStyle(fontSize: 12,
                          fontWeight: FontWeight.w600, color: sc)),
                    ),
                  ]),
                ),
                const SizedBox(height: 12),

                // Big value
                _card(
                  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                  child: Column(children: [
                    Text('${value.toStringAsFixed(2)} $unit',
                        style: TextStyle(fontSize: 52, fontWeight: FontWeight.w700, color: mc)),
                    if (sub != null) ...[
                      const SizedBox(height: 6),
                      Text(sub, style: const TextStyle(fontSize: 12, color: kLabel2),
                          textAlign: TextAlign.center),
                    ],
                    const SizedBox(height: 20),
                    Container(
                      height: 0.5, color: kSeparator,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    const SizedBox(height: 16),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('Safe Range', style: TextStyle(fontSize: 13, color: kLabel2)),
                      Text(_safeRange(), style: TextStyle(fontSize: 13,
                          fontWeight: FontWeight.w600, color: mc)),
                    ]),
                    const SizedBox(height: 8),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('Last Updated', style: TextStyle(fontSize: 13, color: kLabel2)),
                      Text(_formatTs(reading.timestamp),
                          style: const TextStyle(fontSize: 12, color: kLabel2)),
                    ]),
                  ]),
                ),
                const SizedBox(height: 12),

                // Recommendation
                _card(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                            color: kBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.lightbulb_outline_rounded,
                            color: kBlue, size: 17),
                      ),
                      const SizedBox(width: 10),
                      const Text('Recommendation',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: kLabel)),
                    ]),
                    const SizedBox(height: 12),
                    Text(_rec(st, lv),
                        style: const TextStyle(fontSize: 14, color: kLabel2, height: 1.5)),
                  ]),
                ),

                // History chart
                if (dp.readings.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _card(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                              color: mc.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8)),
                          child: Icon(_mIcon(), color: mc, size: 17),
                        ),
                        const SizedBox(width: 10),
                        Text('${widget.metric.toUpperCase()} History',
                            style: const TextStyle(fontSize: 15,
                                fontWeight: FontWeight.w600, color: kLabel)),
                      ]),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: SensorLineChart(
                          readings: dp.readings,
                          metric: widget.metric,
                          color: mc,
                          deviceProvider: dp,
                        ),
                      ),
                    ]),
                  ),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
