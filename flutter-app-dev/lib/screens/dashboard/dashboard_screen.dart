import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/device_provider.dart';
import '../../main.dart' show kBlue, kGreen, kOrange, kRed, kBg, kCardBg, kLabel, kLabel2, kLabel3, kSeparator;
import '../../widgets/app_logo.dart';
import '../../widgets/sensor_chart.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  bool _initialized = false;
  late AnimationController _waveCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  int _trendIdx = 0;

  static const _trendMetrics = ['ph', 'temperature', 'turbidity', 'chlorine'];
  static const _trendLabels  = ['pH', 'Temp', 'Turbidity', 'Cl'];
  static const _trendColors  = [kGreen, kOrange, Color(0xFF5AC8FA), kBlue];

  @override
  void initState() {
    super.initState();
    _waveCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<DeviceProvider>(context, listen: false).loadDevices();
      });
      _initialized = true;
    }
  }

  // ── Apple card ────────────────────────────────────────────────────────────

  Widget _card({required Widget child, EdgeInsets padding = const EdgeInsets.all(20),
      double radius = 16, VoidCallback? onTap}) {
    final w = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 20, offset: Offset(0, 2)),
          BoxShadow(color: Color(0x0F000000), blurRadius: 1,  offset: Offset(0, 1)),
        ],
      ),
      child: child,
    );
    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: w);
    }
    return w;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final dp      = Provider.of<DeviceProvider>(context);
    final reading = dp.latestReading;
    final top     = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: kBg,
      body: dp.isLoading && reading == null
          ? const Center(child: CircularProgressIndicator(color: kBlue))
          : dp.selectedDevice == null
              ? _noDevice()
              : RefreshIndicator(
                  onRefresh: () => dp.loadDevices(),
                  color: kBlue,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      // ── Frosted glass large title bar ──
                      SliverAppBar(
                        pinned: true,
                        expandedHeight: 0,
                        toolbarHeight: 56,
                        backgroundColor: Colors.transparent,
                        flexibleSpace: ClipRect(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                            child: Container(
                              color: Colors.white.withOpacity(0.8),
                              child: SafeArea(
                                bottom: false,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Row(children: [
                                    const AppLogo(size: 32,
                                        useWhiteBackground: true,
                                        backgroundColor: kBlue),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Monitor',
                                              style: TextStyle(fontSize: 17,
                                                  fontWeight: FontWeight.w600, color: kLabel)),
                                          if ((dp.selectedDevice?.name ?? '').isNotEmpty)
                                            Text(dp.selectedDevice?.name ?? '',
                                                style: const TextStyle(
                                                    fontSize: 11, color: kLabel2)),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.refresh_rounded, color: kBlue, size: 20),
                                      onPressed: () => dp.loadDevices(),
                                    ),
                                  ]),
                                ),
                              ),
                            ),
                          ),
                        ),
                        bottom: PreferredSize(
                          preferredSize: const Size.fromHeight(0.5),
                          child: Container(height: 0.5, color: kSeparator),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            _buildQualityCard(dp, reading),
                            const SizedBox(height: 20),
                            _sectionTitle('POOL METRICS'),
                            const SizedBox(height: 8),
                            reading == null ? _noData() : _buildMetricsGrid(reading, dp),
                            if (dp.readings.isNotEmpty) ...[
                              const SizedBox(height: 20),
                              _sectionTitle('24H TRENDS'),
                              const SizedBox(height: 8),
                              _buildTrendsCard(dp),
                            ],
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _sectionTitle(String t) => Text(t,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
          color: kLabel2, letterSpacing: 0.5));

  // ── Quality card ──────────────────────────────────────────────────────────

  Widget _buildQualityCard(DeviceProvider dp, reading) {
    final status = reading != null ? dp.getWaterQualityStatus() : 'Unknown';
    Color sc; IconData si; String msg;

    switch (status) {
      case 'Optimal':
        sc = kGreen; si = Icons.check_circle_rounded; msg = 'All parameters in range'; break;
      case 'Warning':
        sc = kOrange; si = Icons.warning_rounded; msg = 'Some parameters need attention'; break;
      case 'Critical':
        sc = kRed; si = Icons.cancel_rounded; msg = 'Immediate action required'; break;
      default:
        sc = const Color(0xFF8E8E93); si = Icons.help_rounded;
        msg = 'Waiting for device data';
    }

    // fallback icons (those above are not standard Flutter icons)
    si = status == 'Optimal' ? Icons.check_circle_rounded
        : status == 'Warning' ? Icons.warning_rounded
        : status == 'Critical' ? Icons.cancel_rounded
        : Icons.sensors_rounded;

    return _card(
      onTap: () => Navigator.pushNamed(context, '/metrics/graph'),
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(children: [
          // Subtle wave
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: AnimatedBuilder(
              animation: _waveCtrl,
              builder: (_, __) => CustomPaint(
                size: const Size(double.infinity, 44),
                painter: _WavePainter(color: sc.withOpacity(0.06), animation: _waveCtrl),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(children: [
              // Status circle icon
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                    color: sc.withOpacity(0.12), shape: BoxShape.circle),
                child: AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (_, __) => Icon(si, color: sc.withOpacity(_pulseAnim.value), size: 28),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Water Quality',
                    style: const TextStyle(fontSize: 13, color: kLabel2)),
                const SizedBox(height: 3),
                Text(status,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
                        color: kLabel)),
                const SizedBox(height: 3),
                Text(msg, style: const TextStyle(fontSize: 13, color: kLabel2)),
              ])),
              Icon(Icons.chevron_right, color: kLabel3, size: 18),
            ]),
          ),
        ]),
      ),
    );
  }

  // ── Metrics grid ──────────────────────────────────────────────────────────

  static const _metricDefs = [
    ('pH Level',     'ph',          Icons.science_rounded,    kGreen,              '7.2–7.8'),
    ('Turbidity',    'turbidity',   Icons.opacity_rounded,    Color(0xFF5AC8FA),   '< 0.5 NTU'),
    ('Temperature',  'temperature', Icons.thermostat_rounded, kOrange,             '26–30°C'),
    ('Chlorine',     'chlorine',    Icons.water_drop_rounded, kBlue,               '1.0–3.0 ppm'),
  ];

  Widget _buildMetricsGrid(reading, DeviceProvider dp) {
    final values = [
      reading.ph.toStringAsFixed(2),
      '${reading.turbidity.toStringAsFixed(1)} NTU',
      '${reading.temperature.toStringAsFixed(1)}°',
      '${dp.getEstimatedChlorine().toStringAsFixed(1)} ppm',
    ];
    return Column(children: [
      SizedBox(
        height: 160,
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(child: _metricCard(0, values[0])),
          const SizedBox(width: 12),
          Expanded(child: _metricCard(1, values[1])),
        ]),
      ),
      const SizedBox(height: 12),
      SizedBox(
        height: 160,
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(child: _metricCard(2, values[2])),
          const SizedBox(width: 12),
          Expanded(child: _metricCard(3, values[3])),
        ]),
      ),
    ]);
  }

  Widget _metricCard(int i, String value) {
    final (label, metric, icon, accent, range) = _metricDefs[i];
    final dot = _statusDot(metric, value);

    return _card(
      padding: const EdgeInsets.all(14),
      onTap: () => Navigator.pushNamed(context, '/metric/$metric'),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          Container(
            width: 9, height: 9,
            decoration: BoxDecoration(
              color: dot,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: dot.withOpacity(0.4), blurRadius: 5)],
            ),
          ),
        ]),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: kLabel),
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 1),
          Text(label,
              style: const TextStyle(fontSize: 12, color: kLabel2),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(range, style: TextStyle(fontSize: 9, color: accent,
                fontWeight: FontWeight.w600)),
          ),
        ]),
      ]),
    );
  }

  Color _statusDot(String metric, String raw) {
    final v = double.tryParse(raw.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;
    switch (metric) {
      case 'ph':
        if (v >= 7.2 && v <= 7.8) return kGreen;
        if ((v >= 6.8 && v < 7.2) || (v > 7.8 && v <= 8.2)) return kOrange;
        return kRed;
      case 'turbidity':
        if (v <= 0.5) return kGreen;
        if (v <= 2.0) return kOrange;
        return kRed;
      case 'chlorine':
        if (v >= 1.0 && v <= 3.0) return kGreen;
        if ((v >= 0.5 && v < 1.0) || (v > 3.0 && v <= 5.0)) return kOrange;
        return kRed;
      case 'temperature':
        if (v >= 25 && v <= 30) return kGreen;
        if ((v >= 20 && v < 25) || (v > 30 && v <= 33)) return kOrange;
        return kRed;
      default: return const Color(0xFF8E8E93);
    }
  }

  // ── Trends card ───────────────────────────────────────────────────────────

  Widget _buildTrendsCard(DeviceProvider dp) {
    return _card(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Segment-style tab
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: List.generate(_trendMetrics.length, (i) {
            final sel = i == _trendIdx;
            return GestureDetector(
              onTap: () => setState(() => _trendIdx = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  color: sel ? _trendColors[i] : kBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(_trendLabels[i], style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600,
                  color: sel ? Colors.white : kLabel2,
                )),
              ),
            );
          })),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: SensorLineChart(
            readings: dp.readings,
            metric: _trendMetrics[_trendIdx],
            color: _trendColors[_trendIdx],
            deviceProvider: dp,
          ),
        ),
      ]),
    );
  }

  // ── Empty states ──────────────────────────────────────────────────────────

  Widget _noDevice() => Center(
    child: _card(
      padding: const EdgeInsets.all(36),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.wifi_off_rounded, size: 52, color: kLabel3),
        const SizedBox(height: 16),
        const Text('No Device Found',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: kLabel)),
        const SizedBox(height: 6),
        const Text('Connect a device to start monitoring',
            style: TextStyle(fontSize: 14, color: kLabel2), textAlign: TextAlign.center),
      ]),
    ),
  );

  Widget _noData() => _card(
    padding: const EdgeInsets.all(28),
    child: const Column(children: [
      Icon(Icons.hourglass_empty_rounded, size: 44, color: kLabel3),
      SizedBox(height: 12),
      Text('Waiting for sensor data',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: kLabel)),
      SizedBox(height: 4),
      Text('First reading will appear here',
          style: TextStyle(fontSize: 13, color: kLabel2), textAlign: TextAlign.center),
    ]),
  );
}

// ── Wave painter ───────────────────────────────────────────────────────────────

class _WavePainter extends CustomPainter {
  final Color color;
  final Animation<double> animation;
  _WavePainter({required this.color, required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final path  = Path();
    final o = animation.value * 2 * math.pi;
    path.moveTo(0, size.height);
    for (double x = 0; x <= size.width; x++) {
      path.lineTo(x, size.height - 12 + math.sin((x / size.width) * 2 * math.pi + o) * 7);
    }
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => true;
}
