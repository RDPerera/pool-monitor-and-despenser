import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Centralized settings state – shared between Settings Page & Dispensing Page.
/// Use Provider.of<SettingsProvider>(context) in both screens.
class SettingsProvider with ChangeNotifier {
  // ── Pool Profile ──────────────────────────────────────────────────────────
  String poolName        = 'Main Pool';
  String poolType        = 'Residential';
  double poolVolumeLiters = 50000;
  String poolLocation    = '';
  String usageLevel      = 'Medium';

  // ── Chemical Dispensing ───────────────────────────────────────────────────
  bool   autoDispensingEnabled  = false;
  double maxChemicalPerCycle    = 500;   // ml
  int    autoCheckDelaySeconds  = 300;   // 5 min
  bool   manualDispensingAllowed = true;

  // Safety limits
  double safetyLimitHCL  = 200;
  double safetyLimitSoda = 200;
  double safetyLimitCL   = 300;
  double safetyLimitAlum = 150;

  // ── Alert Thresholds ──────────────────────────────────────────────────────
  double phMin           = 7.0;
  double phMax           = 7.8;
  double chlorineMin     = 1.0;
  double chlorineMax     = 3.0;
  double turbidityMax    = 4.0;
  double tempMin         = 18.0;
  double tempMax         = 32.0;

  // ── Sensor Calibration ────────────────────────────────────────────────────
  Map<String, DateTime?> lastCalibrated = {
    'pH':          null,
    'Turbidity':   null,
    'Temperature': null,
    'Chlorine':    null,
  };

  // ── UI Settings ───────────────────────────────────────────────────────────
  bool   darkMode       = false;
  String tempUnit       = '°C';   // '°C' | '°F'
  bool   dataLoggingEnabled = true;
  int    dataRefreshIntervalSeconds = 30;

