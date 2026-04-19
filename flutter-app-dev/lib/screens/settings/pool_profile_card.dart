import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/device_provider.dart';
import '../../models/device.dart';

class PoolProfileCard extends StatefulWidget {
  final VoidCallback onEdit;

  const PoolProfileCard({Key? key, required this.onEdit}) : super(key: key);

  @override
  State<PoolProfileCard> createState() => _PoolProfileCardState();
}

class _PoolProfileCardState extends State<PoolProfileCard> {
  bool _isExpanded = true;
  bool _isEditing = false;

  late TextEditingController _poolNameController;
  late TextEditingController _poolTypeController;
  late TextEditingController _poolVolumeController;
  late TextEditingController _usageLevelController;
  late TextEditingController _operatingHoursController;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
    final cfg = deviceProvider.deviceConfig;
    final calibration = cfg?.calibration ?? {};

    _poolNameController =
        TextEditingController(text: calibration['pool_name'] as String? ?? '');
    _poolTypeController = TextEditingController(
        text: calibration['pool_type'] as String? ?? 'Residential');
    _poolVolumeController = TextEditingController(
        text: (calibration['pool_volume_liters'] as num?)?.toString() ?? '');
    _usageLevelController =
        TextEditingController(text: calibration['usage_level'] as String? ?? '');
    _operatingHoursController = TextEditingController(
        text: (calibration['operating_hours'] as num?)?.toString() ?? '');
  }

  @override
  void dispose() {
    _poolNameController.dispose();
    _poolTypeController.dispose();
    _poolVolumeController.dispose();
    _usageLevelController.dispose();
    _operatingHoursController.dispose();
    super.dispose();
  }

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
                          color: const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.pool,
                            color: Color(0xFF1976D2), size: 24),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pool Profile',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _isEditing ? 'Editing...' : 'Manage pool information',
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
                  _buildField('Pool Name', _poolNameController),
                  const SizedBox(height: 12),
                  _buildField(
                    'Pool Type',
                    _poolTypeController,
                    isDropdown: true,
                    items: ['Residential', 'Hotel', 'Public'],
                  ),
                  const SizedBox(height: 12),
                  _buildField('Pool Volume (Liters)', _poolVolumeController,
                      keyboardType: TextInputType.number),
                  const SizedBox(height: 12),
                  _buildField('Usage Level', _usageLevelController),
                  const SizedBox(height: 12),
                  _buildField('Operating Hours', _operatingHoursController,
                      keyboardType: TextInputType.number),
                  const SizedBox(height: 16),
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
                        onPressed: _isEditing ? _saveChanges : _enterEditMode,
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

  Widget _buildField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    bool isDropdown = false,
    List<String> items = const [],
  }) {
    if (isDropdown) {
      return DropdownButtonFormField<String>(
        value: controller.text.isEmpty ? items.first : controller.text,
        items: items
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: _isEditing
            ? (value) => controller.text = value ?? ''
            : null,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: !_isEditing,
          fillColor: !_isEditing ? Colors.grey[100] : Colors.white,
        ),
      );
    }

    return TextField(
      controller: controller,
      enabled: _isEditing,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: !_isEditing,
        fillColor: !_isEditing ? Colors.grey[100] : Colors.white,
      ),
    );
  }

  void _enterEditMode() {
    setState(() => _isEditing = true);
  }

  Future<void> _saveChanges() async {
    try {
      final deviceProvider =
          Provider.of<DeviceProvider>(context, listen: false);
      final device = deviceProvider.selectedDevice;

      if (device == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No device selected')),
        );
        return;
      }

      // Create updated config
      final cfg = deviceProvider.deviceConfig ??
          DeviceConfig(calibration: {}, thresholds: {}, intervals: {});
      final calibration = Map<String, dynamic>.from(cfg.calibration ?? {});

      calibration['pool_name'] = _poolNameController.text;
      calibration['pool_type'] = _poolTypeController.text;
      calibration['pool_volume_liters'] =
          int.tryParse(_poolVolumeController.text) ?? 0;
      calibration['usage_level'] = _usageLevelController.text;
      calibration['operating_hours'] =
          int.tryParse(_operatingHoursController.text) ?? 0;

      // Save to backend (TODO: implement actual API call)
      // await deviceProvider.updateDeviceConfig(device.deviceId, calibration);

      setState(() => _isEditing = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pool profile updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      widget.onEdit();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}
