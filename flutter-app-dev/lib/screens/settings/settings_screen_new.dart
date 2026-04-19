import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_logo.dart';
import 'user_roles_screen.dart';
import 'logs_reports_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Expanded state for each section
  final Map<String, bool> _expandedSections = {
    'pool_profile': false,
    'sensor_calibration': false,
    'chemical_dispensing': false,
    'alert_thresholds': false,
  };

  // Pool Profile Edit State
  bool _isEditingProfile = false;
  final _poolNameController = TextEditingController(text: 'Main Pool');
  String _poolType = 'Residential';
  final _poolVolumeController = TextEditingController(text: '50000');
  String _usageLevel = 'Medium';
  final _operatingHoursController = TextEditingController(text: '8:00 AM - 8:00 PM');

  // Auto Dispense Settings
  bool _autoDispenseEnabled = true;
  final RangeValues _targetPHRange = const RangeValues(7.2, 7.6);
  final RangeValues _targetChlorineRange = const RangeValues(1.0, 3.0);
  final _maxDoseController = TextEditingController(text: '500');

  // Alert Thresholds - Simplified
  String _pHAlertLevel = 'Normal'; // Options: Normal, Strict, Relaxed
  String _chlorineAlertLevel = 'Normal';
  String _temperatureAlertLevel = 'Normal';
  final bool _sensorFailureAlerts = true;

  @override
  void dispose() {
    _poolNameController.dispose();
    _poolVolumeController.dispose();
    _operatingHoursController.dispose();
    _maxDoseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userRole = authProvider.currentUser?.role ?? 'viewer';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Settings'),
        leading: const Padding(
          padding: EdgeInsets.only(left: 12),
          child: AppLogo(
            size: 32,
            useWhiteBackground: true,
            backgroundColor: Color(0xFF1E88E5), // Theme color background
          ),
        ),
        actions: [
          if (userRole == 'admin')
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: const Icon(Icons.emergency, color: Colors.red, size: 28),
                onPressed: () => _showEmergencyStopDialog(context),
                tooltip: 'Emergency Stop',
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 8),
            if (userRole == 'admin') _buildEmergencyStopBanner(),
            _buildExpandableCard(
              key: 'pool_profile',
              icon: Icons.pool,
              iconColor: const Color(0xFF1976D2),
              title: 'Pool Profile',
              subtitle: '${_poolNameController.text} • $_poolType',
              canEdit: userRole == 'admin',
              content: _buildPoolProfileContent(userRole == 'admin'),
            ),
            _buildExpandableCard(
              key: 'sensor_calibration',
              icon: Icons.tune,
              iconColor: const Color(0xFF607D8B),
              title: 'Sensor Calibration',
              subtitle: 'pH, Chlorine, Temp, ORP',
              canEdit: userRole == 'admin' || userRole == 'technician',
              content: _buildSensorCalibrationContent(
                userRole == 'admin' || userRole == 'technician',
              ),
            ),
            _buildExpandableCard(
              key: 'chemical_dispensing',
              icon: Icons.opacity,
              iconColor: const Color(0xFF1565C0),
              title: 'Chemical Dispensing',
              subtitle: _autoDispenseEnabled ? 'Auto Mode: ON' : 'Auto Mode: OFF',
              canEdit: userRole == 'admin',
              content: _buildChemicalDispensingContent(userRole == 'admin'),
            ),
            _buildExpandableCard(
              key: 'alert_thresholds',
              icon: Icons.priority_high,
              iconColor: const Color(0xFFEF6C00),
              title: 'Alert Thresholds',
              subtitle: 'Warning sensitivity levels',
              canEdit: userRole == 'admin',
              content: _buildAlertThresholdsContent(userRole == 'admin'),
            ),
            const SizedBox(height: 16),
            _buildNavigationSection(userRole),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyStopBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade200, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.emergency_share, color: Colors.red.shade700, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Emergency Stop',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Immediately stop all chemical dispensing',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _showEmergencyStopDialog(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('STOP', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableCard({
    required String key,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool canEdit,
    required Widget content,
  }) {
    final isExpanded = _expandedSections[key] ?? false;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _expandedSections[key] = !isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: iconColor, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: content,
            ),
        ],
      ),
    );
  }

  Widget _buildPoolProfileContent(bool canEdit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          label: 'Pool Name',
          controller: _poolNameController,
          enabled: _isEditingProfile && canEdit,
        ),
        const SizedBox(height: 16),
        _buildDropdownField(
          label: 'Pool Type',
          value: _poolType,
          items: ['Residential', 'Commercial', 'Public'],
          onChanged: canEdit && _isEditingProfile
              ? (value) => setState(() => _poolType = value!)
              : null,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          label: 'Pool Volume (Liters)',
          controller: _poolVolumeController,
          enabled: _isEditingProfile && canEdit,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        _buildDropdownField(
          label: 'Usage Level',
          value: _usageLevel,
          items: ['Low', 'Medium', 'High'],
          onChanged: canEdit && _isEditingProfile
              ? (value) => setState(() => _usageLevel = value!)
              : null,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          label: 'Operating Hours',
          controller: _operatingHoursController,
          enabled: _isEditingProfile && canEdit,
        ),
        if (canEdit) ...[
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (_isEditingProfile)
                TextButton(
                  onPressed: () => setState(() => _isEditingProfile = false),
                  child: const Text('Cancel'),
                ),
              if (_isEditingProfile) const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isEditingProfile = !_isEditingProfile;
                  });
                  if (!_isEditingProfile) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Pool profile updated successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isEditingProfile ? Colors.green : const Color(0xFF1976D2),
                  foregroundColor: Colors.white,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_isEditingProfile ? Icons.save : Icons.edit, size: 18),
                    const SizedBox(width: 6),
                    Text(_isEditingProfile ? 'Save' : 'Edit'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSensorCalibrationContent(bool canEdit) {
    return Column(
      children: [
        _buildSensorCalibrationRow('pH Sensor', '7.4', 'Optimal', canEdit),
        const Divider(height: 24),
        _buildSensorCalibrationRow('Chlorine Sensor', '2.1 ppm', 'Optimal', canEdit),
        const Divider(height: 24),
        _buildSensorCalibrationRow('Temperature Sensor', '28°C', 'Optimal', canEdit),
        const Divider(height: 24),
        _buildSensorCalibrationRow('ORP Sensor', '685 mV', 'Optimal', canEdit),
      ],
    );
  }

  Widget _buildSensorCalibrationRow(
    String name,
    String value,
    String status,
    bool canEdit,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Current: $value',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Status: $status',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (canEdit)
          ElevatedButton(
            onPressed: () => _showCalibrationDialog(context, name),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF607D8B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('Calibrate'),
          ),
      ],
    );
  }

  Widget _buildChemicalDispensingContent(bool canEdit) {
    return Column(
      children: [
        SwitchListTile(
          title: const Text(
            'Auto Dispense Mode',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: const Text('Automatically dispense chemicals'),
          value: _autoDispenseEnabled,
          onChanged: canEdit
              ? (value) {
                  setState(() => _autoDispenseEnabled = value);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Auto dispense ${value ? "enabled" : "disabled"}',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              : null,
          activeColor: const Color(0xFF1565C0),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Target Ranges',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1976D2),
                ),
              ),
              const SizedBox(height: 8),
              _buildInfoRow('pH Range', '${_targetPHRange.start.toStringAsFixed(1)} - ${_targetPHRange.end.toStringAsFixed(1)}'),
              const SizedBox(height: 4),
              _buildInfoRow('Chlorine Range', '${_targetChlorineRange.start.toStringAsFixed(1)} - ${_targetChlorineRange.end.toStringAsFixed(1)} ppm'),
              const SizedBox(height: 4),
              _buildInfoRow('Max Dose', '${_maxDoseController.text} ml'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (canEdit)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showManualDispenseDialog(context),
              icon: const Icon(Icons.water_drop),
              label: const Text('Manual Dispense'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF6C00),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAlertThresholdsContent(bool canEdit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Set the sensitivity level for each parameter',
          style: TextStyle(
            fontSize: 13,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 16),
        _buildThresholdDropdown(
          label: 'pH Alert Level',
          value: _pHAlertLevel,
          icon: Icons.science,
          iconColor: const Color(0xFF1976D2),
          onChanged: canEdit
              ? (value) => setState(() => _pHAlertLevel = value!)
              : null,
        ),
        const SizedBox(height: 12),
        _buildThresholdDropdown(
          label: 'Chlorine Alert Level',
          value: _chlorineAlertLevel,
          icon: Icons.water_drop,
          iconColor: const Color(0xFF00ACC1),
          onChanged: canEdit
              ? (value) => setState(() => _chlorineAlertLevel = value!)
              : null,
        ),
        const SizedBox(height: 12),
        _buildThresholdDropdown(
          label: 'Temperature Alert Level',
          value: _temperatureAlertLevel,
          icon: Icons.thermostat,
          iconColor: const Color(0xFFF4511E),
          onChanged: canEdit
              ? (value) => setState(() => _temperatureAlertLevel = value!)
              : null,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.sensors, color: Colors.grey[700], size: 20),
              const SizedBox(width: 12),
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
                value: _sensorFailureAlerts,
                onChanged: null, // Always enabled (critical alerts)
                activeColor: Colors.grey,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Color(0xFF1976D2), size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Sensor failure alerts cannot be disabled',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[900],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (canEdit) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Alert thresholds updated successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              icon: const Icon(Icons.save),
              label: const Text('Save Changes'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildThresholdDropdown({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
    required ValueChanged<String?>? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          DropdownButton<String>(
            value: value,
            underline: Container(),
            items: ['Strict', 'Normal', 'Relaxed'].map((level) {
              return DropdownMenuItem(
                value: level,
                child: Text(level),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationSection(String userRole) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'MANAGEMENT',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // User Roles - Now visible to all users but with different access
              _buildNavigationTile(
                icon: Icons.people,
                iconColor: const Color(0xFF1976D2),
                title: userRole == 'admin' ? 'User Roles' : 'View Users',
                subtitle: userRole == 'admin' 
                    ? 'Manage users and permissions'
                    : 'View team members and roles',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UserRolesScreen(),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              _buildNavigationTile(
                icon: Icons.history,
                iconColor: const Color(0xFF607D8B),
                title: 'Data Logs & Reports',
                subtitle: 'View sensor history and dispensing logs',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LogsReportsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required bool enabled,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey[100],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?>? onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: onChanged != null ? Colors.white : Colors.grey[100],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  void _showEmergencyStopDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.emergency, color: Colors.red.shade700, size: 32),
            const SizedBox(width: 12),
            const Text('Emergency Stop'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This will immediately stop ALL chemical dispensing operations.',
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 16),
            const Text(
              'A critical alert will be sent to all users.',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Hold the STOP button for 3 seconds to confirm',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _confirmEmergencyStop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('STOP'),
          ),
        ],
      ),
    );
  }

  void _confirmEmergencyStop(BuildContext context) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('EMERGENCY STOP ACTIVATED - All dispensing stopped'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 5),
      ),
    );
  }

  void _showCalibrationDialog(BuildContext context, String sensorName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Calibrate $sensorName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Follow the calibration procedure for $sensorName:'),
            const SizedBox(height: 12),
            const Text('1. Prepare calibration solution'),
            const Text('2. Immerse sensor'),
            const Text('3. Wait for reading to stabilize'),
            const Text('4. Click "Calibrate" below'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Note: Dispensing is disabled during calibration',
                style: TextStyle(fontSize: 13, color: Colors.orange),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$sensorName calibration successful')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF607D8B),
              foregroundColor: Colors.white,
            ),
            child: const Text('Calibrate'),
          ),
        ],
      ),
    );
  }

  void _showManualDispenseDialog(BuildContext context) {
    String selectedChemical = 'pH Increaser';
    final doseController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manual Chemical Dispense'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedChemical,
                  decoration: const InputDecoration(
                    labelText: 'Chemical Type',
                    border: OutlineInputBorder(),
                  ),
                  items: ['pH Increaser', 'pH Decreaser', 'Chlorine', 'Shock Treatment'].map((chem) {
                    return DropdownMenuItem(value: chem, child: Text(chem));
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedChemical = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: doseController,
                  decoration: const InputDecoration(
                    labelText: 'Dose (ml)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Safety: Confirm the dose before proceeding',
                    style: TextStyle(fontSize: 13, color: Colors.orange),
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Dispensing ${doseController.text}ml of $selectedChemical'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF6C00),
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm & Dispense'),
          ),
        ],
      ),
    );
  }
}
