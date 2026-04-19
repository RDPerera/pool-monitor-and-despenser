import 'package:flutter/material.dart';

class ChemicalDispensingCard extends StatefulWidget {
  const ChemicalDispensingCard({Key? key}) : super(key: key);

  @override
  State<ChemicalDispensingCard> createState() =>
      _ChemicalDispensingCardState();
}

class _ChemicalDispensingCardState extends State<ChemicalDispensingCard> {
  bool _isExpanded = false;
  bool _autoDispenseEnabled = false;

  // Auto Dispense Settings
  double _minPH = 6.8;
  double _maxPH = 7.6;
  double _minChlorine = 1.0;
  double _maxChlorine = 3.0;
  double _minORP = 600;
  double _maxORP = 750;
  double _maxDosePerCycle = 100;

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
                          color: const Color(0xFFBBDEFB),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.opacity,
                            color: Color(0xFF1565C0), size: 24),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Chemical Dispensing',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Auto & manual dosage control',
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
                  // Auto Dispense Section
                  _buildSectionTitle('Auto Dispense Mode'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Enable Auto Dispensing',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Switch(
                              value: _autoDispenseEnabled,
                              onChanged: (value) {
                                setState(() => _autoDispenseEnabled = value);
                              },
                              activeColor: Colors.green,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_autoDispenseEnabled) ...[
                          _buildRangeSlider('pH Range', _minPH, _maxPH, 6.0,
                              8.5, (min, max) {
                            setState(() {
                              _minPH = min;
                              _maxPH = max;
                            });
                          }),
                          const SizedBox(height: 12),
                          _buildRangeSlider(
                              'Chlorine Range (ppm)',
                              _minChlorine,
                              _maxChlorine,
                              0.0,
                              5.0,
                              (min, max) {
                            setState(() {
                              _minChlorine = min;
                              _maxChlorine = max;
                            });
                          }),
                          const SizedBox(height: 12),
                          _buildRangeSlider(
                              'ORP Range (mV)',
                              _minORP,
                              _maxORP,
                              500.0,
                              800.0,
                              (min, max) {
                            setState(() {
                              _minORP = min;
                              _maxORP = max;
                            });
                          }),
                          const SizedBox(height: 12),
                          _buildSlider(
                            'Max Dose Per Cycle (mL)',
                            _maxDosePerCycle,
                            10.0,
                            500.0,
                            (value) {
                              setState(() => _maxDosePerCycle = value);
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Manual Dispense Section
                  _buildSectionTitle('Manual Dispense'),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _showManualDispenseModal,
                      icon: const Icon(Icons.handyman),
                      label: const Text('Manually Dispense Chemical'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange[300]!),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning,
                            color: Color(0xFFEF6C00)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Manual dispense requires confirmation for safety.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange[900],
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1565C0),
      ),
    );
  }

  Widget _buildRangeSlider(
    String label,
    double minValue,
    double maxValue,
    double minBound,
    double maxBound,
    Function(double, double) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            children: [
              RangeSlider(
                values: RangeValues(minValue, maxValue),
                min: minBound,
                max: maxBound,
                onChanged: (values) {
                  onChanged(values.start, values.end);
                },
                activeColor: const Color(0xFF1565C0),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Min: ${minValue.toStringAsFixed(1)}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  Text(
                    'Max: ${maxValue.toStringAsFixed(1)}',
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSlider(
    String label,
    double value,
    double min,
    double max,
    Function(double) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            children: [
              Slider(
                value: value,
                min: min,
                max: max,
                onChanged: onChanged,
                activeColor: const Color(0xFF1565C0),
              ),
              Text(
                '${value.toStringAsFixed(1)} mL',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showManualDispenseModal() {
    String selectedChemical = 'Chlorine';
    final doseController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Manual Chemical Dispense',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Select Chemical Type',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedChemical,
                  items: ['Chlorine', 'pH Increaser', 'pH Decreaser', 'Alkalinity']
                      .map((item) =>
                          DropdownMenuItem(value: item, child: Text(item)))
                      .toList(),
                  onChanged: (value) {
                    setModalState(() => selectedChemical = value ?? '');
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Dose (mL)',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: doseController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    hintText: 'Enter dose amount',
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        _showConfirmationModal(
                          selectedChemical,
                          doseController.text,
                        );
                        Navigator.pop(context);
                      },
                      child: const Text('Confirm'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showConfirmationModal(String chemical, String dose) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Dispensing'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Chemical: $chemical'),
            Text('Dose: $dose mL'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[300]!),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning, color: Color(0xFFEF6C00)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This action will dispense chemicals. Ensure the system is ready.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Dispensing $dose mL of $chemical...'),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.pop(context);
              // TODO: Log event with timestamp and user ID
            },
            child: const Text('Dispense'),
          ),
        ],
      ),
    );
  }
}
