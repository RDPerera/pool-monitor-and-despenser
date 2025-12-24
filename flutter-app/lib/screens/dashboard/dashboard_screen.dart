import 'dart:ui';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../providers/auth_provider.dart';
import '../../providers/device_provider.dart';
import '../../models/device.dart';


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

  Color _getMetricColor(double value, double min, double max) {
    if (value < min || value > max) {
      return Colors.red.shade600;
    } else if (value < min + (max - min) * 0.1 || value > max - (max - min) * 0.1) {
      return const Color(0xFFFF9800); // New orange variant
    }
    return const Color(0xFF4CAF50); // New green variant
  }

  String _calculateOverallQuality(SensorReading reading) {
    double _calculateScore(double value, double min, double max, {bool invert = false}) {
      if (invert) {
        if (value <= min) return 1.0;
        if (value >= max) return 0.0;
        return 1.0 - (value - min) / (max - min);
      } else {
        if (value >= min && value <= max) return 1.0;
        if (value < min) return (value / min).clamp(0.0, 1.0);
        return (max / value).clamp(0.0, 1.0);
      }
    }

    double phScore = _calculateScore(reading.ph, 7.2, 7.8);
    double turbidityScore = _calculateScore(reading.turbidity, 0, 5, invert: true);
    double tempScore = _calculateScore(reading.temperature, 26, 30);
    double overallScore = (phScore + turbidityScore + tempScore) / 3;

    if (overallScore >= 0.8) return 'Excellent';
    if (overallScore >= 0.6) return 'Good';
    if (overallScore >= 0.4) return 'Fair';
    return 'Poor';
  }

  Color _getOverallQualityColor(String quality) {
    switch (quality) {
      case 'Excellent':
        return const Color(0xFF4CAF50); // New green variant
      case 'Good':
        return Colors.lightGreen.shade500;
      case 'Fair':
        return const Color(0xFFFF9800); // New orange variant
      case 'Poor':
        return Colors.red.shade600;
      default:
        return Colors.grey.shade500;
    }
  }

  double _calculateChlorineLevel(double ph) {
    // Derive chlorine level from pH - optimal around 7.2-7.8 pH corresponds to 1-3 ppm chlorine
    if (ph >= 7.2 && ph <= 7.8) {
      return 1.5 + (ph - 7.2) * 0.5; // 1.5 to 2.5 ppm
    } else if (ph < 7.2) {
      return 1.0 + (ph - 6.5) * 0.2; // Lower pH, lower chlorine
    } else {
      return 2.5 + (ph - 7.8) * 0.3; // Higher pH, higher chlorine
    }
  }

  Color _getChlorineColor(double chlorine) {
    if (chlorine >= 1.0 && chlorine <= 3.0) {
      return const Color(0xFF4CAF50); // New green variant
    } else if (chlorine >= 0.5 && chlorine < 1.0 || chlorine > 3.0 && chlorine <= 5.0) {
      return const Color(0xFFFF9800); // New orange variant
    } else {
      return Colors.red.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceProvider = Provider.of<DeviceProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final device = deviceProvider.selectedDevice;
    final reading = deviceProvider.latestReading;
    final devices = deviceProvider.devices;
    final error = deviceProvider.error;
    final user = authProvider.currentUser;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(''),
        backgroundColor: Colors.white.withOpacity(0.9),
        elevation: 0,
        actions: devices.length > 1 && device != null
            ? [
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: DropdownButton<String>(
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
                    underline: const SizedBox(),
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ]
            : null,
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: deviceProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : error != null
                ? Center(child: Text('Error: $error', style: const TextStyle(color: Colors.red)))
                : device == null
                    ? const Center(child: Text('No device available'))
                    : reading == null
                        ? Column(
                            children: [
                              const SizedBox(height: kToolbarHeight + 16),
                              Expanded(
                                child: Center(
                                  child: Text(
                                    'No sensor data available for this device.',
                                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : SingleChildScrollView(
                            child: Column(
                              children: [
                                // Top bar with username
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  color: Colors.blue.shade50,
                                  child: Row(
                                    children: [
                                      Icon(Icons.pool, color: Colors.blue.shade700, size: 28),
                                      const SizedBox(width: 12),
                                      Text(
                                        user != null ? "${user.firstName}'s Pool" : "My Pool",
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                          fontFamily: 'SF Pro Display',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: kToolbarHeight),
                                // Overall Quality Card at top
                                _WaterQualityCard(
                                  quality: _calculateOverallQuality(reading),
                                  color: _getOverallQualityColor(_calculateOverallQuality(reading)),
                                  onTap: () => Navigator.pushNamed(context, '/metrics/graph'),
                                ),
                                const SizedBox(height: 16),
                                // Metrics label
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Pool Metrics',
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.onSurface,
                                        fontFamily: 'SF Pro Display',
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Other Metric Cards
                                GridView.count(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 1.2,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  children: [
                                    _PhAnimatedCard(
                                      value: reading.ph.toStringAsFixed(2),
                                      color: _getMetricColor(reading.ph, 7.2, 7.8),
                                      onTap: () => Navigator.pushNamed(context, '/metric/ph'),
                                    ),
                                    _TurbidityAnimatedCard(
                                      value: reading.turbidity.toStringAsFixed(2),
                                      color: _getMetricColor(reading.turbidity, 0, 5),
                                      onTap: () => Navigator.pushNamed(context, '/metric/turbidity'),
                                    ),
                                    _TemperatureAnimatedCard(
                                      value: reading.temperature.toStringAsFixed(1) + ' °C',
                                      color: _getMetricColor(reading.temperature, 26, 30),
                                      onTap: () => Navigator.pushNamed(context, '/metric/temperature'),
                                    ),
                                    _ChlorineAnimatedCard(
                                      value: _calculateChlorineLevel(reading.ph).toStringAsFixed(1) + ' ppm',
                                      color: _getChlorineColor(_calculateChlorineLevel(reading.ph)),
                                      onTap: () {}, // TODO: Add navigation
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
      ),
    );
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
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

class _OverallQualityCard extends StatelessWidget {
  final String quality;
  final Color color;
  final VoidCallback onTap;

  const _OverallQualityCard({
    required this.quality,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.pool, size: 48, color: color),
              const SizedBox(height: 12),
              Text(
                'Overall Quality',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _SimpleMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _SimpleMetricCard({
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
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: Colors.white.withOpacity(0.1),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 32, color: color),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WaterQualityCard extends StatefulWidget {
  final String quality;
  final Color color;
  final VoidCallback onTap;

  const _WaterQualityCard({
    required this.quality,
    required this.color,
    required this.onTap,
  });

  @override
  State<_WaterQualityCard> createState() => _WaterQualityCardState();
}

class _WaterQualityCardState extends State<_WaterQualityCard>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _gyroController;
  double _gyroX = 0.0;
  double _gyroY = 0.0;
  StreamSubscription<GyroscopeEvent>? _gyroSubscription;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _gyroController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    // Check if gyroscope is available
    gyroscopeEvents.first.then((_) {
      _gyroSubscription = gyroscopeEvents.listen((GyroscopeEvent event) {
        setState(() {
          _gyroX = event.x * 10; // Amplify for effect
          _gyroY = event.y * 10;
        });
      });
    }).catchError((_) {
      // Gyroscope not available, keep defaults
    });
  }

  @override
  void dispose() {
    _waveController.dispose();
    _gyroController.dispose();
    _gyroSubscription?.cancel();
    super.dispose();
  }

  Color _getWaterColor(String quality) {
    switch (quality) {
      case 'Excellent':
        return Colors.blue.shade300;
      case 'Good':
        return Colors.blue.shade400;
      case 'Fair':
        return Colors.yellow.shade300;
      case 'Poor':
        return Colors.red.shade300;
      default:
        return Colors.grey.shade300;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        height: 120,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: widget.color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Water background
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getWaterColor(widget.quality).withOpacity(0.8),
                      _getWaterColor(widget.quality).withOpacity(0.4),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              // Waves
              AnimatedBuilder(
                animation: _waveController,
                builder: (context, child) {
                  return CustomPaint(
                    size: const Size(double.infinity, 120),
                    painter: WavePainter(
                      animationValue: _waveController.value,
                      gyroX: _gyroX,
                      gyroY: _gyroY,
                      waterColor: _getWaterColor(widget.quality),
                    ),
                  );
                },
              ),
              // Content overlay
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.pool,
                      size: 40,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Overall Quality',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'SF Pro Display',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.quality,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'SF Pro Display',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WavePainter extends CustomPainter {
  final double animationValue;
  final double gyroX;
  final double gyroY;
  final Color waterColor;

  WavePainter({
    required this.animationValue,
    required this.gyroX,
    required this.gyroY,
    required this.waterColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = waterColor.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final path = Path();

    // Create multiple waves
    for (int i = 0; i < 3; i++) {
      final wavePath = Path();
      final amplitude = 8.0 + i * 2;
      final frequency = 2 + i * 0.5;
      final phase = animationValue * 2 * 3.14159 + i * 0.5;

      wavePath.moveTo(0, size.height);

      for (double x = 0; x <= size.width; x += 2) {
        final y = size.height / 2 +
            amplitude * sin(x / size.width * frequency * 3.14159 + phase) +
            gyroY * (i + 1) * 0.5; // Gyro effect
        wavePath.lineTo(x + gyroX * (i + 1) * 0.3, y); // Gyro horizontal
      }

      wavePath.lineTo(size.width, size.height);
      wavePath.close();

      canvas.drawPath(wavePath, paint);
    }
  }

  @override
  bool shouldRepaint(WavePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
           oldDelegate.gyroX != gyroX ||
           oldDelegate.gyroY != gyroY ||
           oldDelegate.waterColor != waterColor;
  }
}

class BubblePainter extends CustomPainter {
  final double animationValue;
  final Color color;

  BubblePainter({required this.animationValue, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.4)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 5; i++) {
      final delay = i * 0.2;
      final progress = (animationValue + delay) % 1.0;
      final x = 20.0 + i * 15;
      final y = size.height - progress * size.height;
      final radius = 4 + i * 1.5;

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(BubblePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue || oldDelegate.color != color;
  }
}

class ParticlePainter extends CustomPainter {
  final double animationValue;
  final Color color;

  ParticlePainter({required this.animationValue, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 8; i++) {
      final angle = (i / 8) * 2 * pi + animationValue * 2 * pi;
      final radius = 15 + (i % 3) * 10;
      final x = size.width / 2 + cos(angle) * radius;
      final y = size.height / 2 + sin(angle) * radius;
      final particleSize = 2.0 + (i % 2);

      canvas.drawCircle(Offset(x, y), particleSize, paint);
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue || oldDelegate.color != color;
  }
}

class _PhAnimatedCard extends StatefulWidget {
  final String value;
  final Color color;
  final VoidCallback onTap;

  const _PhAnimatedCard({
    required this.value,
    required this.color,
    required this.onTap,
  });

  @override
  State<_PhAnimatedCard> createState() => _PhAnimatedCardState();
}

class _PhAnimatedCardState extends State<_PhAnimatedCard>
    with TickerProviderStateMixin {
  late AnimationController _bubbleController;

  @override
  void initState() {
    super.initState();
    _bubbleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _bubbleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: widget.color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Colored background
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.color.withOpacity(0.8),
                      widget.color.withOpacity(0.4),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              // Bubbles animation
              AnimatedBuilder(
                animation: _bubbleController,
                builder: (context, child) {
                  return CustomPaint(
                    size: const Size(double.infinity, 120),
                    painter: BubblePainter(
                      animationValue: _bubbleController.value,
                      color: widget.color,
                    ),
                  );
                },
              ),
              // Content overlay
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.science, size: 32, color: Colors.white.withOpacity(0.9)),
                      const SizedBox(height: 4),
                      Text(
                        'pH',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'SF Pro Display',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.value,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'SF Pro Display',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TurbidityAnimatedCard extends StatefulWidget {
  final String value;
  final Color color;
  final VoidCallback onTap;

  const _TurbidityAnimatedCard({
    required this.value,
    required this.color,
    required this.onTap,
  });

  @override
  State<_TurbidityAnimatedCard> createState() => _TurbidityAnimatedCardState();
}

class _TurbidityAnimatedCardState extends State<_TurbidityAnimatedCard>
    with TickerProviderStateMixin {
  late AnimationController _particleController;

  @override
  void initState() {
    super.initState();
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: widget.color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Colored background
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.color.withOpacity(0.8),
                      widget.color.withOpacity(0.4),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              // Particles animation
              AnimatedBuilder(
                animation: _particleController,
                builder: (context, child) {
                  return CustomPaint(
                    size: const Size(double.infinity, 120),
                    painter: ParticlePainter(
                      animationValue: _particleController.value,
                      color: widget.color,
                    ),
                  );
                },
              ),
              // Content overlay
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.opacity, size: 32, color: Colors.white.withOpacity(0.9)),
                      const SizedBox(height: 4),
                      Text(
                        'Turbidity',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'SF Pro Display',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.value,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'SF Pro Display',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TemperatureAnimatedCard extends StatefulWidget {
  final String value;
  final Color color;
  final VoidCallback onTap;

  const _TemperatureAnimatedCard({
    required this.value,
    required this.color,
    required this.onTap,
  });

  @override
  State<_TemperatureAnimatedCard> createState() => _TemperatureAnimatedCardState();
}

class _TemperatureAnimatedCardState extends State<_TemperatureAnimatedCard>
    with TickerProviderStateMixin {
  late AnimationController _heatController;

  @override
  void initState() {
    super.initState();
    _heatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _heatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: widget.color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Colored background
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.color.withOpacity(0.8),
                      widget.color.withOpacity(0.4),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              // Heat waves animation
              AnimatedBuilder(
                animation: _heatController,
                builder: (context, child) {
                  return CustomPaint(
                    size: const Size(double.infinity, 120),
                    painter: HeatWavePainter(
                      animationValue: _heatController.value,
                      color: widget.color,
                    ),
                  );
                },
              ),
              // Content overlay
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.thermostat, size: 32, color: Colors.white.withOpacity(0.9)),
                      const SizedBox(height: 4),
                      Text(
                        'Temperature',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'SF Pro Display',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.value,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'SF Pro Display',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HeatWavePainter extends CustomPainter {
  final double animationValue;
  final Color color;

  HeatWavePainter({required this.animationValue, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final heatPaint = Paint()
      ..color = color.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    // Draw rising heat particles - single animation
    for (int i = 0; i < 12; i++) {
      final delay = i * 0.08;
      final progress = (animationValue + delay) % 1.0;

      // Heat particles rise from bottom
      final x = 20 + (i * 25) % (size.width - 40);
      final y = size.height - (progress * size.height * 0.7);
      final radius = 2 + sin(progress * pi * 2) * 1.5;

      // Add some horizontal drift
      final driftX = x + sin(progress * 3 * pi + i) * 8;

      canvas.drawCircle(Offset(driftX, y), radius, heatPaint);

      // Add heat distortion lines
      if (i % 3 == 0) {
        final linePaint = Paint()
          ..color = color.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;

        final linePath = Path();
        linePath.moveTo(driftX - 5, y);
        for (int j = 0; j < 10; j++) {
          final lineX = driftX - 5 + j * 1;
          final lineY = y + sin((j / 10) * pi * 2 + progress * 4 * pi) * 3;
          linePath.lineTo(lineX, lineY);
        }
        canvas.drawPath(linePath, linePaint);
      }
    }
  }

  @override
  bool shouldRepaint(HeatWavePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue || oldDelegate.color != color;
  }
}

class ChemicalPainter extends CustomPainter {
  final double animationValue;
  final Color color;

  ChemicalPainter({required this.animationValue, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.4)
      ..style = PaintingStyle.fill;

    // Draw chemical reaction bubbles
    for (int i = 0; i < 6; i++) {
      final delay = i * 0.15;
      final progress = (animationValue + delay) % 1.0;
      final x = 15.0 + i * 12;
      final y = size.height - progress * size.height * 0.8;
      final radius = 3 + i * 0.8;

      canvas.drawCircle(Offset(x, y), radius, paint);
    }

    // Draw molecular structures
    final moleculePaint = Paint()
      ..color = color.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (int i = 0; i < 3; i++) {
      final centerX = size.width * 0.7 + i * 20;
      final centerY = size.height * 0.3 + sin(animationValue * 2 * pi + i) * 10;

      // Draw central atom
      canvas.drawCircle(Offset(centerX, centerY), 2, moleculePaint);

      // Draw bonds
      for (int j = 0; j < 4; j++) {
        final angle = j * pi / 2 + animationValue * pi;
        final endX = centerX + cos(angle) * 8;
        final endY = centerY + sin(angle) * 8;
        canvas.drawLine(Offset(centerX, centerY), Offset(endX, endY), moleculePaint);
      }
    }
  }

  @override
  bool shouldRepaint(ChemicalPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue || oldDelegate.color != color;
  }
}

class SanitizePainter extends CustomPainter {
  final double animationValue;
  final Color color;

  SanitizePainter({required this.animationValue, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw cleaning waves - single animation
    final wavePaint = Paint()
      ..color = color.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    for (int i = 0; i < 3; i++) {
      final path = Path();
      final waveOffset = i * 25;
      final waveProgress = (animationValue + i * 0.2) % 1.0;

      path.moveTo(0, size.height * 0.6 + waveOffset);

      // Create wave pattern
      for (double x = 0; x <= size.width; x += 4) {
        final normalizedX = x / size.width;
        final waveY = size.height * 0.6 + waveOffset +
            sin((normalizedX * 3 * pi) + (waveProgress * 2 * pi)) * 12 +
            cos((normalizedX * 2 * pi) + (waveProgress * pi)) * 6;
        path.lineTo(x, waveY);
      }

      canvas.drawPath(path, wavePaint);
    }
  }

  @override
  bool shouldRepaint(SanitizePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue || oldDelegate.color != color;
  }
}

class _ChlorineAnimatedCard extends StatefulWidget {
  final String value;
  final Color color;
  final VoidCallback onTap;

  const _ChlorineAnimatedCard({
    required this.value,
    required this.color,
    required this.onTap,
  });

  @override
  State<_ChlorineAnimatedCard> createState() => _ChlorineAnimatedCardState();
}

class _ChlorineAnimatedCardState extends State<_ChlorineAnimatedCard>
    with TickerProviderStateMixin {
  late AnimationController _chemicalController;

  @override
  void initState() {
    super.initState();
    _chemicalController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _chemicalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: widget.color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Colored background
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.color.withOpacity(0.8),
                      widget.color.withOpacity(0.4),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              // Chemical reaction animation
              AnimatedBuilder(
                animation: _chemicalController,
                builder: (context, child) {
                  return CustomPaint(
                    size: const Size(double.infinity, 120),
                    painter: SanitizePainter(
                      animationValue: _chemicalController.value,
                      color: widget.color,
                    ),
                  );
                },
              ),
              // Content overlay
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.sanitizer, size: 32, color: Colors.white.withOpacity(0.9)),
                      const SizedBox(height: 4),
                      Text(
                        'Chlorine',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'SF Pro Display',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.value,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'SF Pro Display',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
