import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dispensing_provider.dart';
import '../../providers/settings_provider.dart';
import '../../main.dart' show kBlue, kGreen, kOrange, kRed, kBg, kCardBg, kLabel, kLabel2, kLabel3, kSeparator;
import 'user_roles_screen.dart';
import 'logs_reports_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final Map<String, bool> _expanded = {
    'pool_profile':        false,
    'sensor_calibration':  false,
    'chemical_dispensing': false,
    'alert_thresholds':    false,
    'device':              false,
    'data_management':     false,
  };

  bool _editingProfile = false;
  late TextEditingController _poolNameCtrl;
  late TextEditingController _poolVolumeCtrl;
  late TextEditingController _poolLocationCtrl;
  String _poolTypeLocal   = 'Residential';
  String _usageLevelLocal = 'Medium';

  late TextEditingController _maxDoseCtrl;
  late TextEditingController _delayCtrl;
  late TextEditingController _safeHCLCtrl;
  late TextEditingController _safeSodaCtrl;
  late TextEditingController _safeCLCtrl;
  late TextEditingController _safeAlumCtrl;

  late TextEditingController _phMinCtrl;
  late TextEditingController _phMaxCtrl;
  late TextEditingController _clMinCtrl;
  late TextEditingController _clMaxCtrl;
  late TextEditingController _turbMinCtrl;
  late TextEditingController _turbMaxCtrl;
  late TextEditingController _tMinCtrl;
  late TextEditingController _tMaxCtrl;

  @override
  void initState() {
    super.initState();
    final s = context.read<SettingsProvider>();

    _poolNameCtrl     = TextEditingController(text: s.poolName);
    _poolVolumeCtrl   = TextEditingController(text: s.poolVolumeLiters.toStringAsFixed(0));
    _poolLocationCtrl = TextEditingController(text: s.poolLocation);
    _poolTypeLocal    = s.poolType;
    _usageLevelLocal  = s.usageLevel;

    _maxDoseCtrl  = TextEditingController(text: s.maxChemicalPerCycle.toStringAsFixed(0));
    _delayCtrl    = TextEditingController(text: s.autoCheckDelaySeconds.toString());
    _safeHCLCtrl  = TextEditingController(text: s.safetyLimitHCL.toStringAsFixed(0));
    _safeSodaCtrl = TextEditingController(text: s.safetyLimitSoda.toStringAsFixed(0));
    _safeCLCtrl   = TextEditingController(text: s.safetyLimitCL.toStringAsFixed(0));
    _safeAlumCtrl = TextEditingController(text: s.safetyLimitAlum.toStringAsFixed(0));

    _phMinCtrl   = TextEditingController(text: '7.2');
    _phMaxCtrl   = TextEditingController(text: '7.8');
    _clMinCtrl   = TextEditingController(text: '1.0');
    _clMaxCtrl   = TextEditingController(text: '3.0');
    _turbMinCtrl = TextEditingController(text: '0.0');
    _turbMaxCtrl = TextEditingController(text: '0.5');
    _tMinCtrl    = TextEditingController(text: '26.0');
    _tMaxCtrl    = TextEditingController(text: '30.0');
  }

  @override
  void dispose() {
    for (final c in [
      _poolNameCtrl, _poolVolumeCtrl, _poolLocationCtrl,
      _maxDoseCtrl, _delayCtrl,
      _safeHCLCtrl, _safeSodaCtrl, _safeCLCtrl, _safeAlumCtrl,
      _phMinCtrl, _phMaxCtrl, _clMinCtrl, _clMaxCtrl,
      _turbMinCtrl, _turbMaxCtrl, _tMinCtrl, _tMaxCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  bool _isAdmin(String role)       => role == 'admin';
  bool _canCalibrate(String role)  => role == 'admin' || role == 'technician';
  bool _canDispense(String role)   => role == 'admin' || role == 'maintenance';
  bool _canThresholds(String role) => role == 'admin' || role == 'technician';

  // ── Card helper ───────────────────────────────────────────────────────────

  Widget _card({required Widget child, EdgeInsets padding = const EdgeInsets.all(0),
      double radius = 16}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: padding,
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 20, offset: Offset(0, 2)),
          BoxShadow(color: Color(0x0F000000), blurRadius: 1,  offset: Offset(0, 1)),
        ],
      ),
      child: child,
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final auth       = context.watch<AuthProvider>();
    final settings   = context.watch<SettingsProvider>();
    final dispensing = context.watch<DispensingProvider>();
    final role       = auth.currentUser?.role ?? 'viewer';

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: kBg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 0,
            backgroundColor: Colors.transparent,
            flexibleSpace: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                child: Container(color: Colors.white.withOpacity(0.8)),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(0.5),
              child: Container(height: 0.5, color: kSeparator),
            ),
            automaticallyImplyLeading: false,
            title: const Text('Settings',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: kLabel)),
            actions: [
              if (_canDispense(role))
                GestureDetector(
                  onTap: () => _showEmergencyStopDialog(context, dispensing),
                  child: Container(
                    margin: const EdgeInsets.only(right: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: kRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.emergency_rounded, color: kRed, size: 14),
                      SizedBox(width: 4),
                      Text('STOP', style: TextStyle(color: kRed,
                          fontSize: 11, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                if (_canDispense(role)) _buildEmergencyBanner(dispensing),

                _sectionHeader('POOL'),
                _expandableCard(
                  key: 'pool_profile',
                  icon: Icons.pool_rounded, iconColor: kBlue,
                  title: 'Pool Profile',
                  subtitle: '${settings.poolName} · ${settings.poolType}',
                  child: _buildPoolProfileContent(role, settings),
                ),

                _sectionHeader('SENSORS'),
                _expandableCard(
                  key: 'sensor_calibration',
                  icon: Icons.tune_rounded, iconColor: const Color(0xFF8E8E93),
                  title: 'Sensor Calibration',
                  subtitle: 'pH · Turbidity · Temperature · Chlorine',
                  child: _buildSensorCalibration(role, settings),
                ),

                _sectionHeader('DISPENSING'),
                _expandableCard(
                  key: 'chemical_dispensing',
                  icon: Icons.opacity_rounded, iconColor: const Color(0xFF5AC8FA),
                  title: 'Chemical Dispensing',
                  subtitle: settings.autoDispensingEnabled ? 'Auto Mode: ON' : 'Auto Mode: OFF',
                  child: _buildDispensingContent(role, settings, dispensing),
                ),

                _sectionHeader('ALERTS'),
                _expandableCard(
                  key: 'alert_thresholds',
                  icon: Icons.notifications_active_rounded, iconColor: kOrange,
                  title: 'Alert Thresholds',
                  subtitle: 'pH 7.2–7.8 · Cl 1.0–3.0 · Turb 0–0.5',
                  child: _buildAlertThresholds(role),
                ),

                _sectionHeader('DEVICE'),
                _expandableCard(
                  key: 'device',
                  icon: Icons.router_rounded, iconColor: kGreen,
                  title: 'Device & Connectivity',
                  subtitle: 'Sensor Unit · Dispenser Unit',
                  child: _buildDeviceSection(),
                ),

                _sectionHeader('DATA'),
                _expandableCard(
                  key: 'data_management',
                  icon: Icons.storage_rounded, iconColor: const Color(0xFF5856D6),
                  title: 'Data Management',
                  subtitle: settings.dataLoggingEnabled ? 'Logging ON' : 'Logging OFF',
                  child: _buildDataManagement(role, settings),
                ),

                _sectionHeader('ACCOUNT'),
                _buildNavCard(role, auth),

                const SizedBox(height: 20),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ── Section header ────────────────────────────────────────────────────────

  Widget _sectionHeader(String label) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 20, 0, 8),
    child: Text(label, style: const TextStyle(
      fontSize: 11, fontWeight: FontWeight.w600,
      color: kLabel2, letterSpacing: 1.5,
    )),
  );

  // ── Expandable card ───────────────────────────────────────────────────────

  Widget _expandableCard({
    required String key,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    final isExp = _expanded[key] ?? false;
    return _card(
      child: Column(children: [
        InkWell(
          onTap: () => setState(() => _expanded[key] = !isExp),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              _iconBox(icon, iconColor),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: const TextStyle(fontSize: 15,
                      fontWeight: FontWeight.w600, color: kLabel)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: kLabel2)),
                ]),
              ),
              Icon(isExp ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  color: kLabel3, size: 22),
            ]),
          ),
        ),
        if (isExp) ...[
          Container(height: 0.5, color: kSeparator,
              margin: const EdgeInsets.symmetric(horizontal: 16)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: child,
          ),
        ],
      ]),
    );
  }

  Widget _iconBox(IconData icon, Color color) => Container(
    width: 40, height: 40,
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Icon(icon, color: color, size: 20),
  );

  // ── A. POOL PROFILE ───────────────────────────────────────────────────────

  Widget _buildPoolProfileContent(String role, SettingsProvider s) {
    final canEdit = _isAdmin(role);

    if (!_editingProfile) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _infoRow('Pool Name',   s.poolName),
        _divider(),
        _infoRow('Pool Type',   s.poolType),
        _divider(),
        _infoRow('Volume',      '${s.poolVolumeLiters.toStringAsFixed(0)} L'),
        _divider(),
        _infoRow('Location',    s.poolLocation.isEmpty ? '—' : s.poolLocation),
        _divider(),
        _infoRow('Usage Level', s.usageLevel),
        if (canEdit) ...[
          const SizedBox(height: 16),
          _primaryButton('Edit Pool Profile', Icons.edit_rounded, kBlue, () {
            _poolNameCtrl.text     = s.poolName;
            _poolVolumeCtrl.text   = s.poolVolumeLiters.toStringAsFixed(0);
            _poolLocationCtrl.text = s.poolLocation;
            _poolTypeLocal   = s.poolType;
            _usageLevelLocal = s.usageLevel;
            setState(() => _editingProfile = true);
          }),
        ] else
          _permissionChip('Admin role required to edit pool profile'),
      ]);
    }

    return Column(children: [
      _textField(_poolNameCtrl, 'Pool Name'),
      const SizedBox(height: 10),
      _dropdown('Pool Type', _poolTypeLocal,
          ['Residential', 'Commercial', 'Hotel', 'Public'],
          (v) => setState(() => _poolTypeLocal = v!)),
      const SizedBox(height: 10),
      _textField(_poolVolumeCtrl, 'Pool Volume (Liters)', isNumber: true),
      const SizedBox(height: 10),
      _dropdown('Usage Level', _usageLevelLocal, ['Low', 'Medium', 'High'],
          (v) => setState(() => _usageLevelLocal = v!)),
      const SizedBox(height: 10),
      _textField(_poolLocationCtrl, 'Location (optional)'),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(child: _ghostButton('Cancel', () => setState(() => _editingProfile = false))),
        const SizedBox(width: 10),
        Expanded(child: _primaryButton('Save', Icons.save_rounded, kBlue, () {
          context.read<SettingsProvider>().updatePoolProfile(
            name: _poolNameCtrl.text.trim(), type: _poolTypeLocal,
            volume: double.tryParse(_poolVolumeCtrl.text) ?? 50000,
            location: _poolLocationCtrl.text.trim(), usage: _usageLevelLocal,
          );
          setState(() => _editingProfile = false);
          _snack('Pool profile updated', kGreen);
        })),
      ]),
    ]);
  }

  // ── B. SENSOR CALIBRATION ─────────────────────────────────────────────────

  Widget _buildSensorCalibration(String role, SettingsProvider s) {
    final sensors = [
      (Icons.science_rounded,    kGreen,                   'pH Sensor',
          'Safe Range: 7.2 – 7.8', 'pH', null as String?),
      (Icons.water_rounded,      const Color(0xFF5AC8FA),  'Turbidity Sensor',
          'Safe Range: 0 – 0.5 NTU', 'Turbidity', null),
      (Icons.thermostat_rounded, kOrange,                  'Temperature Sensor',
          'Safe Range: 26 – 30 °C', 'Temperature', null),
      (Icons.opacity_rounded,    kBlue,                    'Chlorine (Estimated)',
          'Safe Range: 1 – 3 ppm', 'Chlorine',
          'Estimated from pH, Temperature & Turbidity'),
    ];

    return Column(
      children: sensors.asMap().entries.map((e) {
        final i = e.key;
        final (icon, color, name, range, sensorKey, note) = e.value;
        final lastCal = s.lastCalibrated[sensorKey];
        final calText = lastCal != null
            ? 'Last calibrated: ${_fmtDate(lastCal)}' : 'Not yet calibrated';

        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (i > 0) ...[_divider(), const SizedBox(height: 12)],
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: const TextStyle(fontSize: 14,
                    fontWeight: FontWeight.w600, color: kLabel)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: kGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(range, style: const TextStyle(fontSize: 11, color: kGreen,
                      fontWeight: FontWeight.w500)),
                ),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.check_circle_rounded, size: 12, color: kGreen),
                  const SizedBox(width: 4),
                  Text(calText, style: const TextStyle(fontSize: 11, color: kLabel2)),
                ]),
                if (note != null) ...[
                  const SizedBox(height: 4),
                  Text(note, style: const TextStyle(fontSize: 11, color: kLabel2,
                      fontStyle: FontStyle.italic)),
                ],
              ]),
            ),
            if (_canCalibrate(role)) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showCalibrationDialog(context, sensorKey),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Calibrate',
                      style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ]),
        ]);
      }).toList(),
    );
  }

  // ── C. CHEMICAL DISPENSING ────────────────────────────────────────────────

  Widget _buildDispensingContent(String role, SettingsProvider s, DispensingProvider d) {
    final canEdit = _isAdmin(role);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _toggleRow(
        icon: Icons.autorenew_rounded, color: kBlue,
        title: 'Auto Dispensing',
        subtitle: s.autoDispensingEnabled
            ? 'System manages chemicals automatically'
            : 'Manual mode only',
        value: s.autoDispensingEnabled,
        enabled: canEdit && !d.isEmergencyStopped,
        onChanged: (v) => _confirmAutoDispenseToggle(v, s, d),
      ),
      if (d.isEmergencyStopped) ...[
        const SizedBox(height: 8),
        _warningChip('Emergency Stop is active – cannot enable auto mode'),
      ],
      _divider(),
      const SizedBox(height: 2),
      _toggleRow(
        icon: Icons.touch_app_rounded, color: kOrange,
        title: 'Allow Manual Dispensing',
        subtitle: 'Controls manual trigger on Dispensing page',
        value: s.manualDispensingAllowed,
        enabled: canEdit,
        onChanged: canEdit ? (v) {
          context.read<SettingsProvider>().setManualDispensingAllowed(v);
          _snack(v ? 'Manual dispensing allowed' : 'Manual dispensing blocked', kOrange);
        } : null,
      ),

      if (canEdit) ...[
        const SizedBox(height: 16),
        const Text('Safety Limits & Timing',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kLabel)),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _textField(_maxDoseCtrl, 'Max dose/cycle (ml)', isNumber: true)),
          const SizedBox(width: 10),
          Expanded(child: _textField(_delayCtrl, 'Auto check delay (s)', isNumber: true)),
        ]),
        const SizedBox(height: 10),
        const Text('Per-Chemical Safety Limits (ml)',
            style: TextStyle(fontSize: 12, color: kLabel2)),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _textField(_safeHCLCtrl, 'HCl limit', isNumber: true)),
          const SizedBox(width: 8),
          Expanded(child: _textField(_safeSodaCtrl, 'Soda limit', isNumber: true)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _textField(_safeCLCtrl, 'Cl limit', isNumber: true)),
          const SizedBox(width: 8),
          Expanded(child: _textField(_safeAlumCtrl, 'Alum limit', isNumber: true)),
        ]),
        const SizedBox(height: 14),
        _primaryButton('Save Dispensing Settings', Icons.save_rounded, kBlue, () {
          context.read<SettingsProvider>().updateDispensingSettings(
            maxPerCycle:  double.tryParse(_maxDoseCtrl.text) ?? 500,
            delaySeconds: int.tryParse(_delayCtrl.text) ?? 300,
            safeHCL:  double.tryParse(_safeHCLCtrl.text) ?? 200,
            safeSoda: double.tryParse(_safeSodaCtrl.text) ?? 200,
            safeCL:   double.tryParse(_safeCLCtrl.text) ?? 300,
            safeAlum: double.tryParse(_safeAlumCtrl.text) ?? 150,
          );
          _snack('Dispensing settings saved', kGreen);
        }),
      ],
    ]);
  }

  Widget _toggleRow({
    required IconData icon, required Color color,
    required String title, required String subtitle,
    required bool value, required bool enabled,
    required ValueChanged<bool>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 14,
              fontWeight: FontWeight.w600, color: kLabel)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: kLabel2)),
        ])),
        Switch(
          value: value,
          activeColor: color,
          onChanged: enabled ? onChanged : null,
        ),
      ]),
    );
  }

  void _confirmAutoDispenseToggle(bool val, SettingsProvider s, DispensingProvider d) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(val ? 'Enable Auto Dispensing' : 'Disable Auto Dispensing',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: kLabel)),
        content: Text(
          val
              ? 'The system will automatically dispense chemicals when sensor readings go outside safe ranges.'
              : 'Chemicals will NOT be dispensed automatically. You will need to manage dispensing manually.',
          style: const TextStyle(fontSize: 14, color: kLabel2, height: 1.5),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel', style: TextStyle(color: kLabel2))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(val ? 'Enable' : 'Disable',
                style: TextStyle(color: val ? kGreen : kOrange,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        context.read<SettingsProvider>().setAutoDispensing(val);
        context.read<DispensingProvider>().toggleAutoDispensing(val);
        _snack(val ? 'Auto dispensing enabled' : 'Auto dispensing disabled',
            val ? kGreen : kOrange);
      }
    });
  }

  // ── D. ALERT THRESHOLDS ───────────────────────────────────────────────────

  Widget _buildAlertThresholds(String role) {
    final canEdit = _canThresholds(role);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (!canEdit) _warningChip('Read-only – requires Admin or Technician role'),

      _thresholdBlock(icon: Icons.science_rounded, color: kGreen,
          label: 'pH', note: null,
          minCtrl: _phMinCtrl, maxCtrl: _phMaxCtrl, enabled: canEdit),
      _divider(),

      _thresholdBlock(icon: Icons.water_rounded, color: const Color(0xFF5AC8FA),
          label: 'Turbidity (NTU)', note: null,
          minCtrl: _turbMinCtrl, maxCtrl: _turbMaxCtrl, enabled: canEdit),
      _divider(),

      _thresholdBlock(icon: Icons.thermostat_rounded, color: kOrange,
          label: 'Temperature (°C)', note: null,
          minCtrl: _tMinCtrl, maxCtrl: _tMaxCtrl, enabled: canEdit),
      _divider(),

      _thresholdBlock(icon: Icons.opacity_rounded, color: kBlue,
          label: 'Chlorine – Estimated (ppm)',
          note: 'Based on pH, Temperature & Turbidity',
          minCtrl: _clMinCtrl, maxCtrl: _clMaxCtrl, enabled: canEdit),

      if (canEdit) ...[
        const SizedBox(height: 16),
        _primaryButton('Save Thresholds', Icons.save_rounded, kBlue, () {
          context.read<SettingsProvider>().updateAlertThresholds(
            phLow:    double.tryParse(_phMinCtrl.text),
            phHigh:   double.tryParse(_phMaxCtrl.text),
            clLow:    double.tryParse(_clMinCtrl.text),
            clHigh:   double.tryParse(_clMaxCtrl.text),
            turbHigh: double.tryParse(_turbMaxCtrl.text),
            tLow:     double.tryParse(_tMinCtrl.text),
            tHigh:    double.tryParse(_tMaxCtrl.text),
          );
          _snack('Alert thresholds saved', kGreen);
        }),
      ],
    ]);
  }

  Widget _thresholdBlock({
    required IconData icon, required Color color,
    required String label, required String? note,
    required TextEditingController minCtrl, required TextEditingController maxCtrl,
    required bool enabled,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 13,
              fontWeight: FontWeight.w500, color: kLabel)),
          if (note != null) ...[
            const SizedBox(height: 2),
            Text(note, style: const TextStyle(fontSize: 11, color: kLabel2,
                fontStyle: FontStyle.italic)),
          ],
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _textField(minCtrl, 'Min', isNumber: true, enabled: enabled)),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('–', style: TextStyle(color: kLabel2)),
            ),
            Expanded(child: _textField(maxCtrl, 'Max', isNumber: true, enabled: enabled)),
          ]),
        ])),
      ]),
    );
  }

  // ── E. DEVICE ─────────────────────────────────────────────────────────────

  Widget _buildDeviceSection() {
    return Column(children: [
      _deviceCard(
        name: 'Sensor Monitor Unit', deviceId: 'POOL-MONITOR-001',
        status: 'Connected', firmware: 'v1.2.4', lastSync: 'Just now',
        statusColor: kGreen, icon: Icons.sensors_rounded, iconColor: kGreen,
      ),
      const SizedBox(height: 10),
      _deviceCard(
        name: 'Chemical Dispenser Unit', deviceId: 'POOL-DISPENSER-001',
        status: 'Connected', firmware: 'v2.0.1', lastSync: '2 min ago',
        statusColor: kGreen, icon: Icons.opacity_rounded, iconColor: kBlue,
      ),
      const SizedBox(height: 14),
      _primaryButton('Reconnect All Devices', Icons.refresh_rounded, kGreen,
          () => _snack('Reconnecting…', kGreen)),
    ]);
  }

  Widget _deviceCard({
    required String name, required String deviceId, required String status,
    required String firmware, required String lastSync,
    required Color statusColor, required IconData icon, required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 36, height: 36,
            decoration: BoxDecoration(color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: iconColor, size: 18)),
          const SizedBox(width: 10),
          Expanded(child: Text(name, style: const TextStyle(fontSize: 13,
              fontWeight: FontWeight.w600, color: kLabel))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 5, height: 5,
                  decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Text(status, style: TextStyle(fontSize: 10, color: statusColor,
                  fontWeight: FontWeight.w600)),
            ]),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _mini('Device ID', deviceId)),
          Expanded(child: _mini('Firmware', firmware)),
          Expanded(child: _mini('Last Sync', lastSync)),
        ]),
      ]),
    );
  }

  Widget _mini(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 9, color: kLabel2)),
      Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: kLabel)),
    ],
  );

  // ── F. DATA MANAGEMENT ────────────────────────────────────────────────────

  Widget _buildDataManagement(String role, SettingsProvider s) {
    final canEdit = _isAdmin(role);
    return Column(children: [
      _toggleRow(
        icon: Icons.storage_rounded, color: const Color(0xFF5856D6),
        title: 'Data Logging',
        subtitle: 'Store sensor readings for history',
        value: s.dataLoggingEnabled,
        enabled: canEdit,
        onChanged: canEdit ? (v) => context.read<SettingsProvider>().setDataLogging(v) : null,
      ),
      _divider(),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          const Text('Data refresh interval',
              style: TextStyle(fontSize: 13, color: kLabel)),
          const Spacer(),
          DropdownButton<int>(
            value: s.dataRefreshIntervalSeconds,
            underline: const SizedBox(),
            dropdownColor: kCardBg,
            style: const TextStyle(fontSize: 13, color: kLabel),
            items: [10, 30, 60, 120, 300]
                .map((v) => DropdownMenuItem(value: v, child: Text('${v}s')))
                .toList(),
            onChanged: canEdit
                ? (v) => context.read<SettingsProvider>().setDataRefreshInterval(v!)
                : null,
          ),
        ]),
      ),
      if (canEdit) ...[
        const SizedBox(height: 8),
        _primaryButton('Clear All History', Icons.delete_forever_rounded, kRed,
            () => _showClearDataDialog(context)),
      ],
    ]);
  }

  // ── G. NAV CARD ───────────────────────────────────────────────────────────

  Widget _buildNavCard(String role, AuthProvider auth) {
    return _card(
      child: Column(children: [
        if (_isAdmin(role)) ...[
          _navTile(icon: Icons.people_rounded, color: kBlue,
              title: 'User Roles & Permissions',
              subtitle: 'Manage users and access levels',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const UserRolesScreen()))),
          Container(height: 0.5, color: kSeparator,
              margin: const EdgeInsets.only(left: 70)),
        ],
        _navTile(icon: Icons.history_rounded, color: const Color(0xFF8E8E93),
            title: 'Data Logs & Reports',
            subtitle: 'View sensor history and dispensing logs',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const LogsReportsScreen()))),
        Container(height: 0.5, color: kSeparator,
            margin: const EdgeInsets.only(left: 70)),
        _navTile(icon: Icons.person_add_rounded, color: kBlue,
            title: 'Add Account',
            subtitle: 'Link another user or device account',
            onTap: () => Navigator.pushNamed(context, '/register')),
        Container(height: 0.5, color: kSeparator,
            margin: const EdgeInsets.only(left: 70)),
        _navTile(icon: Icons.logout_rounded, color: kRed,
            title: 'Sign Out',
            subtitle: 'Sign out of your account',
            onTap: () => _showSignOutDialog(context, auth)),
      ]),
    );
  }

  Widget _navTile({
    required IconData icon, required Color color,
    required String title, required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Container(width: 40, height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 14,
                fontWeight: FontWeight.w600, color: kLabel)),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(fontSize: 11, color: kLabel2)),
          ])),
          const Icon(Icons.chevron_right_rounded, color: kLabel3, size: 18),
        ]),
      ),
    );
  }

  // ── Emergency banner ──────────────────────────────────────────────────────

  Widget _buildEmergencyBanner(DispensingProvider d) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kRed.withOpacity(d.isEmergencyStopped ? 0.08 : 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kRed.withOpacity(0.25)),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 20, offset: Offset(0, 2)),
        ],
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: kRed.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.emergency_share_rounded, color: kRed, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Emergency Stop', style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w700, color: kLabel)),
          const SizedBox(height: 2),
          Text(
            d.isEmergencyStopped ? 'ACTIVE – All dispensing stopped'
                : 'Immediately stop all chemical dispensing',
            style: const TextStyle(fontSize: 12, color: kLabel2),
          ),
        ])),
        const SizedBox(width: 10),
        if (d.isEmergencyStopped)
          GestureDetector(
            onTap: () { d.resetEmergencyStop(); _snack('Emergency stop cleared', kGreen); },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: kGreen.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('Reset', style: TextStyle(color: kGreen,
                  fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          )
        else
          GestureDetector(
            onTap: () => _showEmergencyStopDialog(context, d),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: kRed.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('STOP', style: TextStyle(color: kRed,
                  fontSize: 12, fontWeight: FontWeight.w800)),
            ),
          ),
      ]),
    );
  }

  // ── Small UI helpers ──────────────────────────────────────────────────────

  Widget _divider() => Container(
    height: 0.5, color: kSeparator,
    margin: const EdgeInsets.symmetric(vertical: 8),
  );

  Widget _infoRow(String label, String value) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: const TextStyle(fontSize: 13, color: kLabel2)),
      Text(value, style: const TextStyle(fontSize: 13,
          fontWeight: FontWeight.w600, color: kLabel)),
    ],
  );

  Widget _textField(TextEditingController c, String label,
      {bool isNumber = false, bool enabled = true}) {
    return TextField(
      controller: c,
      enabled: enabled,
      style: const TextStyle(color: kLabel, fontSize: 14),
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  Widget _dropdown(String label, String value, List<String> items,
      ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: kCardBg,
      style: const TextStyle(color: kLabel, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _primaryButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 17),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _ghostButton(String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: kLabel2,
          side: const BorderSide(color: kSeparator),
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(label),
      ),
    );
  }

  Widget _warningChip(String text) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: kOrange.withOpacity(0.08),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(children: [
      const Icon(Icons.lock_rounded, size: 13, color: kOrange),
      const SizedBox(width: 6),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: kOrange))),
    ]),
  );

  Widget _permissionChip(String text) => Container(
    margin: const EdgeInsets.only(top: 10),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: kBlue.withOpacity(0.08),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(children: [
      const Icon(Icons.info_outline_rounded, size: 14, color: kBlue),
      const SizedBox(width: 6),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: kBlue))),
    ]),
  );

  String _fmtDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  void _snack(String msg, Color bg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg), backgroundColor: bg,
        duration: const Duration(seconds: 2)));
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────

  void _showEmergencyStopDialog(BuildContext ctx, DispensingProvider d) {
    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: kCardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.emergency_rounded, color: kRed, size: 24),
          SizedBox(width: 10),
          Text('Emergency Stop', style: TextStyle(fontSize: 17,
              fontWeight: FontWeight.w700, color: kLabel)),
        ]),
        content: const Text('This will IMMEDIATELY stop ALL chemical dispensing.',
            style: TextStyle(fontSize: 14, color: kLabel2, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: kLabel2)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await d.emergencyStop();
              if (ok) context.read<SettingsProvider>().setAutoDispensing(false);
              _snack(ok ? 'EMERGENCY STOP ACTIVATED' : 'Failed – check connection',
                  ok ? kRed : kOrange);
            },
            child: const Text('STOP ALL', style: TextStyle(color: kRed,
                fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  void _showCalibrationDialog(BuildContext ctx, String sensor) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: kCardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Calibrate $sensor Sensor',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: kLabel)),
        content: const Text(
            'Prepare the calibration solution, immerse the sensor, wait 30 seconds for a stable reading, then confirm below.',
            style: TextStyle(fontSize: 14, color: kLabel2, height: 1.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: kLabel2))),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<SettingsProvider>().markCalibrated(sensor);
              _snack('$sensor sensor calibrated', kGreen);
            },
            child: const Text('Calibrate', style: TextStyle(color: kBlue,
                fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog(BuildContext ctx, AuthProvider auth) {
    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: kCardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out', style: TextStyle(fontSize: 17,
            fontWeight: FontWeight.w700, color: kLabel)),
        content: const Text('Are you sure you want to sign out of your account?',
            style: TextStyle(fontSize: 14, color: kLabel2, height: 1.5)),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel', style: TextStyle(color: kLabel2))),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await auth.logout();
              if (!mounted) return;
              Navigator.pushNamedAndRemoveUntil(context, '/signed-out', (_) => false);
            },
            child: const Text('Sign Out', style: TextStyle(color: kRed,
                fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: kCardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear All History', style: TextStyle(fontSize: 17,
            fontWeight: FontWeight.w700, color: kLabel)),
        content: const Text(
            'This will permanently delete all stored settings and preferences. This cannot be undone.',
            style: TextStyle(fontSize: 14, color: kLabel2, height: 1.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: kLabel2))),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<SettingsProvider>().clearAllData();
              _snack('All local data cleared', kRed);
            },
            child: const Text('Clear', style: TextStyle(color: kRed,
                fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
