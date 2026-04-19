import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class LogsReportsScreen extends StatefulWidget {
  const LogsReportsScreen({Key? key}) : super(key: key);

  @override
  State<LogsReportsScreen> createState() => _LogsReportsScreenState();
}

class _LogsReportsScreenState extends State<LogsReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  // ── Shared date range — affects BOTH tabs ─────────────────────────────────
  String _selectedFilter = 'all';
  DateTime? _startDate;
  DateTime? _endDate;

  bool _isGeneratingPDF = false;
  bool _isGeneratingCSV = false;

  final List<Map<String, dynamic>> _logs = [
    {
      'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
      'type': 'calibration',
      'user': 'Admin',
      'action': 'pH Sensor Calibrated',
      'details': 'Safe range confirmed: 7.2 – 7.8',
    },
    {
      'timestamp': DateTime.now().subtract(const Duration(hours: 5)),
      'type': 'dispensing',
      'user': 'Technician',
      'action': 'Manual Dispense – Chlorine',
      'details': '50 mL dispensed',
    },
    {
      'timestamp': DateTime.now().subtract(const Duration(hours: 12)),
      'type': 'alert',
      'user': 'System',
      'action': 'pH Alert Triggered',
      'details': 'pH dropped to 6.9 (below min 7.2)',
    },
    {
      'timestamp': DateTime.now().subtract(const Duration(days: 1)),
      'type': 'settings',
      'user': 'Admin',
      'action': 'Alert Thresholds Updated',
      'details': 'pH: 7.2–7.8, Cl: 1.0–3.0, Turb: 0–0.5, Temp: 26–30',
    },
    {
      'timestamp': DateTime.now().subtract(const Duration(days: 1, hours: 8)),
      'type': 'dispensing',
      'user': 'System',
      'action': 'Auto Dispense – pH Increaser',
      'details': '20 mL soda dispensed (auto mode)',
    },
    {
      'timestamp': DateTime.now().subtract(const Duration(days: 2)),
      'type': 'emergency',
      'user': 'Admin',
      'action': 'Emergency Stop Activated',
      'details': 'All dispensing stopped immediately',
    },
    {
      'timestamp': DateTime.now().subtract(const Duration(days: 3)),
      'type': 'alert',
      'user': 'System',
      'action': 'High Temperature Warning',
      'details': 'Temperature reached 31.5°C (above max 30°C)',
    },
    {
      'timestamp': DateTime.now().subtract(const Duration(days: 4)),
      'type': 'calibration',
      'user': 'Technician',
      'action': 'Temperature Sensor Calibrated',
      'details': 'Safe range confirmed: 26–30°C',
    },
    {
      'timestamp': DateTime.now().subtract(const Duration(days: 5)),
      'type': 'alert',
      'user': 'System',
      'action': 'Turbidity Alert',
      'details': 'Turbidity at 0.7 NTU (above max 0.5)',
    },
  ];

  final Map<String, Map<String, dynamic>> _sensorSummary = {
    'pH': {
      'avg': 7.45, 'min': 7.1, 'max': 7.9,
      'safeMin': 7.2, 'safeMax': 7.8, 'unit': '',
    },
    'Chlorine (Est.)': {
      'avg': 2.1, 'min': 0.9, 'max': 3.1,
      'safeMin': 1.0, 'safeMax': 3.0, 'unit': 'ppm',
    },
    'Temperature': {
      'avg': 27.8, 'min': 25.9, 'max': 31.5,
      'safeMin': 26.0, 'safeMax': 30.0, 'unit': '°C',
    },
    'Turbidity': {
      'avg': 0.3, 'min': 0.1, 'max': 0.7,
      'safeMin': 0.0, 'safeMax': 0.5, 'unit': 'NTU',
    },
  };

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  // ── Shared filtered logs — used by BOTH tabs ──────────────────────────────
  List<Map<String, dynamic>> get _filteredLogs {
    var logs = _selectedFilter == 'all'
        ? _logs
        : _logs.where((l) => l['type'] == _selectedFilter).toList();
    if (_startDate != null) {
      logs = logs
          .where((l) => (l['timestamp'] as DateTime).isAfter(_startDate!))
          .toList();
    }
    if (_endDate != null) {
      final end = _endDate!.add(const Duration(days: 1));
      logs = logs
          .where((l) => (l['timestamp'] as DateTime).isBefore(end))
          .toList();
    }
    return logs;
  }

  // Formatted date range string shown in the report tab
  String get _dateRangeLabel {
    if (_startDate == null && _endDate == null) {
      return 'Last 7 days (all data)';
    }
    final from = _startDate != null
        ? DateFormat('dd MMM yyyy').format(_startDate!)
        : 'Beginning';
    final to = _endDate != null
        ? DateFormat('dd MMM yyyy').format(_endDate!)
        : 'Today';
    return '$from → $to';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final role = auth.currentUser?.role ?? 'viewer';
    final canExport = role == 'admin' || role == 'maintenance';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text('Data Logs & Reports'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.history, size: 18), text: 'Activity Logs'),
            Tab(icon: Icon(Icons.bar_chart, size: 18), text: 'Summary Report'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildLogsTab(canExport),
          _buildReportTab(canExport),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Tab 1 – Activity Logs
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildLogsTab(bool canExport) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildFilterSection(),
          const SizedBox(height: 16),
          if (canExport) _buildExportSection(),
          if (canExport) const SizedBox(height: 16),
          _buildLogsList(),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filters',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            // Type chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip('all', 'All'),
                  _filterChip('dispensing', 'Dispensing'),
                  _filterChip('alert', 'Alerts'),
                  _filterChip('calibration', 'Calibration'),
                  _filterChip('settings', 'Settings'),
                  _filterChip('emergency', 'Emergency'),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // Date range pickers — shared with Summary tab
            Row(
              children: [
                Expanded(
                  child: _datePicker(
                    'Start Date', _startDate,
                    (d) => setState(() => _startDate = d),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _datePicker(
                    'End Date', _endDate,
                    (d) => setState(() => _endDate = d),
                  ),
                ),
              ],
            ),
            if (_startDate != null || _endDate != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.info_outline, size: 13, color: Colors.blue[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Date range also applied to Summary Report',
                    style: TextStyle(fontSize: 11, color: Colors.blue[600]),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () =>
                        setState(() { _startDate = null; _endDate = null; }),
                    icon: const Icon(Icons.clear, size: 13),
                    label: const Text('Clear', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: const EdgeInsets.symmetric(horizontal: 4)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String val, String label) {
    final sel = _selectedFilter == val;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label,
            style: TextStyle(
                fontSize: 12,
                color: sel ? Colors.white : Colors.grey[700])),
        selected: sel,
        selectedColor: const Color(0xFF1976D2),
        backgroundColor: Colors.grey[100],
        onSelected: (v) => setState(() => _selectedFilter = v ? val : 'all'),
      ),
    );
  }

  Widget _datePicker(
      String hint, DateTime? value, ValueChanged<DateTime> onPicked) {
    return InkWell(
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (d != null) onPicked(d);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          border: Border.all(
              color: value != null
                  ? const Color(0xFF1976D2)
                  : Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
          color: value != null
              ? const Color(0xFFE3F2FD)
              : null,
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 14,
                color: value != null ? const Color(0xFF1976D2) : Colors.grey),
            const SizedBox(width: 6),
            Text(
              value == null
                  ? hint
                  : DateFormat('dd/MM/yy').format(value),
              style: TextStyle(
                  fontSize: 12,
                  color: value == null
                      ? Colors.grey
                      : const Color(0xFF1565C0),
                  fontWeight: value != null ? FontWeight.w600 : FontWeight.normal),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportSection() {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Export Data',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isGeneratingPDF ? null : _generatePDF,
                    icon: _isGeneratingPDF
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.picture_as_pdf, size: 16),
                    label: Text(_isGeneratingPDF ? 'Generating...' : 'PDF Report'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1976D2),
                        foregroundColor: Colors.white),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isGeneratingCSV ? null : _exportCSV,
                    icon: _isGeneratingCSV
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.table_chart, size: 16),
                    label: Text(_isGeneratingCSV ? 'Exporting...' : 'Export CSV'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogsList() {
    final logs = _filteredLogs;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${logs.length} entries',
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            if (logs.isEmpty)
              Text('No logs match filters',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
        const SizedBox(height: 10),
        if (logs.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(children: [
                Icon(Icons.inbox, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text('No logs found',
                    style: TextStyle(color: Colors.grey[500])),
              ]),
            ),
          )
        else
          ...logs.map(_buildLogEntry),
      ],
    );
  }

  Widget _buildLogEntry(Map<String, dynamic> log) {
    final color = _typeColor(log['type'] as String);
    final icon  = _typeIcon(log['type'] as String);
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(log['action'] as String,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis),
                      ),
                      _typeBadge(log['type'] as String, color),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(log['details'] as String? ?? '',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('By: ${log['user']}',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey[500])),
                      Text(
                          DateFormat('dd/MM HH:mm')
                              .format(log['timestamp'] as DateTime),
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey[500])),
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

  Widget _typeBadge(String type, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4)),
    child: Text(type.toUpperCase(),
        style: TextStyle(
            fontSize: 9, fontWeight: FontWeight.bold, color: color)),
  );

  // ─────────────────────────────────────────────────────────────────────────
  // Tab 2 – Summary Report (uses same date range as Tab 1)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildReportTab(bool canExport) {
    final filtered    = _filteredLogs;
    final alerts      = filtered.where((l) => l['type'] == 'alert').length;
    final dispenses   = filtered.where((l) => l['type'] == 'dispensing').length;
    final emergencies = filtered.where((l) => l['type'] == 'emergency').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Active date range banner ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: (_startDate != null || _endDate != null)
                  ? const Color(0xFFE3F2FD)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: (_startDate != null || _endDate != null)
                    ? const Color(0xFF1976D2)
                    : Colors.grey.shade300,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.date_range,
                  size: 18,
                  color: (_startDate != null || _endDate != null)
                      ? const Color(0xFF1565C0)
                      : Colors.grey[600],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Report period',
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _dateRangeLabel,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: (_startDate != null || _endDate != null)
                              ? const Color(0xFF1565C0)
                              : Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_startDate != null || _endDate != null)
                  TextButton(
                    onPressed: () =>
                        setState(() { _startDate = null; _endDate = null; }),
                    style: TextButton.styleFrom(
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: const EdgeInsets.symmetric(horizontal: 8)),
                    child: const Text('Clear',
                        style: TextStyle(fontSize: 12, color: Color(0xFF1976D2))),
                  ),
                // Switch to Activity Logs to change date
                TextButton(
                  onPressed: () => _tabCtrl.animateTo(0),
                  style: TextButton.styleFrom(
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(horizontal: 8)),
                  child: Text(
                    'Change',
                    style: TextStyle(
                        fontSize: 12,
                        color: (_startDate != null || _endDate != null)
                            ? const Color(0xFF1976D2)
                            : Colors.grey[600]),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Sensor summary ─────────────────────────────────────────────────
          _sectionCard(
            title: 'Sensor Readings Summary',
            icon: Icons.sensors,
            color: const Color(0xFF00897B),
            child: Column(
              children: _sensorSummary.entries
                  .map((e) => _sensorSummaryRow(e.key, e.value))
                  .toList(),
            ),
          ),
          const SizedBox(height: 12),

          // ── Activity counts — from FILTERED logs ───────────────────────────
          _sectionCard(
            title: 'Activity Summary  (${filtered.length} records in period)',
            icon: Icons.analytics,
            color: const Color(0xFF7B1FA2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statTile(alerts.toString(), 'Alerts', Colors.orange),
                _statTile(dispenses.toString(), 'Dispenses', Colors.blue),
                _statTile(emergencies.toString(), 'Emergency', Colors.red),
                _statTile(
                    filtered
                        .where((l) => l['type'] == 'calibration')
                        .length
                        .toString(),
                    'Calibrations',
                    Colors.teal),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Configured thresholds ──────────────────────────────────────────
          _sectionCard(
            title: 'Configured Safe Thresholds',
            icon: Icons.rule,
            color: const Color(0xFFEF6C00),
            child: Column(
              children: [
                _threshRow(Icons.science, const Color(0xFF1976D2),
                    'pH', '7.2 – 7.8', null),
                const Divider(height: 16),
                _threshRow(Icons.water, const Color(0xFF00ACC1),
                    'Turbidity', '0 – 0.5 NTU', null),
                const Divider(height: 16),
                _threshRow(Icons.thermostat, const Color(0xFFF4511E),
                    'Temperature', '26 – 30 °C', null),
                const Divider(height: 16),
                _threshRow(Icons.opacity, const Color(0xFF388E3C),
                    'Chlorine (Estimated)', '1 – 3 ppm',
                    'Simulated · Based on pH, Temperature & Turbidity'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Export buttons ─────────────────────────────────────────────────
          if (canExport) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isGeneratingPDF ? null : _generatePDF,
                icon: _isGeneratingPDF
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.picture_as_pdf),
                label: Text(_isGeneratingPDF
                    ? 'Generating...'
                    : 'Download PDF Report'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isGeneratingCSV ? null : _exportCSV,
                icon: _isGeneratingCSV
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.table_chart),
                label: Text(
                    _isGeneratingCSV ? 'Exporting...' : 'Export CSV'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green,
                  side: const BorderSide(color: Colors.green),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ] else
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock, color: Colors.grey[600], size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'PDF / CSV export requires Admin or Maintenance role.',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Shared UI pieces
  // ─────────────────────────────────────────────────────────────────────────

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: color)),
              ),
            ]),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }

  Widget _sensorSummaryRow(String name, Map<String, dynamic> v) {
    final avg     = v['avg'] as double;
    final min     = v['min'] as double;
    final max     = v['max'] as double;
    final safeMin = v['safeMin'] as double;
    final safeMax = v['safeMax'] as double;
    final unit    = v['unit'] as String;
    final avgOk   = avg >= safeMin && avg <= safeMax;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(name,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _miniStat('Avg', '${avg.toStringAsFixed(1)}$unit',
                    avgOk ? Colors.green : Colors.red),
                _miniStat('Min', '${min.toStringAsFixed(1)}$unit', Colors.blue),
                _miniStat('Max', '${max.toStringAsFixed(1)}$unit', Colors.red),
                _miniStat('Safe', '$safeMin–$safeMax', Colors.grey),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) => Column(
    children: [
      Text(value,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.bold, color: color)),
      Text(label,
          style: TextStyle(fontSize: 10, color: Colors.grey[600])),
    ],
  );

  Widget _statTile(String value, String label, Color color) => Column(
    children: [
      Text(value,
          style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold, color: color)),
      const SizedBox(height: 3),
      Text(label,
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          textAlign: TextAlign.center),
    ],
  );

  Widget _threshRow(
    IconData icon,
    Color iconColor,
    String param,
    String range,
    String? note,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(param,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500)),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Text(range,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade800)),
                  ),
                ],
              ),
              if (note != null) ...[
                const SizedBox(height: 3),
                Text(note,
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Export
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _generatePDF() async {
    setState(() => _isGeneratingPDF = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _isGeneratingPDF = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'PDF report ready.\n'
          'Add "pdf: ^3.10.8" and "printing: ^5.12.0" to pubspec.yaml to enable real download.',
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 4),
      ),
    );
  }

  Future<void> _exportCSV() async {
    setState(() => _isGeneratingCSV = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _isGeneratingCSV = false);
    final header = 'Timestamp,Type,Action,Details,User\n';
    final rows   = _filteredLogs.map((l) {
      final ts = DateFormat('dd/MM/yyyy HH:mm').format(l['timestamp'] as DateTime);
      return '"$ts","${l['type']}","${l['action']}","${l['details']}","${l['user']}"';
    }).join('\n');
    debugPrint('$header$rows');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'CSV exported.\n'
          'Add "file_saver: ^0.2.14" to pubspec.yaml to save as a real file.',
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 4),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  Color _typeColor(String t) {
    switch (t) {
      case 'calibration': return Colors.blue;
      case 'dispensing':  return Colors.green;
      case 'alert':       return Colors.orange;
      case 'settings':    return Colors.purple;
      case 'emergency':   return Colors.red;
      default:            return Colors.grey;
    }
  }

  IconData _typeIcon(String t) {
    switch (t) {
      case 'calibration': return Icons.tune;
      case 'dispensing':  return Icons.opacity;
      case 'alert':       return Icons.priority_high;
      case 'settings':    return Icons.settings;
      case 'emergency':   return Icons.emergency;
      default:            return Icons.info;
    }
  }
}
