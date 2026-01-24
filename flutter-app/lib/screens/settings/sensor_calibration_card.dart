import 'package:flutter/material.dart';

class SensorCalibrationCard extends StatefulWidget {
  const SensorCalibrationCard({Key? key}) : super(key: key);

  @override
  State<SensorCalibrationCard> createState() =>
      _SensorCalibrationCardState();
}

class _SensorCalibrationCardState extends State<SensorCalibrationCard> {
  bool _isExpanded = false;

  String? _calibratingensor;
  final Map<String, String> _calibrationStatus = {
    'pH': 'Not Calibrated',
    'Chlorine': 'Calibrated',
    'Temperature': 'Calibrated',
    'ORP': 'Not Calibrated',
  };

  final Map<String, double> _sensorReadings = {
    'pH': 7.2,
    'Chlorine': 1.5,
    'Temperature': 25.0,
    'ORP': 650.0,
  };

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECEFF1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.tune,
                            color: Color(0xFF607D8B), size: 24),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Sensor Calibration',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Calibrate connected sensors',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
                ],
              ),
            ),
          ),
          // Expanded Content
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  ..._sensorReadings.keys.map((sensor) {
                    final status = _calibrationStatus[sensor];
                    final isCalibrating = _calibratingensor == sensor;
                    final reading = _sensorReadings[sensor];
                    final statusColor = status == 'Calibrated'
                        ? Colors.green
                        : Colors.orange;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  sensor,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Chip(
                                  label: Text(
                                    status ?? 'Unknown',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                    ),
                                  ),
                                  backgroundColor: statusColor,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Current Reading: ${reading?.toStringAsFixed(2) ?? 'N/A'} ${_getUnit(sensor)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: isCalibrating
                                    ? null
                                    : () => _calibrateSensor(sensor),
                                icon: isCalibrating
                                    ? SizedBox(
                                        width: 16,
                                        height: 16,
                                        child:
                                            CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<
                                                  Color>(
                                            Colors.blue[700]!,
                                          ),
                                        ),
                                      )
                                    : const Icon(Icons.refresh),
                                label: Text(isCalibrating
                                    ? 'Calibrating...'
                                    : 'Calibrate $sensor'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isCalibrating
                                      ? Colors.grey[400]
                                      : const Color(0xFF1976D2),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info, color: Color(0xFF1976D2)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Calibration is disabled when dispensing is in progress.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[900],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _calibrateSensor(String sensor) async {
    setState(() {
      _calibratingensor = sensor;
      // Calibration started
    });

    // Simulate calibration process
    await Future.delayed(const Duration(seconds: 3));

    setState(() {
      _calibrationStatus[sensor] = 'Calibrated';
      _calibratingensor = null;
      // Calibration completed
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$sensor sensor calibrated successfully!'),
        backgroundColor: Colors.green,
      ),
    );

    // TODO: Log calibration event with timestamp and user ID
  }

  String _getUnit(String sensor) {
    switch (sensor) {
      case 'pH':
        return 'pH';
      case 'Chlorine':
        return 'ppm';
      case 'Temperature':
        return '°C';
      case 'ORP':
        return 'mV';
      default:
        return '';
    }
  }
}
