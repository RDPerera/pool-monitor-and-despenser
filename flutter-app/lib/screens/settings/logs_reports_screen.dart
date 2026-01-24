import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LogsReportsScreen extends StatefulWidget {
  const LogsReportsScreen({Key? key}) : super(key: key);

  @override
  State<LogsReportsScreen> createState() => _LogsReportsScreenState();
}

class _LogsReportsScreenState extends State<LogsReportsScreen> {
  String _selectedFilter = 'all';
  DateTime? _startDate;
  DateTime? _endDate;

  final List<Map<String, dynamic>> _logs = [
    {
      'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
      'type': 'calibration',
      'user': 'Admin User',
      'action': 'pH Sensor Calibrated',
      'details': 'Offset: +0.05',
    },
    {
      'timestamp': DateTime.now().subtract(const Duration(hours: 5)),
      'type': 'dispensing',
      'user': 'Technician',
      'action': 'Manual Dispense - Chlorine',
      'details': '50 mL dispensed',
    },
    {
      'timestamp': DateTime.now().subtract(const Duration(hours: 12)),
      'type': 'alert',
      'user': 'System',
      'action': 'pH Alert',
      'details': 'pH dropped to 6.2 (below minimum 6.5)',
    },
    {
      'timestamp': DateTime.now().subtract(const Duration(days: 1)),
      'type': 'settings',
      'user': 'Admin User',
      'action': 'Alert Thresholds Updated',
      'details': 'pH range: 6.5 - 8.0',
    },
    {
      'timestamp': DateTime.now().subtract(const Duration(days: 2)),
      'type': 'emergency',
      'user': 'Admin User',
      'action': 'Emergency Stop Activated',
      'details': 'All dispensing stopped',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Logs & Reports'),
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filters
            _buildFilterSection(),
            const SizedBox(height: 24),
            // Export Options
            _buildExportSection(),
            const SizedBox(height: 24),
            // Logs Table
            _buildLogsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filters',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            // Log Type Filter
            const Text(
              'Log Type',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('all', 'All Logs'),
                  _buildFilterChip('calibration', 'Calibration'),
                  _buildFilterChip('dispensing', 'Dispensing'),
                  _buildFilterChip('alert', 'Alerts'),
                  _buildFilterChip('settings', 'Settings'),
                  _buildFilterChip('emergency', 'Emergency'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Date Range
            const Text(
              'Date Range',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectStartDate(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            _startDate == null
                                ? 'Start Date'
                                : DateFormat('MM/dd/yyyy')
                                    .format(_startDate!),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectEndDate(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            _endDate == null
                                ? 'End Date'
                                : DateFormat('MM/dd/yyyy').format(_endDate!),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _selectedFilter = selected ? value : 'all');
        },
        backgroundColor: Colors.white,
        selectedColor: const Color(0xFF1976D2),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.grey[700],
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildExportSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Export Data',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _exportData('pdf'),
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Export to PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1976D2),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _exportData('csv'),
                    icon: const Icon(Icons.table_chart),
                    label: const Text('Export to CSV'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogsSection() {
    final filteredLogs = _selectedFilter == 'all'
        ? _logs
        : _logs
            .where((log) => log['type'] == _selectedFilter)
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Activity Logs',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${filteredLogs.length} entries',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...filteredLogs.map((log) => _buildLogEntry(log)).toList(),
      ],
    );
  }

  Widget _buildLogEntry(Map<String, dynamic> log) {
    final typeColor = _getTypeColor(log['type']);
    final typeIcon = _getTypeIcon(log['type']);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(typeIcon, color: typeColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          log['action'],
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          log['type'].toString().toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: typeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    log['details'] ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'By: ${log['user']}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                      Text(
                        DateFormat('MM/dd HH:mm').format(log['timestamp']),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'calibration':
        return Colors.blue;
      case 'dispensing':
        return Colors.green;
      case 'alert':
        return Colors.orange;
      case 'settings':
        return Colors.purple;
      case 'emergency':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'calibration':
        return Icons.tune;
      case 'dispensing':
        return Icons.opacity;
      case 'alert':
        return Icons.priority_high;
      case 'settings':
        return Icons.settings;
      case 'emergency':
        return Icons.emergency;
      default:
        return Icons.info;
    }
  }

  void _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  void _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  void _exportData(String format) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exporting data to $format...'),
        backgroundColor: Colors.green,
      ),
    );
    // TODO: Implement actual export functionality
  }
}
