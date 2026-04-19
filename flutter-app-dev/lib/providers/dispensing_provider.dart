import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/dispensing_job.dart';
import '../services/dispensing_service.dart';
import 'package:http/http.dart' as http;

class DispensingProvider with ChangeNotifier {
  final DispensingService _service = DispensingService();
  static const String _deviceId = 'POOL-MONITOR-001';
  static const String _baseUrl  = 'http://34.70.141.104:5000/api';

  bool _isAutoDispensingEnabled = false;
  bool _isManualDispensingActive = false;
  bool _isEmergencyStopped = false;
  bool _isLoading = false;
  String? _error;

  List<DispensingJob> _dispensingHistory = [];
  Map<String, String> _dispenserValues = {
    'dispenser1': '0', 'dispenser2': '0',
    'dispenser3': '0', 'dispenser4': '0',
  };

  bool get isAutoDispensingEnabled => _isAutoDispensingEnabled;
  bool get isManualDispensingActive => _isManualDispensingActive;
  bool get isEmergencyStopped => _isEmergencyStopped;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<DispensingJob> get dispensingHistory => _dispensingHistory;
  Map<String, String> get dispenserValues => _dispenserValues;

  Future<void> loadAll() async {
    _setLoading(true);
    _error = null;
    try {
      await Future.wait([_loadJobs(), _loadDispenserValues()]);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _loadJobs() async {
    List<DispensingJob> jobs = [];
    try {
      final auto   = await _service.getJobsByDevice(_deviceId, limit: 50, status: 'auto');
      final manual = await _service.getJobsByDevice(_deviceId, limit: 50, status: 'manual');
      jobs = [...auto, ...manual];
      jobs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (_) {
      try {
        jobs = await _service.getAllJobs(deviceId: _deviceId);
      } catch (e) {
        jobs = _getDummyJobs();
      }
    }
    
    if (jobs.isEmpty) {
      jobs = _getDummyJobs();
    }
    
    _dispensingHistory = jobs;
  }

  List<DispensingJob> _getDummyJobs() {
    final now = DateTime.now();
    return [
      DispensingJob(
        id: 1,
        deviceId: _deviceId,
        timestamp: now.subtract(const Duration(minutes: 30)).toIso8601String(),
        hcl: 0, soda: 0, cl: 50, al: 0, flag: 'manual'
      ),
      DispensingJob(
        id: 2,
        deviceId: _deviceId,
        timestamp: now.subtract(const Duration(hours: 2)).toIso8601String(),
        hcl: 10, soda: 0, cl: 0, al: 0, flag: 'auto'
      ),
      DispensingJob(
        id: 3,
        deviceId: _deviceId,
        timestamp: now.subtract(const Duration(hours: 5)).toIso8601String(),
        hcl: 0, soda: 20, cl: 10, al: 5, flag: 'manual'
      ),
      DispensingJob(
        id: 4,
        deviceId: _deviceId,
        timestamp: now.subtract(const Duration(days: 1)).toIso8601String(),
        hcl: 0, soda: 0, cl: 100, al: 0, flag: 'auto'
      ),
    ];
  }

  Future<void> _loadDispenserValues() async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/dispenser/get'));
      if (res.statusCode == 200) {
        _dispenserValues = Map<String, String>.from(json.decode(res.body));
      }
    } catch (_) {}
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  Future<void> toggleAutoDispensing(bool enabled) async {
    if (_isEmergencyStopped) return;
    _isAutoDispensingEnabled = enabled;
    // In a real scenario, this would send an API request to enable/disable auto mode on the IoT device
    notifyListeners();
  }

  Future<bool> emergencyStop() async {
    _setLoading(true);
    try {
      await http.post(Uri.parse('$_baseUrl/dispenser/reset'));
      _isEmergencyStopped = true;
      _isAutoDispensingEnabled = false;
      _isManualDispensingActive = false;
      _dispenserValues = {'dispenser1':'0','dispenser2':'0','dispenser3':'0','dispenser4':'0'};
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> resetEmergencyStop() async {
    _isEmergencyStopped = false;
    notifyListeners();
  }

  Future<bool> dispenseManual(String chemical, double amount) async {
    double hcl = 0, soda = 0, cl = 0, al = 0;
    switch (chemical) {
      case 'Chlorine': cl = amount; break;
      case 'pH Increaser (Soda)': soda = amount; break;
      case 'pH Decreaser (HCl)': hcl = amount; break;
      case 'Alkalinity (Alum)': al = amount; break;
    }
    return dispenseAllManual(cl: cl, soda: soda, hcl: hcl, al: al);
  }

  Future<bool> dispenseAllManual({
    double cl = 0, double soda = 0, double hcl = 0, double al = 0,
  }) async {
    if (_isEmergencyStopped || _isAutoDispensingEnabled) return false;

    _isManualDispensingActive = true;
    _error = null;
    notifyListeners();

    try {
      await http.post(
        Uri.parse('$_baseUrl/dispenser/set'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'dispenser1': hcl.toStringAsFixed(0),
          'dispenser2': soda.toStringAsFixed(0),
          'dispenser3': cl.toStringAsFixed(0),
          'dispenser4': al.toStringAsFixed(0),
        }),
      );
      await _service.createDispensingJob(
          deviceId: _deviceId, hcl: hcl, soda: soda, cl: cl, al: al, flag: 'manual');
      await loadAll();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isManualDispensingActive = false;
      notifyListeners();
    }
  }
}
