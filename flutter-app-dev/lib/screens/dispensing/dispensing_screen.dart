import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/device_provider.dart';
import '../../providers/dispensing_provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/dispensing_job.dart';
import '../../main.dart' show kBlue, kGreen, kOrange, kRed, kBg, kCardBg, kLabel, kLabel2, kLabel3, kSeparator;

class DispensingScreen extends StatefulWidget {
  const DispensingScreen({Key? key}) : super(key: key);
  @override
  State<DispensingScreen> createState() => _DispensingScreenState();
}

class _DispensingScreenState extends State<DispensingScreen> {
  final _clCtrl   = TextEditingController();
  final _sodaCtrl = TextEditingController();
  final _hclCtrl  = TextEditingController();
  final _alCtrl   = TextEditingController();

  DateTime? _schedDate;
  TimeOfDay? _schedTime;
  String _repeatMode = 'daily';

  bool _applied = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DispensingProvider>(context, listen: false).loadAll();
    });
  }

  @override
  void dispose() {
    _clCtrl.dispose(); _sodaCtrl.dispose(); _hclCtrl.dispose(); _alCtrl.dispose();
    super.dispose();
  }

  // ── Logic (unchanged) ─────────────────────────────────────────────────────

  Map<String, double> _computeSuggestions(DeviceProvider dp) {
    final r = dp.latestReading;
    if (r == null) return {'cl': 0, 'soda': 0, 'hcl': 0, 'al': 0};
    final chlorine = dp.estimateChlorineForReading(r);
    final quality  = dp.getWaterQualityStatus();
    double cl = 0, soda = 0, hcl = 0, al = 0;
    if (chlorine < 1.0)          cl   = 60;
    else if (chlorine < 1.5)     cl   = 30;
    else if (chlorine < 2.0)     cl   = 15;
    if (r.turbidity > 1500)      al   = 50;
    else if (r.turbidity > 1000) al   = 30;
    else if (r.turbidity > 700)  al   = 15;
    if (r.ph < 1500)             soda = 25;
    else if (r.ph > 2800)        hcl  = 20;
    else if (r.ph < 1800)        soda = 12;
    if (quality == 'Critical') {
      cl = (cl * 1.4).clamp(0, 100); soda = (soda * 1.3).clamp(0, 80);
      hcl = (hcl * 1.3).clamp(0, 80); al  = (al * 1.3).clamp(0, 80);
    }
    return {
      'cl':   double.parse(cl.toStringAsFixed(0)),
      'soda': double.parse(soda.toStringAsFixed(0)),
      'hcl':  double.parse(hcl.toStringAsFixed(0)),
      'al':   double.parse(al.toStringAsFixed(0)),
    };
  }

  void _applySuggestions(DeviceProvider dp) {
    final s = _computeSuggestions(dp);
    setState(() {
      _clCtrl.text   = s['cl']!   > 0 ? s['cl']!.toStringAsFixed(0)   : '';
      _sodaCtrl.text = s['soda']! > 0 ? s['soda']!.toStringAsFixed(0) : '';
      _hclCtrl.text  = s['hcl']!  > 0 ? s['hcl']!.toStringAsFixed(0)  : '';
      _alCtrl.text   = s['al']!   > 0 ? s['al']!.toStringAsFixed(0)   : '';
      _applied = true;
    });
  }

  List<Map<String, dynamic>> _reasons(DeviceProvider dp) {
    final r = dp.latestReading;
    if (r == null) return [];
    final chlorine = dp.estimateChlorineForReading(r);
    final quality  = dp.getWaterQualityStatus();
    return [
      {'label': 'Chlorine',  'value': '${chlorine.toStringAsFixed(1)} ppm',
       'ok': chlorine >= 1.5, 'icon': Icons.water_drop_outlined},
      {'label': 'Turbidity', 'value': r.turbidity.toStringAsFixed(0),
       'ok': r.turbidity <= 700,  'icon': Icons.opacity_outlined},
      {'label': 'Quality',   'value': quality,
       'ok': quality == 'Optimal', 'icon': Icons.verified_outlined},
    ];
  }

  Future<void> _confirmDispense(DispensingProvider p, SettingsProvider s) async {
    if (p.isEmergencyStopped) return;
    final cl   = double.tryParse(_clCtrl.text.trim())   ?? 0;
    final soda = double.tryParse(_sodaCtrl.text.trim()) ?? 0;
    final hcl  = double.tryParse(_hclCtrl.text.trim())  ?? 0;
    final al   = double.tryParse(_alCtrl.text.trim())   ?? 0;
    if (cl == 0 && soda == 0 && hcl == 0 && al == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter at least one amount'))); return;
    }
    if (cl   > s.safetyLimitCL)   { _safetySnack('Chlorine', s.safetyLimitCL);   return; }
    if (soda > s.safetyLimitSoda) { _safetySnack('Soda',     s.safetyLimitSoda); return; }
    if (hcl  > s.safetyLimitHCL)  { _safetySnack('HCl',      s.safetyLimitHCL);  return; }
    if (al   > s.safetyLimitAlum) { _safetySnack('Alum',     s.safetyLimitAlum); return; }

    final ok = await showDialog<bool>(context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: kCardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Confirm Dispense',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: kLabel)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            if (cl   > 0) _dRow('Chlorine',     cl,   kBlue),
            if (soda > 0) _dRow('pH Increaser', soda, kGreen),
            if (hcl  > 0) _dRow('pH Decreaser', hcl,  kOrange),
            if (al   > 0) _dRow('Alkalinity',   al,   const Color(0xFFAF52DE)),
            const SizedBox(height: 10),
            Container(padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: kOrange.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8)),
              child: const Text('Verify amounts before proceeding.',
                  style: TextStyle(fontSize: 12, color: kOrange))),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel', style: TextStyle(color: kLabel2))),
            TextButton(onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Dispense', style: TextStyle(color: kBlue,
                    fontWeight: FontWeight.w600))),
          ],
        ));
    if (ok == true) {
      final success = await p.dispenseAllManual(cl: cl, soda: soda, hcl: hcl, al: al);
      if (mounted) {
        if (success) {
          _clCtrl.clear(); _sodaCtrl.clear(); _hclCtrl.clear(); _alCtrl.clear();
          setState(() => _applied = false);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Dispense started'), backgroundColor: kGreen));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Error: ${p.error ?? "Failed"}'), backgroundColor: kRed));
        }
      }
    }
  }

  Widget _dRow(String name, double amount, Color c) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
      const SizedBox(width: 10),
      Text(name, style: const TextStyle(fontSize: 14, color: kLabel)),
      const Spacer(),
      Text('${amount.toStringAsFixed(0)} mL',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c)),
    ]),
  );

  void _safetySnack(String chem, double limit) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('$chem exceeds safety limit of ${limit.toStringAsFixed(0)} mL'),
        backgroundColor: kRed,
      ));

  void _toggleAuto(DispensingProvider p, SettingsProvider s, bool val) async {
    final ok = await showDialog<bool>(context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: kCardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(val ? 'Enable Auto Dispensing?' : 'Disable Auto Dispensing?',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: kLabel)),
          content: Text(val
              ? 'System will monitor sensors and dispense automatically.'
              : 'Auto dispensing will be stopped.',
              style: const TextStyle(color: kLabel2)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel', style: TextStyle(color: kLabel2))),
            TextButton(onPressed: () => Navigator.pop(ctx, true),
                child: Text('Confirm', style: TextStyle(
                    color: val ? kGreen : kRed, fontWeight: FontWeight.w600))),
          ],
        ));
    if (ok == true) { p.toggleAutoDispensing(val); s.setAutoDispensing(val); }
  }

  void _emergencyStop(DispensingProvider p, SettingsProvider s) async {
    final ok = await showDialog<bool>(context: context, barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: kCardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(children: [
            Icon(Icons.warning_rounded, color: kRed, size: 22),
            SizedBox(width: 8),
            Text('Emergency Stop', style: TextStyle(fontSize: 17,
                fontWeight: FontWeight.w600, color: kLabel)),
          ]),
          content: const Text(
              'Immediately stops ALL dispensing.\n\nAre you sure?',
              style: TextStyle(color: kLabel2)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel', style: TextStyle(color: kLabel2))),
            TextButton(onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Stop All',
                    style: TextStyle(color: kRed, fontWeight: FontWeight.w700))),
          ],
        ));
    if (ok == true) {
      await p.emergencyStop(); s.setAutoDispensing(false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Emergency stop — all dispensing halted'),
        backgroundColor: kRed, duration: Duration(seconds: 4),
      ));
    }
  }

  String _fmtDate(String ts) {
    try {
      var dt = DateTime.parse(ts);
      if (!dt.isUtc) dt = DateTime.utc(dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second);
      final local = dt.toLocal();
      final diff  = DateTime.now().difference(local);
      if (diff.inDays == 0) return 'Today ${DateFormat('h:mm a').format(local)}';
      if (diff.inDays == 1) return 'Yesterday ${DateFormat('h:mm a').format(local)}';
      return DateFormat('MMM d, h:mm a').format(local);
    } catch (_) { return ts; }
  }

  // ── Apple card ────────────────────────────────────────────────────────���───

  Widget _card({required Widget child,
      EdgeInsets padding = const EdgeInsets.all(20), double radius = 16}) {
    return Container(
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

  // ── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Consumer3<DispensingProvider, SettingsProvider, DeviceProvider>(
      builder: (context, provider, settings, deviceProvider, _) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (provider.isAutoDispensingEnabled != settings.autoDispensingEnabled &&
              !provider.isEmergencyStopped) {
            provider.toggleAutoDispensing(settings.autoDispensingEnabled);
          }
        });

        final isAutoOn = settings.autoDispensingEnabled;
        final blocked  = provider.isEmergencyStopped || !settings.manualDispensingAllowed;

        return Scaffold(
          backgroundColor: kBg,
          body: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Frosted glass nav bar
              SliverAppBar(
                pinned: true,
                expandedHeight: 0,
                toolbarHeight: 52,
                backgroundColor: Colors.transparent,
                flexibleSpace: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                    child: Container(
                      color: Colors.white.withOpacity(0.8),
                      alignment: Alignment.bottomLeft,
                      padding: EdgeInsets.only(
                        left: 16,
                        bottom: 12,
                        top: MediaQuery.of(context).padding.top,
                      ),
                      child: const Text('Dispense',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: kLabel)),
                    ),
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(0.5),
                  child: Container(height: 0.5, color: kSeparator),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([

                    // Auto toggle
                    _buildAutoToggle(provider, settings, isAutoOn),
                    const SizedBox(height: 12),

                    // Schedule (when auto on)
                    if (isAutoOn && !provider.isEmergencyStopped) ...[
                      _buildScheduleCard(),
                      const SizedBox(height: 12),
                    ],

                    // Smart recommendation
                    _buildRecommendation(deviceProvider),
                    const SizedBox(height: 12),

                    // Manual dose
                    _buildManualDose(provider, settings, blocked),
                    const SizedBox(height: 24),

                    // History label
                    const Padding(
                      padding: EdgeInsets.only(left: 4, bottom: 8),
                      child: Text('DISPENSING HISTORY',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                              color: kLabel2, letterSpacing: 0.5)),
                    ),
                    _buildHistory(provider),
                    const SizedBox(height: 24),

                    // Emergency stop
                    _buildEmergencyStop(provider, settings),
                    const SizedBox(height: 60),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Auto Toggle ───────────────────────────────────────────────────────────

  Widget _buildAutoToggle(DispensingProvider p, SettingsProvider s, bool isOn) {
    return _card(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: (isOn ? kGreen : const Color(0xFF8E8E93)).withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.smart_toy_outlined,
              color: isOn ? kGreen : const Color(0xFF8E8E93), size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Auto Dispensing',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: kLabel)),
          Text(isOn ? 'Monitoring sensors automatically' : 'Set amounts manually below',
              style: const TextStyle(fontSize: 12, color: kLabel2)),
        ])),
        Switch(
          value: isOn,
          onChanged: p.isEmergencyStopped ? null : (v) => _toggleAuto(p, s, v),
          activeColor: kGreen,
          thumbColor: MaterialStateProperty.resolveWith((_) => Colors.white),
        ),
      ]),
    );
  }

  // ── Schedule Card ─────────────────────────────────────────────────────────

  Widget _buildScheduleCard() {
    final dateStr = _schedDate == null ? 'Set date' : DateFormat('MMM d, y').format(_schedDate!);
    final timeStr = _schedTime == null ? 'Set time' : _schedTime!.format(context);

    return _card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.calendar_today_outlined, color: kGreen, size: 17),
          SizedBox(width: 8),
          Text('Auto Schedule', style: TextStyle(fontSize: 15,
              fontWeight: FontWeight.w600, color: kLabel)),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _pickerTile(
            icon: Icons.calendar_month_outlined, label: 'Date', value: dateStr,
            color: kBlue, set: _schedDate != null,
            onTap: () async {
              final d = await showDatePicker(context: context,
                  initialDate: _schedDate ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)));
              if (d != null) setState(() => _schedDate = d);
            },
          )),
          const SizedBox(width: 10),
          Expanded(child: _pickerTile(
            icon: Icons.access_time_rounded, label: 'Time', value: timeStr,
            color: kOrange, set: _schedTime != null,
            onTap: () async {
              final t = await showTimePicker(context: context,
                  initialTime: _schedTime ?? TimeOfDay.now());
              if (t != null) setState(() => _schedTime = t);
            },
          )),
        ]),
        const SizedBox(height: 14),
        Wrap(spacing: 8, runSpacing: 8, children: ['once', 'daily', 'weekly'].map((m) {
          final sel = _repeatMode == m;
          return GestureDetector(
            onTap: () => setState(() => _repeatMode = m),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: sel ? kGreen : kBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(m[0].toUpperCase() + m.substring(1),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                      color: sel ? Colors.white : kLabel2)),
            ),
          );
        }).toList()),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: (_schedDate != null && _schedTime != null)
                ? () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Schedule saved: $dateStr at $timeStr ($_repeatMode)'),
                    backgroundColor: kGreen)) : null,
            icon: const Icon(Icons.schedule_rounded, size: 17),
            label: const Text('Save Schedule', style: TextStyle(fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: kGreen, foregroundColor: Colors.white,
              disabledBackgroundColor: kBg,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ),
      ]),
    );
  }

  Widget _pickerTile({required IconData icon, required String label, required String value,
      required Color color, required bool set, required VoidCallback onTap}) =>
    GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: set ? color.withOpacity(0.07) : kBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 17, color: set ? color : const Color(0xFF8E8E93)),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 11, color: kLabel2)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
              color: set ? color : kLabel2)),
        ]),
      ),
    );

  // ── Smart Recommendation ──────────────────────────────────────────────────

  Widget _buildRecommendation(DeviceProvider dp) {
    final sugg    = _computeSuggestions(dp);
    final reasons = _reasons(dp);
    final hasSug  = sugg.values.any((v) => v > 0);

    return _card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: kBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.auto_fix_high_rounded, color: kBlue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Smart Recommendation',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: kLabel)),
            const Text('Based on current readings',
                style: TextStyle(fontSize: 12, color: kLabel2)),
          ])),
          if (_applied)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: kGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Applied', style: TextStyle(fontSize: 11,
                  fontWeight: FontWeight.w600, color: kGreen)),
            ),
        ]),
        const SizedBox(height: 14),

        // Sensor pills
        Wrap(spacing: 7, runSpacing: 7, children: reasons.map((r) {
          final ok = r['ok'] as bool;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: ok ? kGreen.withOpacity(0.08) : kOrange.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(r['icon'] as IconData, size: 11,
                  color: ok ? kGreen : kOrange),
              const SizedBox(width: 5),
              Text('${r['label']}: ${r['value']}', style: TextStyle(
                  fontSize: 11,
                  color: ok ? kGreen : kOrange,
                  fontWeight: ok ? FontWeight.normal : FontWeight.w600)),
            ]),
          );
        }).toList()),
        const SizedBox(height: 14),

        if (!hasSug)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: kGreen.withOpacity(0.07),
                borderRadius: BorderRadius.circular(12)),
            child: const Row(children: [
              Icon(Icons.check_circle_outline_rounded, color: kGreen, size: 17),
              SizedBox(width: 10),
              Text('Pool looks balanced — no dosing needed!',
                  style: TextStyle(fontSize: 13, color: kGreen)),
            ]),
          )
        else ...[
          Wrap(spacing: 7, runSpacing: 7, children: [
            if (sugg['cl']!   > 0) _sugChip('Chlorine',    '${sugg['cl']!.toStringAsFixed(0)} mL',   kBlue),
            if (sugg['soda']! > 0) _sugChip('pH Increaser', '${sugg['soda']!.toStringAsFixed(0)} mL', kGreen),
            if (sugg['hcl']!  > 0) _sugChip('pH Decreaser', '${sugg['hcl']!.toStringAsFixed(0)} mL',  kOrange),
            if (sugg['al']!   > 0) _sugChip('Alkalinity',   '${sugg['al']!.toStringAsFixed(0)} mL',   const Color(0xFFAF52DE)),
          ]),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _applySuggestions(dp),
              icon: const Icon(Icons.auto_fix_high_rounded, size: 17),
              label: const Text('Apply Suggestion',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: kBlue, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _sugChip(String name, String amount, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: c.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(name, style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w500)),
      const SizedBox(width: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(8)),
        child: Text(amount, style: const TextStyle(color: Colors.white, fontSize: 11,
            fontWeight: FontWeight.w700)),
      ),
    ]),
  );

  // ── Manual Dose ───────────────────────────────────────────────────────────

  Widget _buildManualDose(DispensingProvider p, SettingsProvider s, bool blocked) {
    return _card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 38, height: 38,
            decoration: BoxDecoration(color: kBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.science_outlined, color: kBlue, size: 20)),
          const SizedBox(width: 12),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Manual Dose', style: TextStyle(fontSize: 15,
                fontWeight: FontWeight.w600, color: kLabel)),
            Text('Enter amount per chemical', style: TextStyle(fontSize: 12, color: kLabel2)),
          ])),
          if (p.isAutoDispensingEnabled)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(color: kGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: const Text('Auto ON', style: TextStyle(color: kGreen, fontSize: 11,
                  fontWeight: FontWeight.w600)),
            ),
        ]),
        const SizedBox(height: 20),

        _chemRow(icon: Icons.water_drop_rounded,     label: 'Chlorine',     sub: 'Disinfectant', ctrl: _clCtrl,   color: kBlue,   disabled: blocked),
        const SizedBox(height: 10),
        _chemRow(icon: Icons.arrow_upward_rounded,   label: 'pH Increaser', sub: 'Soda Ash',     ctrl: _sodaCtrl, color: kGreen,  disabled: blocked),
        const SizedBox(height: 10),
        _chemRow(icon: Icons.arrow_downward_rounded, label: 'pH Decreaser', sub: 'HCl',          ctrl: _hclCtrl,  color: kOrange, disabled: blocked),
        const SizedBox(height: 10),
        _chemRow(icon: Icons.opacity_rounded,        label: 'Alkalinity',   sub: 'Alum',         ctrl: _alCtrl,   color: const Color(0xFFAF52DE), disabled: blocked),

        const SizedBox(height: 20),

        if (blocked)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: kRed.withOpacity(0.07),
                borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              const Icon(Icons.lock_outline_rounded, color: kRed, size: 16),
              const SizedBox(width: 10),
              Expanded(child: Text(
                p.isEmergencyStopped
                    ? 'System is in Emergency Stop state.'
                    : 'Manual dispensing is disabled in Settings.',
                style: const TextStyle(fontSize: 13, color: kRed))),
            ]),
          )
        else
          _buildDispenseButton(p, s),
      ]),
    );
  }

  Widget _buildDispenseButton(DispensingProvider p, SettingsProvider s) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _confirmDispense(p, s),
        icon: const Icon(Icons.water_drop_rounded, size: 18),
        label: const Text('Dispense Now',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: kBlue, foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _chemRow({required IconData icon, required String label, required String sub,
      required TextEditingController ctrl, required Color color, required bool disabled}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: kBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Container(width: 40, height: 40,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))]),
          child: Icon(icon, color: Colors.white, size: 20)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kLabel)),
          Text(sub, style: const TextStyle(fontSize: 11, color: kLabel2)),
        ])),
        const SizedBox(width: 12),
        SizedBox(
          width: 96,
          child: TextField(
            controller: ctrl,
            enabled: !disabled,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 16),
            decoration: InputDecoration(
              suffixText: 'mL',
              suffixStyle: TextStyle(color: color.withOpacity(0.5), fontSize: 11,
                  fontWeight: FontWeight.w500),
              hintText: '0',
              hintStyle: TextStyle(color: color.withOpacity(0.3), fontSize: 15),
              filled: true, fillColor: kCardBg,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: color.withOpacity(0.2))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: color.withOpacity(0.2))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: color, width: 1.5)),
            ),
          ),
        ),
      ]),
    );
  }

  // ── History ───────────────────────────────────────────────────────────────

  Widget _buildHistory(DispensingProvider p) {
    if (p.isLoading) return const Center(child: Padding(padding: EdgeInsets.all(24),
        child: CircularProgressIndicator(color: kBlue)));
    if (p.error != null) return _card(child: Column(children: [
      const Icon(Icons.wifi_off_rounded, size: 36, color: kLabel3),
      const SizedBox(height: 10),
      const Text('Could not load history', style: TextStyle(color: kLabel2)),
      const SizedBox(height: 12),
      TextButton(onPressed: p.loadAll, child: const Text('Retry')),
    ], mainAxisSize: MainAxisSize.min));
    if (p.dispensingHistory.isEmpty) return _card(
      padding: const EdgeInsets.all(24),
      child: const Center(child: Text('No dispensing history yet.',
          style: TextStyle(color: kLabel2))));

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: p.dispensingHistory.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _histCard(p.dispensingHistory[i]),
    );
  }

  Widget _histCard(DispensingJob job) {
    final isAuto  = job.flag.toLowerCase() == 'auto';
    final flagCol = isAuto ? kGreen : kBlue;
    return _card(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 34, height: 34,
            decoration: BoxDecoration(color: flagCol.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(isAuto ? Icons.smart_toy_outlined : Icons.pan_tool_outlined,
                color: flagCol, size: 16)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(job.flag.toUpperCase(),
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: flagCol)),
            Text(_fmtDate(job.timestamp),
                style: const TextStyle(fontSize: 11, color: kLabel2)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(color: kGreen.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20)),
            child: const Text('Done', style: TextStyle(fontSize: 10, color: kGreen,
                fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 10),
        Wrap(spacing: 6, runSpacing: 6, children: [
          if (job.cl   > 0) _chip('Cl',   job.cl,   kBlue),
          if (job.soda > 0) _chip('Soda', job.soda, kGreen),
          if (job.hcl  > 0) _chip('HCl',  job.hcl,  kOrange),
          if (job.al   > 0) _chip('Alum', job.al,   const Color(0xFFAF52DE)),
          if (job.cl == 0 && job.soda == 0 && job.hcl == 0 && job.al == 0)
            _chip('No data', 0, const Color(0xFF8E8E93)),
        ]),
      ]),
    );
  }

  Widget _chip(String label, double amount, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(color: c.withOpacity(0.08), borderRadius: BorderRadius.circular(20)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(label, style: TextStyle(fontSize: 11, color: c, fontWeight: FontWeight.w600)),
      if (amount > 0) ...[
        const SizedBox(width: 4),
        Text('${amount.toStringAsFixed(0)} mL',
            style: TextStyle(fontSize: 11, color: c.withOpacity(0.7))),
      ],
    ]),
  );

  // ── Emergency Stop ────────────────────────────────────────────────────────

  Widget _buildEmergencyStop(DispensingProvider p, SettingsProvider s) {
    return _card(
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        Container(width: 40, height: 40,
          decoration: BoxDecoration(color: kRed.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(Icons.warning_rounded,
              color: p.isEmergencyStopped ? kRed : kRed.withOpacity(0.7), size: 22)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Emergency Stop', style: TextStyle(fontSize: 14,
              fontWeight: FontWeight.w600, color: kRed)),
          Text(p.isEmergencyStopped ? 'ACTIVE — tap Reset to resume'
              : 'Halt all dispensing immediately',
              style: const TextStyle(fontSize: 12, color: kLabel2)),
        ])),
        const SizedBox(width: 10),
        p.isEmergencyStopped
            ? TextButton(
                onPressed: () {
                  p.resetEmergencyStop();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('System reset'), backgroundColor: kGreen));
                },
                style: TextButton.styleFrom(foregroundColor: kGreen),
                child: const Text('Reset', style: TextStyle(fontWeight: FontWeight.w600)))
            : ElevatedButton(
                onPressed: () => _emergencyStop(p, s),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kRed, foregroundColor: Colors.white, elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('STOP', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
      ]),
    );
  }
}
