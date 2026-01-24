import 'package:flutter/material.dart';

class AlertThresholdsCard extends StatefulWidget {
  final bool isAdmin;

  const AlertThresholdsCard({Key? key, required this.isAdmin})
      : super(key: key);

  @override
  State<AlertThresholdsCard> createState() =>
      _AlertThresholdsCardState();
}

class _AlertThresholdsCardState extends State<AlertThresholdsCard> {
  bool _isExpanded = false;
  bool _isEditing = false;

  // Thresholds
  double _phMin = 6.5;
  double _phMax = 8.0;
  double _chlorineMin = 0.5;
  double _chlorineMax = 5.0;
  double _tempMax = 35.0;
  bool _sensorFailureAlertsEnabled = true;

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
                          color: const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.priority_high,
                            color: Color(0xFFEF6C00), size: 24),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Alert Thresholds',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Set min/max warning levels',
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildThresholdField(
                    'pH Minimum',
                    _phMin,
                    (value) => setState(() => _phMin = value),
                    6.0,
                    9.0,
                  ),
                  const SizedBox(height: 16),
                  _buildThresholdField(
                    'pH Maximum',
                    _phMax,
                    (value) => setState(() => _phMax = value),
                    6.0,
                    9.0,
                  ),
                  const SizedBox(height: 16),
                  _buildThresholdField(
                    'Chlorine Minimum (ppm)',
                    _chlorineMin,
                    (value) => setState(() => _chlorineMin = value),
                    0.0,
                    5.0,
                  ),
                  const SizedBox(height: 16),
                  _buildThresholdField(
                    'Chlorine Maximum (ppm)',
                    _chlorineMax,
                    (value) => setState(() => _chlorineMax = value),
                    0.0,
                    5.0,
                  ),
                  const SizedBox(height: 16),
                  _buildThresholdField(
                    'Temperature Maximum (°C)',
                    _tempMax,
                    (value) => setState(() => _tempMax = value),
                    20.0,
                    50.0,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Sensor Failure Alerts',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Switch(
                          value: _sensorFailureAlertsEnabled,
                          onChanged: (value) {
                            setState(() =>
                                _sensorFailureAlertsEnabled = value);
                            _saveTreshold();
                          },
                          activeColor: Colors.green,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
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
                            'Critical alerts cannot be disabled. Changes are saved immediately and logged.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[900],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (widget.isAdmin)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (_isEditing)
                          ElevatedButton.icon(
                            onPressed: () => setState(() => _isEditing = false),
                            icon: const Icon(Icons.close),
                            label: const Text('Cancel'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[400],
                            ),
                          ),
                        if (_isEditing) const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _isEditing
                              ? _saveTreshold
                              : () => setState(() => _isEditing = true),
                          icon: Icon(_isEditing ? Icons.save : Icons.edit),
                          label: Text(_isEditing ? 'Save' : 'Edit'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isEditing
                                ? Colors.green
                                : const Color(0xFF1976D2),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildThresholdField(
    String label,
    double value,
    Function(double) onChanged,
    double min,
    double max,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                value.toStringAsFixed(2),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1976D2),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: value,
          min: min,
          max: max,
          onChanged: _isEditing ? onChanged : null,
          activeColor: const Color(0xFF1976D2),
        ),
      ],
    );
  }

  Future<void> _saveTreshold() async {
    setState(() => _isEditing = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Alert thresholds updated and logged!'),
        backgroundColor: Colors.green,
      ),
    );

    // TODO: Save thresholds to backend and log the event
  }
}
