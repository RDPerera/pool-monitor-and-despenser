import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/device_provider.dart';
import 'dart:math' as math;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  bool _initialized = false;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final deviceProvider =
          Provider.of<DeviceProvider>(context, listen: false);
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

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      body: deviceProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : device == null
              ? _buildNoDeviceState()
              : RefreshIndicator(
                  onRefresh: () => deviceProvider.loadDevices(),
                  child: CustomScrollView(
                    slivers: [
                      // Custom Header (Not AppBar)
                      SliverToBoxAdapter(
                        child: _buildHeader(deviceProvider, reading),
                      ),

                      // Content
                      SliverPadding(
                        padding: const EdgeInsets.all(20),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            // Overall Quality Banner (Clickable)
                            _buildOverallQualityBanner(
                                deviceProvider, reading, context),
                            const SizedBox(height: 24),

                            // Pool Metrics Header
                            const Text(
                              'Pool Metrics',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A2332),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Metrics Grid
                            reading == null
                                ? _buildNoDataState()
                                : _buildMetricsGrid(reading),
                            const SizedBox(height: 40),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeader(DeviceProvider deviceProvider, reading) {
    final status = reading != null
        ? deviceProvider.getWaterQualityStatus()
        : 'Unknown';
    final statusColor = reading != null
        ? deviceProvider.getWaterQualityColor()
        : const Color(0xFF78909C);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE4E7EB), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Row (Bell icon removed)
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dashboard Overview',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A2332),
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Real-time pool water quality monitoring',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF5F6C7B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Status Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: statusColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  status == 'Optimal'
                      ? Icons.check_circle
                      : status == 'Warning'
                          ? Icons.warning_amber
                          : Icons.info,
                  size: 16,
                  color: statusColor,
                ),
                const SizedBox(width: 8),
                Text(
                  status == 'Optimal'
                      ? 'All parameters within safe range'
                      : status == 'Warning'
                          ? 'Some parameters need attention'
                          : 'Check your pool status',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallQualityBanner(
      DeviceProvider deviceProvider, reading, BuildContext context) {
    if (reading == null) {
      return _buildStatusCard(
        'System Status',
        'Unknown',
        'Waiting for data...',
        const Color(0xFF78909C),
        Icons.error_outline,
        context,
      );
    }

    final status = deviceProvider.getWaterQualityStatus();
    // Use blue color #1E88E5 instead of green for Overall Quality
    const color = Color(0xFF1E88E5);

    String message;
    IconData icon;

    switch (status) {
      case 'Optimal':
        message = 'All parameters within target range';
        icon = Icons.check_circle_outline;
        break;
      case 'Warning':
        message = 'Some parameters need attention';
        icon = Icons.warning_amber_outlined;
        break;
      case 'Critical':
        message = 'Immediate action required';
        icon = Icons.error_outline;
        break;
      default:
        message = 'Checking system status';
        icon = Icons.help_outline;
    }

    return _buildStatusCard(
      'Overall Quality',
      status,
      message,
      color,
      icon,
      context,
    );
  }

  Widget _buildStatusCard(
    String title,
    String status,
    String message,
    Color color,
    IconData icon,
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: () {
        // Navigate to Overall Overview Page
        Navigator.pushNamed(context, '/overall-overview');
      },
      child: AnimatedBuilder(
        animation: _waveController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color,
                  color.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Animated Wave
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: CustomPaint(
                    size: const Size(double.infinity, 50),
                    painter: _AnimatedWavePainter(
                      color: Colors.white.withOpacity(0.15),
                      animation: _waveController,
                    ),
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Spacer(),
                          // Tap to view details hint
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  'Tap to view details',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white.withOpacity(0.9),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 10,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        status,
                        style: const TextStyle(
                          fontSize: 32,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        message,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.95),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricsGrid(reading) {
    return Column(
      children: [
        // Row 1
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'pH Level',
                reading.ph.toStringAsFixed(2),
                '7.2-7.8',
                const Color(0xFFE8F5E9), // Soft green background
                const Color(0xFF43A047), // Green icon
                const Color(0xFF1B5E20), // Dark green text
                Icons.science_outlined,
                onTap: () => Navigator.pushNamed(context, '/metric/ph'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Turbidity',
                '${reading.turbidity.toStringAsFixed(1)} NTU',
                '< 5.0',
                const Color(0xFFECEFF1), // Light grey-blue background
                const Color(0xFF546E7A), // Grey-blue icon
                const Color(0xFF263238), // Dark grey text
                Icons.opacity_outlined,
                onTap: () => Navigator.pushNamed(context, '/metric/turbidity'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Row 2
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Temperature',
                '${reading.temperature.toStringAsFixed(1)}°C',
                '26-30°C',
                const Color(0xFFFFF3E0), // Soft warm orange background
                const Color(0xFFFB8C00), // Orange icon
                const Color(0xFF5D4037), // Brown text
                Icons.thermostat_outlined,
                onTap: () =>
                    Navigator.pushNamed(context, '/metric/temperature'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Chlorine',
                '${(reading.ph * 0.3).toStringAsFixed(1)} ppm',
                '1.0-3.0',
                const Color(0xFFE3F2FD), // Very light blue background
                const Color(0xFF1E88E5), // Blue icon
                const Color(0xFF0D47A1), // Dark blue text
                Icons.water_drop_outlined,
                onTap: () {},
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    String range,
    Color backgroundColor,
    Color iconColor,
    Color textColor,
    IconData icon, {
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE4E7EB), width: 1),
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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: iconColor,
                  ),
                ),
                const Spacer(),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: iconColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: textColor.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Range: $range',
              style: TextStyle(
                fontSize: 11,
                color: textColor.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDeviceState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.devices_outlined,
            size: 64,
            color: Color(0xFF8A94A6),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Devices Found',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A2332),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add a device to start monitoring',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF5F6C7B),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add),
            label: const Text('Add Device'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4E7EB)),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.hourglass_empty,
            size: 48,
            color: Color(0xFF8A94A6),
          ),
          SizedBox(height: 16),
          Text(
            'No sensor data available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1A2332),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Waiting for first reading from device',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF5F6C7B),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Animated Wave Painter
class _AnimatedWavePainter extends CustomPainter {
  final Color color;
  final Animation<double> animation;

  _AnimatedWavePainter({required this.color, required this.animation})
      : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final waveOffset = animation.value * 2 * math.pi;

    path.moveTo(0, size.height);

    for (double i = 0; i <= size.width; i++) {
      path.lineTo(
        i,
        size.height -
            20 +
            math.sin((i / size.width) * 2 * math.pi + waveOffset) * 10,
      );
    }

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}