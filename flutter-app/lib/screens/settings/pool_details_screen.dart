import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/device_provider.dart';
import '../../models/device.dart';

class PoolDetailsScreen extends StatefulWidget {
  const PoolDetailsScreen({Key? key}) : super(key: key);

  @override
  State<PoolDetailsScreen> createState() => _PoolDetailsScreenState();
}

class _PoolDetailsScreenState extends State<PoolDetailsScreen> {
  final _name = TextEditingController();
  final _length = TextEditingController();
  final _width = TextEditingController();
  final _depth = TextEditingController();
  final _volume = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final prov = Provider.of<DeviceProvider>(context, listen: false);
    final cfg = prov.deviceConfig;
    if (cfg == null) return;
    final c = cfg.calibration ?? {};
    _name.text = (c['pool_name'] as String?) ?? '';
    _length.text = (c['pool_length_m']?.toString()) ?? '';
    _width.text = (c['pool_width_m']?.toString()) ?? '';
    _depth.text = (c['pool_depth_m']?.toString()) ?? '';
    _volume.text = (c['pool_volume_liters']?.toString()) ?? '';
  }

  @override
  void dispose() {
    _name.dispose();
    _length.dispose();
    _width.dispose();
    _depth.dispose();
    _volume.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pool Details')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Pool Name')),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: TextFormField(controller: _length, decoration: const InputDecoration(labelText: 'Length (m)'), keyboardType: TextInputType.number)),
              const SizedBox(width: 8),
              Expanded(child: TextFormField(controller: _width, decoration: const InputDecoration(labelText: 'Width (m)'), keyboardType: TextInputType.number)),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: TextFormField(controller: _depth, decoration: const InputDecoration(labelText: 'Avg Depth (m)'), keyboardType: TextInputType.number)),
              const SizedBox(width: 8),
              Expanded(child: TextFormField(controller: _volume, decoration: const InputDecoration(labelText: 'Volume (L)'), keyboardType: TextInputType.number)),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              ElevatedButton.icon(onPressed: _calculate, icon: const Icon(Icons.calculate), label: const Text('Calc')),
              const SizedBox(width: 12),
              ElevatedButton.icon(onPressed: _save, icon: const Icon(Icons.save), label: const Text('Save')),
            ])
          ],
        ),
      ),
    );
  }

  void _calculate() {
    final l = double.tryParse(_length.text) ?? 0;
    final w = double.tryParse(_width.text) ?? 0;
    final d = double.tryParse(_depth.text) ?? 0;
    if (l > 0 && w > 0 && d > 0) {
      final liters = (l * w * d) * 1000;
      _volume.text = liters.round().toString();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Volume: ${liters.round()} L')));
    }
  }

  Future<void> _save() async {
    final prov = Provider.of<DeviceProvider>(context, listen: false);
    final dev = prov.selectedDevice;
    if (dev == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No device selected')));
      return;
    }
    final cfg = prov.deviceConfig ?? DeviceConfig(calibration: {}, thresholds: {}, intervals: {});
    final cal = Map<String, dynamic>.from(cfg.calibration ?? {});
    cal['pool_name'] = _name.text;
    cal['pool_length_m'] = double.tryParse(_length.text) ?? 0;
    cal['pool_width_m'] = double.tryParse(_width.text) ?? 0;
    cal['pool_depth_m'] = double.tryParse(_depth.text) ?? 0;
    cal['pool_volume_liters'] = double.tryParse(_volume.text) ?? 0;
    final newCfg = DeviceConfig(
      calibration: cal,
      thresholds: cfg.thresholds,
      intervals: cfg.intervals,
    );
    final ok = await prov.updateDeviceConfig(dev.deviceId, newCfg);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Saved' : 'Save failed')));
  }
}