  // ── Data Management ───────────────────────────────────────────────────────
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  SettingsProvider() {
    _loadFromPrefs();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Setters with auto-save
  // ─────────────────────────────────────────────────────────────────────────

  void updatePoolProfile({
    String? name,
    String? type,
    double? volume,
    String? location,
    String? usage,
  }) {
    if (name     != null) poolName          = name;
    if (type     != null) poolType          = type;
    if (volume   != null) poolVolumeLiters  = volume;
    if (location != null) poolLocation      = location;
    if (usage    != null) usageLevel        = usage;
    _saveToPrefs();
    notifyListeners();
  }

  /// Called from BOTH Settings and Dispensing pages.
  void setAutoDispensing(bool value) {
    autoDispensingEnabled = value;
    _saveToPrefs();
    notifyListeners();
  }

  void setManualDispensingAllowed(bool value) {
    manualDispensingAllowed = value;
    _saveToPrefs();
    notifyListeners();
  }

  void updateDispensingSettings({
    double? maxPerCycle,
    int? delaySeconds,
    double? safeHCL,
    double? safeSoda,
    double? safeCL,
    double? safeAlum,
  }) {
    if (maxPerCycle   != null) maxChemicalPerCycle       = maxPerCycle;
    if (delaySeconds  != null) autoCheckDelaySeconds     = delaySeconds;
    if (safeHCL       != null) safetyLimitHCL            = safeHCL;
    if (safeSoda      != null) safetyLimitSoda           = safeSoda;
    if (safeCL        != null) safetyLimitCL             = safeCL;
    if (safeAlum      != null) safetyLimitAlum           = safeAlum;
    _saveToPrefs();
    notifyListeners();
  }

  void updateAlertThresholds({
    double? phLow, double? phHigh,
    double? clLow, double? clHigh,
    double? turbHigh,
    double? tLow, double? tHigh,
  }) {
    if (phLow    != null) phMin          = phLow;
    if (phHigh   != null) phMax          = phHigh;
    if (clLow    != null) chlorineMin    = clLow;
    if (clHigh   != null) chlorineMax    = clHigh;
    if (turbHigh != null) turbidityMax   = turbHigh;
    if (tLow     != null) tempMin        = tLow;
    if (tHigh    != null) tempMax        = tHigh;
    _saveToPrefs();
    notifyListeners();
  }

  void markCalibrated(String sensor) {
    lastCalibrated[sensor] = DateTime.now();
    _saveToPrefs();
    notifyListeners();
  }

  void setDarkMode(bool value) {
    darkMode = value;
    _saveToPrefs();
    notifyListeners();
  }

  void setTempUnit(String unit) {
    tempUnit = unit;
    _saveToPrefs();
    notifyListeners();
  }

  void setDataLogging(bool value) {
    dataLoggingEnabled = value;
    _saveToPrefs();
    notifyListeners();
  }

  void setDataRefreshInterval(int seconds) {
    dataRefreshIntervalSeconds = seconds;
    _saveToPrefs();
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Persistence helpers
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _loadFromPrefs() async {
    _isLoading = true;
    notifyListeners();
    try {
      final p = await SharedPreferences.getInstance();
      poolName            = p.getString('poolName')       ?? poolName;
      poolType            = p.getString('poolType')       ?? poolType;
      poolVolumeLiters    = p.getDouble('poolVolume')     ?? poolVolumeLiters;
      poolLocation        = p.getString('poolLocation')   ?? poolLocation;
      usageLevel          = p.getString('usageLevel')     ?? usageLevel;
      autoDispensingEnabled    = p.getBool('autoDispense')    ?? autoDispensingEnabled;
      manualDispensingAllowed  = p.getBool('manualAllowed')   ?? manualDispensingAllowed;
      maxChemicalPerCycle      = p.getDouble('maxPerCycle')   ?? maxChemicalPerCycle;
      autoCheckDelaySeconds    = p.getInt('delaySeconds')     ?? autoCheckDelaySeconds;
      safetyLimitHCL  = p.getDouble('safeHCL')   ?? safetyLimitHCL;
      safetyLimitSoda = p.getDouble('safeSoda')  ?? safetyLimitSoda;
      safetyLimitCL   = p.getDouble('safeCL')    ?? safetyLimitCL;
      safetyLimitAlum = p.getDouble('safeAlum')  ?? safetyLimitAlum;
      phMin        = p.getDouble('phMin')        ?? phMin;
      phMax        = p.getDouble('phMax')        ?? phMax;
      chlorineMin  = p.getDouble('clMin')        ?? chlorineMin;
      chlorineMax  = p.getDouble('clMax')        ?? chlorineMax;
      turbidityMax = p.getDouble('turbMax')      ?? turbidityMax;
      tempMin      = p.getDouble('tempMin')      ?? tempMin;
      tempMax      = p.getDouble('tempMax')      ?? tempMax;
      darkMode     = p.getBool('darkMode')       ?? darkMode;
      tempUnit     = p.getString('tempUnit')     ?? tempUnit;
      dataLoggingEnabled          = p.getBool('dataLogging')      ?? dataLoggingEnabled;
      dataRefreshIntervalSeconds  = p.getInt('refreshInterval')   ?? dataRefreshIntervalSeconds;

      // Calibration timestamps
      for (final sensor in lastCalibrated.keys.toList()) {
        final ts = p.getString('calib_$sensor');
        if (ts != null) lastCalibrated[sensor] = DateTime.tryParse(ts);
      }
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString('poolName',       poolName);
      await p.setString('poolType',       poolType);
      await p.setDouble('poolVolume',     poolVolumeLiters);
      await p.setString('poolLocation',   poolLocation);
      await p.setString('usageLevel',     usageLevel);
      await p.setBool('autoDispense',     autoDispensingEnabled);
      await p.setBool('manualAllowed',    manualDispensingAllowed);
      await p.setDouble('maxPerCycle',    maxChemicalPerCycle);
      await p.setInt('delaySeconds',      autoCheckDelaySeconds);
      await p.setDouble('safeHCL',   safetyLimitHCL);
      await p.setDouble('safeSoda',  safetyLimitSoda);
      await p.setDouble('safeCL',    safetyLimitCL);
      await p.setDouble('safeAlum',  safetyLimitAlum);
      await p.setDouble('phMin',     phMin);
      await p.setDouble('phMax',     phMax);
      await p.setDouble('clMin',     chlorineMin);
      await p.setDouble('clMax',     chlorineMax);
      await p.setDouble('turbMax',   turbidityMax);
      await p.setDouble('tempMin',   tempMin);
      await p.setDouble('tempMax',   tempMax);
      await p.setBool('darkMode',    darkMode);
      await p.setString('tempUnit',  tempUnit);
      await p.setBool('dataLogging', dataLoggingEnabled);
      await p.setInt('refreshInterval', dataRefreshIntervalSeconds);

      for (final entry in lastCalibrated.entries) {
        if (entry.value != null) {
          await p.setString('calib_${entry.key}', entry.value!.toIso8601String());
        }
      }
    } catch (_) {}
  }

  Future<void> clearAllData() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.clear();
    } catch (_) {}
    notifyListeners();
  }
}
